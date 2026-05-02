import '../../imports/imports.dart';

/// A premium, highly customizable wrapper around [CachedNetworkImage].
///
/// This widget provides smooth transitions, specialized error handling,
/// and integrates with the project's design system.
class AppCachedImage extends StatelessWidget {
  /// The URL of the image to display.
  final String imageUrl;

  /// Optional width for the image.
  final double? width;

  /// Optional height for the image.
  final double? height;

  /// How the image should be inscribed into the box.
  final BoxFit fit;

  /// Optional placeholder displayed while the image is loading.
  /// If null, a shimmer or loading indicator is shown.
  final Widget? placeholder;

  /// Optional widget displayed if the image fails to load.
  final Widget? errorWidget;

  /// [Optional] color to be combined with the image.
  final Color? color;

  /// [Optional] blend mode for the [color].
  final BlendMode? colorBlendMode;

  /// The borderRadius of the image.
  final BorderRadius? borderRadius;

  /// The duration of the fade-in animation.
  final Duration? fadeInDuration;

  /// How to align the image within its bounds.
  final Alignment alignment;

  /// If true, the image will be wrapped in a [Skeletonizer] during loading.
  final bool useSkeleton;

  /// Optional key to use for caching.
  final String? cacheKey;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.color,
    this.colorBlendMode,
    this.borderRadius,
    this.fadeInDuration,
    this.alignment = Alignment.center,
    this.useSkeleton = true,
    this.cacheKey,
  });

  @override
  Widget build(BuildContext context) {
    // Standardize scaling to preserve aspect ratio (using width-based factor)
    final double? adjustedWidth = width?.w;
    final double? adjustedHeight = height?.w;

    Widget imageContent = CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: cacheKey,
      width: adjustedWidth,
      height: adjustedHeight,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      alignment: alignment,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 500),
      placeholder: (context, url) =>
          placeholder ?? _buildDefaultPlaceholder(context),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildDefaultErrorWidget(context),
    );

    if (borderRadius != null) {
      imageContent = ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    if (useSkeleton) {
      return Skeletonizer(
        enabled: true,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: context.contextTheme.colorScheme.surfaceContainerHighest,
            borderRadius: borderRadius,
          ),
        ),
      );
    }
    return _buildLoadingIndicator(context);
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.contextTheme.colorScheme.primary.withValues(alpha: 0.4),
            context.contextTheme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.school_rounded,
          color: Colors.white.withValues(alpha: 0.3),
          size: 48,
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.contextTheme.colorScheme.primary.withValues(alpha: 0.6),
            context.contextTheme.colorScheme.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.school_rounded,
          color: Colors.white.withValues(alpha: 0.4),
          size: 56,
        ),
      ),
    );
  }
}
