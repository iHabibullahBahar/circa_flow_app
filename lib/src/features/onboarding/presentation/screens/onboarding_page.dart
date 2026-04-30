import 'package:circa_flow_main/src/imports/imports.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';

class OnboardingPage extends HookWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.contextTheme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final configCtrl = Get.find<ConfigController>();

    final pageController = usePageController();
    final currentIndex = useState(0);

    final List<Map<String, dynamic>> onboardingData =
        useMemoized(() => [
              {
                'title': 'onboarding.onboarding_title_1'.t(),
                'subtitle': 'onboarding.onboarding_subtitle_1'.t(),
              },
              {
                'title': 'onboarding.onboarding_title_2'.t(),
                'subtitle': 'onboarding.onboarding_subtitle_2'.t(),
              },
              {
                'title': 'onboarding.onboarding_title_3'.t(),
                'subtitle': 'onboarding.onboarding_subtitle_3'.t(),
              },
            ]);

    void onGetStarted() {
      Get.offAllNamed<void>(AppRoutes.login);
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // --- Top branding (config-driven) ---
            Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.lg.h,
                bottom: AppSpacing.sm.h,
              ),
              child: Obx(() {
                final logoUrl = configCtrl.logoUrl;
                final orgName = configCtrl.orgName;
                return Column(
                  children: [
                    if (logoUrl != null)
                      AppCachedImage(
                        imageUrl: logoUrl,
                        width: 56.w,
                        height: 56.w,
                      )
                    else
                      Icon(
                        Icons.circle_rounded,
                        size: 48.sp,
                        color: colorScheme.primary,
                      ),
                    SizedBox(height: AppSpacing.sm.h),
                    Text(
                      orgName,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                        fontSize: 22.sp,
                      ),
                    ),
                  ],
                );
              }),
            ),

            // --- Page slides ---
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: onboardingData.length,
                onPageChanged: (i) => currentIndex.value = i,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconForPage(index),
                          size: 100.sp,
                          color: colorScheme.primary.withValues(alpha: 0.8),
                        ),
                        SizedBox(height: AppSpacing.xl.h),
                        Text(
                          onboardingData[index]['title'] as String,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            height: 1.2,
                            fontSize: 24.sp,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md.h),
                        Text(
                          onboardingData[index]['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // --- Page indicator + button ---
            Padding(
              padding: EdgeInsets.all(AppSpacing.xl.w),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: pageController,
                    count: onboardingData.length,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: colorScheme.primary,
                      dotColor: colorScheme.outlineVariant,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  AppButton(
                    label: 'shared.get_started'.t(),
                    onPressed: onGetStarted,
                    isFullWidth: true,
                  ),
                  SizedBox(height: AppSpacing.md.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForPage(int index) {
    return switch (index) {
      0 => Icons.groups_2_rounded,
      1 => Icons.event_note_rounded,
      _ => Icons.check_circle_outline_rounded,
    };
  }
}
