import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';

/// Reusable image picker widget with Supabase Storage upload.
/// Shows a thumbnail preview after selection with remove/replace options.
/// Falls back gracefully if Supabase Storage bucket doesn't exist.
class ImagePickerWidget extends StatefulWidget {
  /// Called when an image is successfully picked and uploaded (or picked on web).
  /// Returns the public URL of the uploaded image, or null if removed.
  final ValueChanged<String?> onImageSelected;

  /// Initial image URL to display (for edit mode).
  final String? initialImageUrl;

  /// Storage bucket name in Supabase.
  final String bucketName;

  /// Hint text shown before image is selected.
  final String hint;

  const ImagePickerWidget({
    super.key,
    required this.onImageSelected,
    this.initialImageUrl,
    this.bucketName = 'item-images',
    this.hint = 'Tap to add photo from gallery',
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedFile;
  String? _uploadedUrl;
  bool _isUploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _uploadedUrl = widget.initialImageUrl;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() {
        _pickedFile = file;
        _isUploading = true;
        _uploadError = null;
      });

      // Try uploading to Supabase Storage
      try {
        final supabase = Supabase.instance.client;
        final userId = supabase.auth.currentUser?.id ?? 'guest';
        final ext = file.path.split('.').last.toLowerCase();
        final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

        late final String publicUrl;

        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          await supabase.storage
              .from(widget.bucketName)
              .uploadBinary(fileName, bytes, fileOptions: FileOptions(contentType: 'image/$ext'));
        } else {
          await supabase.storage
              .from(widget.bucketName)
              .upload(fileName, File(file.path), fileOptions: FileOptions(contentType: 'image/$ext'));
        }

        publicUrl = supabase.storage.from(widget.bucketName).getPublicUrl(fileName);

        if (mounted) {
          setState(() {
            _uploadedUrl = publicUrl;
            _isUploading = false;
          });
          widget.onImageSelected(publicUrl);
        }
      } catch (_) {
        // Storage bucket may not exist — use local file preview only
        // Caller gets null URL and should use a default image fallback
        if (mounted) {
          setState(() {
            _isUploading = false;
            _uploadError = 'Upload skipped — using local preview';
          });
          // Return a data URI or local path indicator so the parent knows
          // an image was selected even without cloud upload
          widget.onImageSelected(null);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadError = 'Could not open gallery';
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _pickedFile = null;
      _uploadedUrl = null;
      _uploadError = null;
    });
    widget.onImageSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _pickedFile != null || _uploadedUrl != null;

    return GestureDetector(
      onTap: _isUploading ? null : _pickImage,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 90),
        decoration: BoxDecoration(
          color: hasImage ? Colors.transparent : AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? AppColors.primary.withValues(alpha: 0.3) : Colors.grey.shade300,
            width: hasImage ? 1.5 : 1,
            style: hasImage ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: hasImage ? _buildPreview() : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_photo_alternate_outlined,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.hint,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'JPG, PNG supported • Max 5MB',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: _buildThumbnail(),
            ),
          ),
          const SizedBox(width: 12),
          // Status & actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isUploading) ...[
                  const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      SizedBox(width: 8),
                      Text('Uploading...', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                    ],
                  ),
                ] else if (_uploadedUrl != null) ...[
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Image uploaded',
                          style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ] else if (_uploadError != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 15),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Saved locally',
                          style: const TextStyle(fontSize: 11, color: Colors.orange),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ActionChip(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Replace',
                      color: AppColors.primary,
                      onTap: _isUploading ? null : _pickImage,
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove',
                      color: AppColors.error,
                      onTap: _removeImage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (_pickedFile != null && !kIsWeb) {
      return Image.file(File(_pickedFile!.path), fit: BoxFit.cover);
    } else if (_uploadedUrl != null) {
      return Image.network(
        _uploadedUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
      );
    }
    return const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 32);
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
