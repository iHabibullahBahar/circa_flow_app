import 'dart:async';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import 'package:circa_flow_main/src/features/auth/domain/entities/user.dart';
import 'package:circa_flow_main/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:circa_flow_main/src/features/messaging/presentation/providers/socket_manager.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionController extends GetxController {
  final AuthRepository _repository;
  StreamSubscription<AppUser?>? _authSub;

  final Rx<SessionStatus> status = SessionStatus.unknown.obs;
  final Rx<AppUser?> user = Rx<AppUser?>(null);

  bool get isAuthenticated => status.value == SessionStatus.authenticated;

  SessionController({required AuthRepository repository}) : _repository = repository;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    final result = await _repository.checkAuthState();
    result.fold(
      (_) => status.value = SessionStatus.unauthenticated,
      (u) {
        if (u != null) {
          user.value = u;
          _updateOneSignalTag(u);
          status.value = SessionStatus.authenticated;
          _connectSocket();
        } else {
          status.value = SessionStatus.unauthenticated;
        }
      },
    );

    _authSub = _repository.onAuthStateChanged.listen((u) {
      if (u != null) {
        user.value = u;
        _updateOneSignalTag(u);
        status.value = SessionStatus.authenticated;
        _connectSocket();
      } else {
        user.value = null;
        OneSignal.User.removeTag("org_id");
        OneSignal.logout();
        status.value = SessionStatus.unauthenticated;
        _disconnectSocket();
      }
    });
  }

  void _updateOneSignalTag(AppUser u) {
    if (u.id.isNotEmpty) {
      OneSignal.login(u.id);
    }
    if (u.organizationId != null) {
      OneSignal.User.addTagWithKey("org_id", u.organizationId.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    user.value = null;
    OneSignal.User.removeTag("org_id");
    OneSignal.logout();
    status.value = SessionStatus.unauthenticated;
    _disconnectSocket();
  }

  void _connectSocket() {
    try {
      Get.find<SocketManager>().connect();
    } catch (_) {}
  }

  void _disconnectSocket() {
    try {
      Get.find<SocketManager>().disconnect();
    } catch (_) {}
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }
}

