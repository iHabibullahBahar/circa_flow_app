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
        _resolveNavigation(session.status.value, isInitial: true);
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
        _resolveNavigation(session.status.value, isInitial: true);
      }
    }
  }

  void _resolveNavigation(SessionStatus status, {bool isInitial = false}) {
    // Only set _navigated = true on the very first resolution (from Splash)
    if (isInitial) {
      if (_navigated) return;
      _navigated = true;
      FlutterNativeSplash.remove();
    }

    final configCtrl = Get.find<ConfigController>();
    
    if (status == SessionStatus.authenticated) {
      // If we just authenticated, and we weren't already on a home-path, go home
      // In many cases, we are already navigating manually from LoginController,
      // but this is a safety net.
      if (isInitial) Get.offAllNamed<void>(AppRoutes.home);
    } else if (status == SessionStatus.unauthenticated) {
      if (!configCtrl.allowGuestAccess) {
        // If guest access is NOT allowed, always kick to onboarding/login
        Get.offAllNamed<void>(AppRoutes.onboarding);
      } else {
        // Guest access is allowed. 
        // On initial load, we go home. On subsequent logouts, we stay where we are 
        // (as the UI will reactively show Guest view) or we can optionally go home.
        if (isInitial) Get.offAllNamed<void>(AppRoutes.home);
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
