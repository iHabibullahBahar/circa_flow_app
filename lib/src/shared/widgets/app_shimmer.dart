import 'package:skeletonizer/skeletonizer.dart';
import '../../imports/imports.dart';

/// A global shimmer/skeleton loader that uses the [skeletonizer] package.
/// It provides a modern, adaptive loading state that matches the actual UI structure.
class AppShimmer extends StatelessWidget {
  const AppShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    
    return Skeletonizer(
      enabled: enabled,
      effect: ShimmerEffect(
        baseColor: context.appColors.shimmerBase,
        highlightColor: cs.surface,
        duration: const Duration(milliseconds: 1500),
      ),
      child: child,
    );
  }

  /// A simple rectangular shimmer placeholder for custom shapes.
  static Widget box({
    double? width,
    double? height,
    double borderRadius = 8,
    EdgeInsetsGeometry? margin,
  }) {
    return Builder(
      builder: (context) {
        final cs = context.contextTheme.colorScheme;
        return Container(
          width: width,
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      },
    );
  }

  /// A circular shimmer placeholder.
  static Widget circle({
    required double size,
    EdgeInsetsGeometry? margin,
  }) {
    return Builder(
      builder: (context) {
        final cs = context.contextTheme.colorScheme;
        return Container(
          width: size,
          height: size,
          margin: margin,
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
