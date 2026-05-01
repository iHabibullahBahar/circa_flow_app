import '../../imports/imports.dart';

/// A robust, themed text field component designed for general use throughout the app.
/// It supports an optional top label, prefix/suffix icons, and consistent styling
/// that adheres to the application's theme and color scheme.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.initialValue,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.height = 50.0,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? initialValue;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final cs = context.contextTheme.colorScheme;
    final tt = context.contextTheme.textTheme;

    // Calculate vertical padding to achieve the target height
    // Using .h to match the responsive scaling used in AppButton
    final double targetHeight = height ?? 50.0;
    final double verticalPadding = (targetHeight.h - 22.0) / 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          autofocus: autofocus,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          enableInteractiveSelection: true,
          onTapOutside: (event) => FocusScope.of(context).unfocus(),
          contextMenuBuilder: (context, editableTextState) {
            return AdaptiveTextSelectionToolbar.buttonItems(
              anchors: editableTextState.contextMenuAnchors,
              buttonItems: editableTextState.contextMenuButtonItems,
            );
          },
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: cs.primary,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            prefixIcon: prefixIcon,
            prefixIconConstraints: BoxConstraints(
              maxHeight: targetHeight.h,
              minWidth: 44,
            ),
            suffixIcon: suffixIcon,
            suffixIconConstraints: BoxConstraints(
              maxHeight: targetHeight.h,
              minWidth: 44,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: verticalPadding > 0 ? verticalPadding : 0,
            ),
          ),
        ),
      ],
    );
  }
}
