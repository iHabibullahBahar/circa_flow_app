import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:circa_flow_main/src/config/app_config_model.dart';
import 'package:circa_flow_main/src/config/config_controller.dart';
import 'package:circa_flow_main/src/features/auth/presentation/providers/session_controller.dart';
import 'package:circa_flow_main/src/features/messaging/presentation/providers/inbox_controller.dart';
import 'package:circa_flow_main/src/features/messaging/presentation/providers/chat_controller.dart';
import 'package:circa_flow_main/src/services/api_service.dart';
import 'package:logger/logger.dart';

/// Permanent GetxService singleton that manages the Reverb WebSocket connection.
///
/// Lifecycle:
///   - connect() → called by SessionController when authenticated
///   - disconnect() → called by SessionController on logout
///   - subscribe(channel) → called lazily when opening a chat screen
///   - unsubscribe(channel) → called when leaving a chat screen
///
/// Uses Pusher wire protocol (JSON frames) — Reverb is fully compatible.
class SocketManager extends GetxService {
  static SocketManager get instance => Get.find<SocketManager>();

  final _log = Logger();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _subscribed = <String>{};
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _intentionalClose = false;
  String? _socketId;

  final isConnected = false.obs;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void onReady() {
    super.onReady();
    // Watch for the config to finish loading from the network.
    // At app startup, _connectSocket() fires while config.value still has the
    // cached config (which may have an empty WS key). Once the fresh config
    // arrives (status → ready), retry the connection if:
    //   • we have a real WS key now
    //   • the user is authenticated
    //   • we are not already connected
    final configCtrl = Get.find<ConfigController>();
    ever(configCtrl.status, (ConfigStatus status) {
      if (status != ConfigStatus.ready) return;
      final wsKey = configCtrl.config.value.websocket.key;
      if (wsKey.isEmpty) return;
      final session = Get.find<SessionController>();
      if (!session.isAuthenticated) return;
      if (isConnected.value) return;  // already up — nothing to do
      _log.i('[WS] Config ready with key — retrying connect');
      connect();
    });
  }

  // ── Connection ─────────────────────────────────────────────────────────────

  void connect() {
    final config = Get.find<ConfigController>().config.value;
    final session = Get.find<SessionController>();

    if (!session.isAuthenticated) {
      _log.w('[WS] Not authenticated — skipping WebSocket connect');
      return;
    }

    final wsConfig = config.websocket;
    if (wsConfig.key.isEmpty) {
      _log.w('[WS] No WebSocket key in config — skipping connect');
      return;
    }

    _intentionalClose = false;
    _reconnectAttempt = 0;
    _openChannel(wsConfig);
  }

