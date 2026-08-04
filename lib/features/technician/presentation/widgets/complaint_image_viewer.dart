import 'package:flutter/material.dart';

class ComplaintImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ComplaintImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  static void show(BuildContext context, List<String> imageUrls, {int initialIndex = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComplaintImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  State<ComplaintImageViewer> createState() => _ComplaintImageViewerState();
}

class _ComplaintImageViewerState extends State<ComplaintImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        foregroundColor: Colors.white,
        title: Text(
          'Complaint Photo (${_currentIndex + 1} of ${widget.imageUrls.length})',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        itemBuilder: (context, index) {
          final url = widget.imageUrls[index];
          return Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (ctx, err, stack) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 64),
                    SizedBox(height: 8),
                    Text('Could not load image', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
