import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../shared/global_audio_manager.dart';
import '../shared/message_reply_preview.dart';
import '../shared/message_status_indicator.dart';

// How many days to keep cached OGG files before auto-deletion.
const int _kAudioCacheExpiryDays = 7;

/// Full-featured audio message bubble with:
/// - Lazy-init audio player (just_audio)
/// - OGG → file download + caching (Android / iOS), FFmpeg not required on
///   Android; iOS OGG fallback attempts direct streaming.
/// - Messenger-style compact waveform visualisation
/// - Playback speed cycling (1× / 1.5× / 2×)
/// - GlobalAudioManager ensures only one audio plays at a time
class AudioMessageBubble extends StatefulWidget {
  const AudioMessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.groupStatus,
    this.showTimestamp = false,
    this.onTap,
    this.contactName = 'Contact',
    this.onReplyTap,
    this.isLastOutgoing = false,
    this.contactAvatarUrl,
  });

  final types.AudioMessage message;
  final bool isSentByMe;
  final types.MessageGroupStatus? groupStatus;
  final bool showTimestamp;
  final VoidCallback? onTap;
  final String contactName;
  final VoidCallback? onReplyTap;
  final bool isLastOutgoing;
  final String? contactAvatarUrl;

  bool get isFirstInGroup => groupStatus == null || groupStatus!.isFirst;
  bool get isLastInGroup => groupStatus == null || groupStatus!.isLast;

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _player = AudioPlayer();
  final _globalAudio = GlobalAudioManager();
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isInitialized = false;
  bool _autoPlayAfterInit = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _currentAudioSource;
  double _playbackSpeed = 1.0;

  static bool _cleanupDone = false;

  String get _playerId => widget.message.id;

  @override
  void initState() {
    super.initState();
    _checkMetadataDuration();
    _extractDurationOnly();
  }

  void _checkMetadataDuration() {
    final meta = widget.message.metadata;
    if (meta == null) return;
    final sec = meta['duration'];
    final ms = meta['durationMs'];
    if (sec is num && sec > 0) {
      _duration = Duration(seconds: sec.toInt());
      return;
    }
    if (ms is num && ms > 0) _duration = Duration(milliseconds: ms.toInt());
  }

  Future<void> _extractDurationOnly() async {
    if (_duration != Duration.zero) return;
    try {
      final src = widget.message.source;
      final isLocal =
          !src.startsWith('http://') && !src.startsWith('https://');
      final temp = AudioPlayer();
      try {
        final d = isLocal
            ? await temp.setFilePath(
                src.startsWith('file://') ? src.replaceFirst('file://', '') : src)
            : await temp.setUrl(src);
        if (mounted && d != null && d != Duration.zero) {
          setState(() => _duration = d);
        }
      } finally {
        await temp.dispose();
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(AudioMessageBubble old) {
    super.didUpdateWidget(old);
    if (old.message.source != widget.message.source && _isInitialized) {
      _isInitialized = false;
      _currentAudioSource = null;
      _initAudio();
    }
  }

  @override
  void dispose() {
    _globalAudio.unregister(_playerId);
    _player.dispose();
    super.dispose();
  }

  // ─── Cache helpers ────────────────────────────────────────────────────────

  String _cacheFileName(String url) {
    String name = url.split('/').last.split('?').first;
    if (!name.contains('.') || name.isEmpty) {
      name = 'audio_${url.hashCode.toRadixString(36)}.ogg';
    } else {
      name = name.replaceAll(RegExp(r'[^\w\-.]'), '_');
      if (!name.toLowerCase().endsWith('.ogg')) {
        name = '${name.split('.').first}_${url.hashCode.toRadixString(36)}.ogg';
      }
    }
    return name;
  }

  Future<Directory> _audioCacheDir() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/audio_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> _cleanupOldFiles() async {
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}/audio_cache');
      if (!await dir.exists()) return;
      final expiry = DateTime.now()
          .subtract(const Duration(days: _kAudioCacheExpiryDays));
      for (final f in dir.listSync()) {
        if (f is File && (await f.stat()).modified.isBefore(expiry)) {
          try { await f.delete(); } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<File?> _downloadFile(String url) async {
    try {
      if (!_cleanupDone) {
        _cleanupDone = true;
        _cleanupOldFiles();
      }
      final cacheDir = await _audioCacheDir();
      final file = File('${cacheDir.path}/${_cacheFileName(url)}');
      if (await file.exists() && (await file.stat()).size > 1024) return file;
      if (await file.exists()) await file.delete();
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        await file.writeAsBytes(res.bodyBytes);
        return file;
      }
    } catch (_) {}
    return null;
  }

  // ─── Init audio ──────────────────────────────────────────────────────────

  Future<void> _initAudio() async {
    if (_isInitialized && _currentAudioSource == widget.message.source) return;

    try {
      String src = widget.message.source;
      final isLocal =
          !src.startsWith('http://') && !src.startsWith('https://');
      final isOgg = src.toLowerCase().contains('.ogg') ||
          src.toLowerCase().contains('opus') ||
          (widget.message.metadata?['mimeType']?.toString() ?? '')
              .contains('ogg');

      // For OGG remote files, try to cache the raw file first (works on Android;
      // iOS may not decode OGG natively but just_audio will fallback gracefully).
      if (!isLocal && isOgg) {
        final cacheDir = await _audioCacheDir();
        final cached = File('${cacheDir.path}/${_cacheFileName(src)}');
        if (await cached.exists() && (await cached.stat()).size > 1024) {
          src = cached.path;
        } else {
          if (mounted) setState(() { _isLoading = true; _hasError = false; });
          final downloaded = await _downloadFile(src);
          if (downloaded != null) {
            src = downloaded.path;
          } else {
            if (mounted) setState(() { _isLoading = false; _hasError = true; });
            return;
          }
        }
      }

      // Resolve path
      final bool isLocalPath;
      if (src.startsWith('http://') || src.startsWith('https://')) {
        isLocalPath = false;
      } else if (src.startsWith('file://')) {
        src = src.replaceFirst('file://', '');
        isLocalPath = true;
      } else {
        isLocalPath = !src.contains('://');
      }

      if (isLocalPath) {
        await _player.setFilePath(src);
      } else {
        await _player.setUrl(src);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = false;
        _isInitialized = true;
        _currentAudioSource = widget.message.source;
      });

      if (_autoPlayAfterInit) {
        _autoPlayAfterInit = false;
        _player.play();
      }

      _player.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _duration = d);
      });
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player.playerStateStream.listen((state) {
        if (!mounted) return;
        if (state.processingState == ProcessingState.completed) {
          _globalAudio.unregister(_playerId);
          _player.pause();
          _player.seek(Duration.zero);
          setState(() { _position = Duration.zero; _isPlaying = false; });
          return;
        }
        setState(() {
          _isPlaying = state.playing;
          if (_isPlaying) _globalAudio.registerPlaying(_player, _playerId);
        });
      });
    } catch (e) {
      debugPrint('AudioMessageBubble: error loading audio: $e');
      if (!mounted) return;
      setState(() { _isLoading = false; _hasError = true; _autoPlayAfterInit = false; });
    }
  }

  // ─── Playback helpers ─────────────────────────────────────────────────────

  void _cycleSpeed() {
    setState(() {
      _playbackSpeed = switch (_playbackSpeed) {
        1.0 => 1.5,
        1.5 => 2.0,
        _ => 1.0,
      };
      _player.setSpeed(_playbackSpeed);
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _speedLabel() => _playbackSpeed == 1.0
      ? '1x'
      : _playbackSpeed == 1.5
          ? '1.5x'
          : '2x';

  // ─── Waveform ─────────────────────────────────────────────────────────────

  Widget _buildWaveform(Color active, Color inactive, double progress) {
    const heights = [12.0, 18.0, 14.0, 22.0, 16.0, 20.0, 12.0, 24.0,
        18.0, 14.0, 22.0, 16.0, 20.0, 14.0, 18.0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < heights.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 3,
            height: heights[i],
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: progress > (i / heights.length) ? active : inactive,
            ),
          ),
      ],
    );
  }

  // ─── Player row ──────────────────────────────────────────────────────────

  Widget _buildPlayerRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
    final iconColor = widget.isSentByMe ? Colors.white : cs.onSurface;
    final activeWave = widget.isSentByMe ? Colors.white : cs.onSurface;
    final inactiveWave = widget.isSentByMe
        ? Colors.white.withValues(alpha: 0.4)
        : cs.onSurface.withValues(alpha: 0.3);
    final durationColor = widget.isSentByMe
        ? Colors.white.withValues(alpha: 0.9)
        : cs.onSurface.withValues(alpha: 0.8);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play / Pause / Retry / Spinner
        GestureDetector(
          onTap: _isLoading
              ? null
              : _hasError
                  ? () {
                      setState(() { _isLoading = true; _hasError = false; });
                      _initAudio();
                    }
                  : () async {
                      if (!_isInitialized && !_isLoading) {
                        setState(() { _isLoading = true; _autoPlayAfterInit = true; });
                        await _initAudio();
                        return;
                      }
                      if (_isPlaying) {
                        _player.pause();
                      } else {
                        _player.play();
                      }
                    },
          child: SizedBox(
            width: 36,
            height: 36,
            child: _isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: iconColor, strokeWidth: 2),
                    ),
                  )
                : _hasError
                    ? Icon(Icons.refresh_rounded, color: iconColor, size: 28)
                    : Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: iconColor,
                        size: 32,
                      ),
          ),
        ),
        const SizedBox(width: 8),
        // Waveform
        _buildWaveform(activeWave, inactiveWave, progress),
        const SizedBox(width: 10),
        // Duration + speed
        SizedBox(
          width: 42,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isPlaying || _position > Duration.zero
                    ? _fmt(_position)
                    : _fmt(_duration),
                style: TextStyle(
                  color: durationColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isPlaying || _position > Duration.zero)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: GestureDetector(
                    onTap: _cycleSpeed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.isSentByMe
                            ? Colors.white.withValues(alpha: 0.2)
                            : cs.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _speedLabel(),
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Timestamp ────────────────────────────────────────────────────────────

  Widget _buildTimestampRow(Color textColor) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: widget.showTimestamp ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: widget.showTimestamp ? 24 : 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 4),
          child: Center(
            child: Text(
              _formatDateTime(widget.message.createdAt),
              style: TextStyle(
                  color: textColor.withValues(alpha: 0.6), fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.isSentByMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        _buildTimestampRow(cs.onSurface),
        MessageReplyPreview(
          message: widget.message,
          isSentByMe: widget.isSentByMe,
          contactName: widget.contactName,
          onReplyTap: widget.onReplyTap,
        ),
        GestureDetector(
          onTap: widget.onTap,
          child: Align(
            alignment: widget.isSentByMe
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              margin: EdgeInsets.only(
                left: 12,
                right: 12,
                top: widget.isFirstInGroup ? 8 : 1,
                bottom: widget.isLastInGroup ? 8 : 1,
              ),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isSentByMe ? null : cs.surfaceContainerHigh,
                gradient: widget.isSentByMe
                    ? const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color(0xFF4A00E0),
                          Color(0xFF8E2DE2),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildPlayerRow(context),
            ),
          ),
        ),
        MessageStatusIndicator(
          isSentByMe: widget.isSentByMe,
          isLastOutgoing: widget.isLastOutgoing,
          isSeen: widget.message.seenAt != null,
          messageId: widget.message.id,
          contactAvatarUrl: widget.contactAvatarUrl,
        ),
      ],
    );
  }
}

String _formatDateTime(DateTime? dt) {
  if (dt == null) return '';
  final l = dt.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
