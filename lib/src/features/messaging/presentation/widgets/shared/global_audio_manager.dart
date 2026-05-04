import 'package:just_audio/just_audio.dart';

/// Global manager to ensure only one audio plays at a time.
///
/// When a new audio starts playing, any other playing audio is paused.
/// This is a singleton shared across all [AudioMessageBubble] instances in the
/// chat list, so the user can only hear one message at a time.
class GlobalAudioManager {
  static final GlobalAudioManager _instance = GlobalAudioManager._internal();
  factory GlobalAudioManager() => _instance;
  GlobalAudioManager._internal();

  AudioPlayer? _currentPlayer;
  String? _currentPlayerId;

  /// Register a player as the currently playing one.
  /// Any previously playing audio will be paused.
  void registerPlaying(AudioPlayer player, String playerId) {
    if (_currentPlayer != null && _currentPlayerId != playerId) {
      try {
        _currentPlayer!.pause();
      } catch (_) {
        // Ignore errors if player is disposed
      }
    }
    _currentPlayer = player;
    _currentPlayerId = playerId;
  }

  /// Unregister a player (call when audio stops or widget disposes).
  void unregister(String playerId) {
    if (_currentPlayerId == playerId) {
      _currentPlayer = null;
      _currentPlayerId = null;
    }
  }

  /// Whether a specific player is the currently active one.
  bool isCurrentPlayer(String playerId) => _currentPlayerId == playerId;
}
