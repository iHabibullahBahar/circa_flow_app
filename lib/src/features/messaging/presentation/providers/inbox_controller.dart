import 'dart:async';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/session_controller.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/inbox_repository.dart';

/// GetxController for the inbox screen.
/// Manages the sorted list of conversations, delta sync, and WS-triggered refreshes.
class InboxController extends GetxController {
  final InboxRepository _repository;

  InboxController({InboxRepository? repository})
      : _repository = repository ?? InboxRepository();

  final conversations = <int, ConversationModel>{}.obs; // keyed by id
  final sortedInbox = <ConversationModel>[].obs;
  final isLoading = true.obs;
  final isRefreshing = false.obs;

  /// Total unread count across all conversations — drives the nav badge.
  int get totalUnread =>
      sortedInbox.fold(0, (sum, c) => sum + c.unreadCount);

  String? _lastSyncTime;
  Timer? _debounceTimer;

  static const _syncKey = 'messaging_last_sync';

  @override
  void onInit() {
    super.onInit();
    _loadLastSyncTime().then((_) => loadInbox());
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Full inbox load (on init and pull-to-refresh).
  Future<void> loadInbox() async {
    isLoading.value = true;
    final result = await _repository.getInbox();
    result.fold(
      (failure) => isLoading.value = false,
      (list) {
        conversations.clear();
        for (final c in list) {
          conversations[c.id] = c;
        }
        _sortInbox();
        isLoading.value = false;
        _saveSyncTime();
      },
    );
  }

  /// Pull-to-refresh — full reload.
  Future<void> refresh() async {
    isRefreshing.value = true;
    await loadInbox();
    isRefreshing.value = false;
  }

  /// Delta sync — only fetch conversations updated since last sync.
  Future<void> deltaSync() async {
    final result = await _repository.getInbox(updatedAfter: _lastSyncTime);
    result.fold(
      (failure) => null,
      (list) {
        for (final c in list) {
          _merge(c);
        }
        _saveSyncTime();
      },
    );
  }

  /// Called by SocketManager when an InboxUpdated WS event arrives.
  /// Debounced 500ms to avoid hammering API on burst messages.
  void onSocketInboxUpdated(Map<String, dynamic> payload) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), deltaSync);
  }

  /// Optimistically update a conversation in the inbox (e.g., after sending).
  void updateConversation(ConversationModel updated) {
    _merge(updated);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  void _merge(ConversationModel c) {
    conversations[c.id] = c;
    _sortInbox();
  }

  void _sortInbox() {
    final sorted = conversations.values.toList()
      ..sort((a, b) {
        final at = a.lastMessageAt ?? a.updatedAt;
        final bt = b.lastMessageAt ?? b.updatedAt;
        return bt.compareTo(at);
      });
    sortedInbox.value = sorted;
  }

  Future<void> _loadLastSyncTime() async {
    final session = Get.find<SessionController>();
    final orgKey = session.user.value?.organizationId?.toString() ?? 'default';
    final prefs = await SharedPreferences.getInstance();
    _lastSyncTime = prefs.getString('${_syncKey}_$orgKey');
  }

  Future<void> _saveSyncTime() async {
    final session = Get.find<SessionController>();
    final orgKey = session.user.value?.organizationId?.toString() ?? 'default';
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc().toIso8601String();
    await prefs.setString('${_syncKey}_$orgKey', now);
    _lastSyncTime = now;
  }
}
