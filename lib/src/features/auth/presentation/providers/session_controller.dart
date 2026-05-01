import 'dart:async';
import 'package:circa_flow_main/src/imports/packages_imports.dart';
import 'package:circa_flow_main/src/features/auth/domain/entities/user.dart';
import 'package:circa_flow_main/src/features/auth/domain/repositories/auth_repository.dart';

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
      } else {
        user.value = null;
        OneSignal.User.removeTag("org_id");
        status.value = SessionStatus.unauthenticated;
      }
    });
  }

  void _updateOneSignalTag(AppUser u) {
    if (u.organizationId != null) {
      OneSignal.User.addTagWithKey("org_id", u.organizationId.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    user.value = null;
    OneSignal.User.removeTag("org_id");
    status.value = SessionStatus.unauthenticated;
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }
}

