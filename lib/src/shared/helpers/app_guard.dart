import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/config_controller.dart';
import '../../features/auth/presentation/providers/session_controller.dart';
import 'app_dialogs.dart';

enum GuardType {
  guest,
  premium, // Added for future-proofing
}

class AppGuard {
  /// Acts as a centralized gatekeeper for protected actions.
  /// First checks if the backend provided `actionGuards` for the specific [action].
  /// If not, it uses [fallbackGuards].
  static void check(
    BuildContext context, {
    required String action,
    List<GuardType> fallbackGuards = const [],
    required VoidCallback onPass,
  }) {
    // 1. Resolve required guards (Backend config takes priority over local fallbacks)
    List<String> requiredGuardStrings = [];
    try {
      final configCtrl = Get.find<ConfigController>();
      final backendGuards = configCtrl.config.value.actionGuards[action];
      if (backendGuards != null) {
        requiredGuardStrings = backendGuards;
      } else {
        requiredGuardStrings = fallbackGuards.map((g) => g.name).toList();
      }
    } catch (_) {
      requiredGuardStrings = fallbackGuards.map((g) => g.name).toList();
    }

    // 2. Evaluate guards
    for (final guardStr in requiredGuardStrings) {
      if (guardStr == GuardType.guest.name) {
        final session = Get.find<SessionController>();
        if (!session.isAuthenticated) {
          AppDialogs.showLoginRequiredBottomSheet(context);
          return; // Abort action
        }
      } else if (guardStr == GuardType.premium.name) {
        // Future: Check premium status
        // final session = Get.find<SessionController>();
        // if (!session.isPremium) {
        //   AppDialogs.showPremiumRequiredBottomSheet(context);
        //   return;
        // }
      }
    }

    // 3. If all guards pass, execute the action
    onPass();
  }

  /// Returns true if the user passes the required guards for the given [action].
  static bool canProceed({
    required String action,
    List<GuardType> fallbackGuards = const [],
  }) {
    List<String> requiredGuardStrings = [];
    try {
      final configCtrl = Get.find<ConfigController>();
      final backendGuards = configCtrl.config.value.actionGuards[action];
      if (backendGuards != null) {
        requiredGuardStrings = backendGuards;
      } else {
        requiredGuardStrings = fallbackGuards.map((g) => g.name).toList();
      }
    } catch (_) {
      requiredGuardStrings = fallbackGuards.map((g) => g.name).toList();
    }

    for (final guardStr in requiredGuardStrings) {
      if (guardStr == GuardType.guest.name) {
        final session = Get.find<SessionController>();
        if (!session.isAuthenticated) {
          return false;
        }
      }
    }

    return true;
  }
}
