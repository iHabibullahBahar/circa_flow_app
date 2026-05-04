
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

/// A bottom sheet that displays the user's recent photos in a grid.
/// Allows multi-selection of up to [maxCount] images.
/// Returns a [List<String>] of local file paths when the user taps "Send".
class InlineGallerySheet extends StatefulWidget {
  final int maxCount;

  const InlineGallerySheet({super.key, this.maxCount = 10});

  static Future<List<String>?> show({int maxCount = 10}) {
    return Get.bottomSheet<List<String>>(
      InlineGallerySheet(maxCount: maxCount),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<InlineGallerySheet> createState() => _InlineGallerySheetState();
}

class _InlineGallerySheetState extends State<InlineGallerySheet> {
  List<AssetEntity> _assets = [];
  final List<AssetEntity> _selectedAssets = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      setState(() {
        _isLoading = false;
        _hasPermission = false;
      });
      return;
    }

    setState(() {
      _hasPermission = true;
    });

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    if (paths.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final AssetPathEntity recent = paths.first;
    final List<AssetEntity> recentAssets = await recent.getAssetListPaged(
      page: 0,
      size: 60, // Fetch top 60 recent images
    );

    setState(() {
      _assets = recentAssets;
      _isLoading = false;
    });
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        if (_selectedAssets.length < widget.maxCount) {
          _selectedAssets.add(asset);
        } else {
          Get.snackbar(
            'Limit Reached',
            'You can only select up to ${widget.maxCount} images.',
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    });
  }

  Future<void> _onSendTap() async {
    if (_selectedAssets.isEmpty) return;
    
    // Show a loading indicator if converting assets takes time
    Get.dialog<void>(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    final List<String> paths = [];
    for (final asset in _selectedAssets) {
      final file = await asset.file;
      if (file != null) {
        paths.add(file.path);
      }
    }

    Get.back<void>(); // close dialog
    Get.back<List<String>>(result: paths); // close sheet with result
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.7, // Take up 70% of screen height
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Photos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton(
                  onPressed: _selectedAssets.isEmpty ? null : _onSendTap,
                  child: Text('Send${_selectedAssets.isNotEmpty ? ' (${_selectedAssets.length})' : ''}'),
                ),
              ],
            ),
          ),
          
          // Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasPermission
                    ? const Center(child: Text('Permission denied'))
                    : _assets.isEmpty
                        ? const Center(child: Text('No photos found'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(2),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                            itemCount: _assets.length,
                            itemBuilder: (context, index) {
                              final asset = _assets[index];
                              final isSelected = _selectedAssets.contains(asset);
                              final selectionIndex = _selectedAssets.indexOf(asset);

                              return GestureDetector(
                                onTap: () => _toggleSelection(asset),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    AssetThumbnail(asset: asset),
                                    if (isSelected)
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black.withValues(alpha: 0.3),
                                        ),
                                      ),
                                    if (isSelected)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: cs.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${selectionIndex + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (!isSelected)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class AssetThumbnail extends StatelessWidget {
  final AssetEntity asset;

  const AssetThumbnail({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailData,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
        );
      },
    );
  }
}
