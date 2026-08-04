import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import 'role_selection_dialog.dart';

/// Modal dialog or full screen view collecting Full Name and Role during onboarding.
class ProfileNameDialog extends ConsumerStatefulWidget {
  final String userId;
  final String? defaultRole;
  final String? initialName;

  const ProfileNameDialog({
    super.key,
    required this.userId,
    this.defaultRole,
    this.initialName,
  });

  @override
  ConsumerState<ProfileNameDialog> createState() => _ProfileNameDialogState();
}

class _ProfileNameDialogState extends ConsumerState<ProfileNameDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late String _selectedRole;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _selectedRole = widget.defaultRole?.toLowerCase() ?? 'customer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      await ref.read(profileProvider.notifier).saveOnboarding(
            userId: widget.userId,
            fullName: _nameController.text.trim(),
            role: _selectedRole,
            phone: currentUser?.phone,
            email: currentUser?.email,
          );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Assam Hub',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          'Complete your profile setup to get started',
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Full Name Field
              Text(
                'Full Name *',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Anay Sharma',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Select Role
              Text(
                'Select Your Role *',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              RoleSelectionWidget(
                initialRole: _selectedRole,
                onRoleSelected: (role) => setState(() => _selectedRole = role),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Complete Onboarding & Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
