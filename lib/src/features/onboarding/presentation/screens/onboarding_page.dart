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



    void onGetStarted() async {
      await SecureStorageService.instance.write('has_seen_onboarding', 'true');
      Get.offAllNamed<void>(AppRoutes.login);
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Obx(() {
          final logoUrl = configCtrl.logoUrl;
          final orgName = configCtrl.orgName;
          final List<OnboardingSlide> onboardingData = configCtrl.onboarding.isNotEmpty 
            ? configCtrl.onboarding 
            : [
                OnboardingSlide(title: 'Welcome to $orgName', subtitle: 'The complete platform for organization management and community engagement.'),
                OnboardingSlide(title: 'Stay Connected', subtitle: 'Receive real-time updates and participate in events.'),
                OnboardingSlide(title: 'All in One Place', subtitle: 'Manage your documents and resources seamlessly.'),
              ];

          if (onboardingData.isEmpty && configCtrl.status.value == ConfigStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // --- Top branding (config-driven) ---
              Padding(
                padding: EdgeInsets.only(
                  top: AppSpacing.lg.h,
                  bottom: AppSpacing.sm.h,
                ),
                child: Column(
                  children: [
                    if (logoUrl != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.onSurface.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: AppCachedImage(
                            imageUrl: logoUrl,
                            width: 64,
                            height: 64,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.circle_rounded,
                        size: 64.sp,
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
                ),
              ),

              // --- Page slides ---
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: onboardingData.length,
                  onPageChanged: (i) => currentIndex.value = i,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
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
                            onboardingData[index].title,
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
                            onboardingData[index].subtitle,
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
          );
        }),
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
