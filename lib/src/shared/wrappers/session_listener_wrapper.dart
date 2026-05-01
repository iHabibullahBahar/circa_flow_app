import 'package:circa_flow_main/src/imports/core_imports.dart';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/session_controller.dart';

/// Listens to both [ConfigController] and [SessionController] changes and
/// triggers navigation only after config is ready + session state is known.
///
/// Flow:
///   1. App starts on /splash
///   2. ConfigController fetches config (loading → ready/error)
///   3. Once config is ready, SessionController resolves auth state
///   4. This wrapper navigates to home or onboarding accordingly
class SessionListenerWrapper extends StatefulWidget {
  final Widget child;
  const SessionListenerWrapper({super.key, required this.child});

  @override
  State<SessionListenerWrapper> createState() => _SessionListenerWrapperState();
}

class _SessionListenerWrapperState extends State<SessionListenerWrapper> {
  Worker? _configWorker;
  Worker? _sessionWorker;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupListeners();
    });
  }

  void _setupListeners() {
    final configCtrl = Get.find<ConfigController>();
    final session = Get.find<SessionController>();

    // Step 1: Wait for config to finish loading
    _configWorker = ever(configCtrl.status, (status) {
      if (status == ConfigStatus.loading) return; // still loading

      // Config is ready (or failed with fallback) — now watch session
      _configWorker?.dispose();
      _configWorker = null;

      _sessionWorker = ever(session.status, (sessionStatus) {
        if (sessionStatus == SessionStatus.unknown) return;
        _resolveNavigation(sessionStatus);
      });

      // If session is already resolved (e.g. no token found immediately)
      if (session.status.value != SessionStatus.unknown) {
        _resolveNavigation(session.status.value);
      }
    });

    // If config is already done (fast cache hit) handle immediately
    if (configCtrl.status.value != ConfigStatus.loading) {
      _configWorker?.dispose();
      _configWorker = null;

      _sessionWorker = ever(session.status, (sessionStatus) {
        if (sessionStatus == SessionStatus.unknown) return;
        _resolveNavigation(sessionStatus);
      });

      if (session.status.value != SessionStatus.unknown) {
        _resolveNavigation(session.status.value);
      }
    }
  }

  void _resolveNavigation(SessionStatus status) {
    // Only set _navigated = true on the very first resolution (from Splash)
    if (!_navigated) {
      _navigated = true;
    } else {
      // If we already navigated once, we only care about re-navigating 
      // if we lose auth and need to be kicked out.
      if (status == SessionStatus.unauthenticated) {
        final configCtrl = Get.find<ConfigController>();
        if (!configCtrl.allowGuestAccess) {
          Get.offAllNamed<void>(AppRoutes.onboarding);
        }
      }
      return; 
    }

    final configCtrl = Get.find<ConfigController>();
    
    if (status == SessionStatus.authenticated) {
      Get.offAllNamed<void>(AppRoutes.home);
    } else if (status == SessionStatus.unauthenticated) {
      if (!configCtrl.allowGuestAccess) {
        Get.offAllNamed<void>(AppRoutes.onboarding);
      } else {
        Get.offAllNamed<void>(AppRoutes.home);
      }
    }
  }

  @override
  void dispose() {
    _configWorker?.dispose();
    _sessionWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
