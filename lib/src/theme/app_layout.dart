import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centralized layout tokens for consistent sizing across the app.
abstract final class AppLayout {
  AppLayout._();

  /// Default height for input fields (AppTextField) and medium buttons (AppButton).
  static double get controlHeight => 45.0;

  /// Large height for primary buttons or hero inputs.
  static double get controlHeightLarge => 50.0;

  /// Small height for secondary buttons or compact inputs.
  static double get controlHeightSmall => 40.0;

  // Scaled versions for usage in build methods
  static double get hControl => controlHeight.h;
  static double get hControlLarge => controlHeightLarge.h;
  static double get hControlSmall => controlHeightSmall.h;
}
