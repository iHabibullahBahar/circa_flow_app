import 'package:circa_flow_main/src/imports/imports.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.centerTitle = true,
    this.onPressed,
    this.isTransparent = false,
  });

  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final VoidCallback? onPressed;
  final bool? centerTitle;
  final bool isTransparent;

  @override
  Widget build(BuildContext context) {
    final theme = context.contextTheme;
    
    // Check if we can pop
    final bool canPop = Navigator.canPop(context);
    
    void handleBack() {
      if (onPressed != null) {
        onPressed!();
      } else if (canPop) {
        Navigator.maybePop(context);
              } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
              }
    }

    return AppBar(
      centerTitle: centerTitle,
      elevation: 0,
      backgroundColor: isTransparent ? Colors.transparent : null,
      shadowColor: Colors.transparent,
      title: titleWidget ??
          Text(
            title,
            style: theme.appBarTheme.titleTextStyle?.copyWith(
              fontWeight: FontWeight.w600,
            ) ?? theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
      leadingWidth: 40.w,
      leading: GestureDetector(
        onTap: handleBack,
        child: ColoredBox(
          color: Colors.transparent,
          child: 
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                size: 24,
              )
,
        ),
      ),
      iconTheme: theme.appBarTheme.iconTheme,
      actions: actions ?? [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
