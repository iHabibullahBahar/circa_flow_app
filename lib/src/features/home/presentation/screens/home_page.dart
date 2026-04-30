import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';

import 'package:circa_flow_main/src/features/auth/presentation/providers/session_controller.dart';


class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.contextTheme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final session = Get.find<SessionController>();
    final user = session.user.value;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppTopBar(
        title: 'home.home_title'.t(),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedHome01,
                size: 60.sp,
                color: colorScheme.primary,
              ),
              SizedBox(height: AppSpacing.lg.h),
              Obx(() => Text(
                user?.name ?? user?.email ?? ('home.welcome_home'.t()),
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              )),
              SizedBox(height: AppSpacing.xl.h),
              AppButton(
                label: 'auth.logout'.t(),
                onPressed: () => Get.offAllNamed<void>(AppRoutes.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