  void disconnect() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscribed.clear();
    _socketId = null;
    isConnected.value = false;
    _log.i('[WS] Disconnected');
  }

  // ── Channel subscription ───────────────────────────────────────────────────

  /// Subscribe to a private channel lazily (e.g., when opening a chat screen).
  /// Safe to call multiple times — duplicate subscriptions are skipped.
  void subscribe(String channel) {
    if (_subscribed.contains(channel)) return;
    _subscribed.add(channel);
    if (_channel == null) return;
    _sendSubscribe(channel);
  }

  /// Unsubscribe from a channel (e.g., when leaving chat screen).
  void unsubscribe(String channel) {
    _subscribed.remove(channel);
    _channel?.sink.add(jsonEncode({
      'event': 'pusher:unsubscribe',
      'data': {'channel': channel},
    }));
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _openChannel(WebSocketConfig wsConfig) {
    try {
      final uri = Uri.parse(wsConfig.wsUrl);
      _channel = WebSocketChannel.connect(uri);
      _log.i('[WS] Connecting to ${wsConfig.wsUrl}');

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _startHeartbeat();
    } catch (e) {
      _log.e('[WS] Failed to connect: $e');
      _scheduleReconnect(wsConfig);
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final Map<String, dynamic> frame = jsonDecode(raw as String);
      final event = frame['event'] as String?;
      final data = frame['data'];

      switch (event) {
        case 'pusher:connection_established':
          final parsed = data is String ? jsonDecode(data) : data;
          _socketId = parsed['socket_id'] as String?;
          isConnected.value = true;
          _reconnectAttempt = 0;
          _log.i('[WS] Connected. socket_id=$_socketId');
          // Subscribe to personal user channel + any pending channels
          _resubscribeAll();

        case 'pusher:error':
          _log.e('[WS] Server error: $data');

        case 'pusher_internal:subscription_succeeded':
          _log.d('[WS] Subscribed: ${frame['channel']}');

        default:
          // Route app events to controllers
          _dispatchEvent(event, frame['channel'] as String?, data);
      }
    } catch (e) {
      _log.e('[WS] Parse error: $e');
    }
  }

  void _onError(Object error) {
    _log.e('[WS] Error: $error');
    isConnected.value = false;
  }

  void _onDone() {
    isConnected.value = false;
    _subscription?.cancel();
    _channel = null;

    if (!_intentionalClose) {
      _log.w('[WS] Connection closed unexpectedly — scheduling reconnect');
      _scheduleReconnectFromConfig();
    }
  }

  void _scheduleReconnectFromConfig() {
    final config = Get.find<ConfigController>().config.value;
    final session = Get.find<SessionController>();
    if (!session.isAuthenticated) return;
    _scheduleReconnect(config.websocket);
  }

  void _scheduleReconnect(WebSocketConfig wsConfig) {
    _reconnectTimer?.cancel();
    // Exponential backoff: 1s, 2s, 4s … max 30s
    final delay = Duration(seconds: min(pow(2, _reconnectAttempt).toInt(), 30));
    _reconnectAttempt++;
    _log.i('[WS] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempt)');
    _reconnectTimer = Timer(delay, () => _openChannel(wsConfig));
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _channel?.sink.add(jsonEncode(<String, dynamic>{'event': 'pusher:ping', 'data': <String, dynamic>{}}));
    });
  }

  void _resubscribeAll() {
    // Always subscribe personal user channel first
    final session = Get.find<SessionController>();
    final memberId = session.user.value?.id;
    if (memberId != null && memberId.isNotEmpty) {
      final userChannel = 'private-user.$memberId';
      _subscribed.add(userChannel);
    }

    // Subscribe all pending channels
    for (final channel in List<String>.from(_subscribed)) {
      _sendSubscribe(channel);
    }
  }

  void _sendSubscribe(String channel) {
    // For private channels, we need an auth token from the backend.
    // Reverb/Pusher protocol: send auth before subscription.
    _authenticateAndSubscribe(channel);
  }

  Future<void> _authenticateAndSubscribe(String channel) async {
    if (_socketId == null) return;

    try {
      // POST /api/v1/broadcasting/auth — explicit route with auth:member guard.
      // Dio's baseUrl is /api/v1/ so the relative path resolves correctly.
      final result = await ApiService.instance.post<Map<String, dynamic>>(
        'broadcasting/auth',
        data: {
          'socket_id': _socketId,
          'channel_name': channel,
        },
      );

      result.fold(
        (failure) => _log.w('[WS] Auth failed for $channel: ${failure.message}'),
        (response) {
          final auth = response['auth'] as String?;
          if (auth == null) return;

          _channel?.sink.add(jsonEncode({
            'event': 'pusher:subscribe',
            'data': {
              'channel': channel,
              'auth': auth,
            },
          }));
          _log.d('[WS] Subscribed to $channel');
        },
      );
    } catch (e) {
      _log.e('[WS] Auth error for $channel: $e');
    }
  }


  // ── Event dispatch ─────────────────────────────────────────────────────────

  void _dispatchEvent(String? event, String? channel, dynamic data) {
    if (event == null) return;
    final Map<String, dynamic> payload =
        data is String
            ? ((jsonDecode(data) as Map?)?.cast<String, dynamic>() ?? {})
            : ((data as Map?)?.cast<String, dynamic>() ?? {});

    switch (event) {
      case r'App\Events\InboxUpdated':
      case 'inbox.updated':
        _log.d('[WS] inbox.updated → conversationId=${payload['conversation_id']}');
        _findInboxController()?.onSocketInboxUpdated(payload);

      case r'App\Events\MessageSent':
      case 'message.new':
        _log.d('[WS] message.new → msgId=${payload['message_id']}');
        _findChatController(payload['conversation_id'])?.onSocketMessageNew(payload);

      case r'App\Events\MessageRead':
      case 'message.read':
        _log.d('[WS] message.read');
        _findChatController(payload['conversation_id'])?.onSocketMessageRead(payload);

      case r'App\Events\TypingEvent':
      case 'typing':
        _findChatController(payload['conversation_id'])?.onSocketTyping(payload);
    }
  }

  InboxController? _findInboxController() {
    try {
      return Get.find<InboxController>(tag: 'inbox_controller');
    } catch (_) {
      return null;
    }
  }

  // ignore: avoid_annotating_with_dynamic
  ConversationController? _findChatController(dynamic conversationId) {
    if (conversationId == null) return null;
    try {
      return Get.find<ConversationController>(tag: 'chat_$conversationId');
    } catch (_) {
      return null;
    }
  }
}
