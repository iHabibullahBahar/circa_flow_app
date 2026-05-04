import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Full-screen swipeable image gallery for chat messages.
///
/// Supports both local [File] paths and network URLs.
/// Open via [ChatImageGallery.open].
class ChatImageGallery extends StatefulWidget {
  const ChatImageGallery({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  final List<String> imageUrls;
  final int initialIndex;

  /// Convenience method to push the gallery as a full-screen route.
  static Future<void> open(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (_, __, ___) => ChatImageGallery(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  State<ChatImageGallery> createState() => _ChatImageGalleryState();
}

class _ChatImageGalleryState extends State<ChatImageGallery> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Immersive UI while gallery is open
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  bool _isLocalFile(String url) =>
      !url.startsWith('http://') && !url.startsWith('https://');

  ImageProvider _imageProvider(String url) {
    if (_isLocalFile(url)) return FileImage(File(url));
    return CachedNetworkImageProvider(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: widget.imageUrls.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              )
            : null,
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.imageUrls.length,
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        builder: (context, index) {
          final url = widget.imageUrls[index];
          return PhotoViewGalleryPageOptions(
            imageProvider: _imageProvider(url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            heroAttributes: PhotoViewHeroAttributes(tag: 'chat_image_$index'),
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_rounded,
                  color: Colors.white54, size: 60),
            ),
          );
        },
        loadingBuilder: (_, event) => Center(
          child: CircularProgressIndicator(
            value: event?.expectedTotalBytes != null
                ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
                : null,
            color: Colors.white54,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}
