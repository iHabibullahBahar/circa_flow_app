import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

import '../shared/message_reply_preview.dart';

/// Inline video message bubble with lazy-init player.
///
/// - Tap play → lazy-initialise VideoPlayerController
/// - Tapping the video while playing shows/hides controls
/// - Expand button pushes [_FullscreenVideoPlayer]
/// - Consistent purple-gradient / theme bubble styling
class VideoMessageBubble extends StatefulWidget {
  const VideoMessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.groupStatus,
    this.showTimestamp = false,
    this.onTap,
    this.contactName = 'Contact',
    this.onReplyTap,
  });

  final types.VideoMessage message;
  final bool isSentByMe;
  final types.MessageGroupStatus? groupStatus;
  final bool showTimestamp;
  final VoidCallback? onTap;
  final String contactName;
  final VoidCallback? onReplyTap;

  bool get isFirstInGroup => groupStatus == null || groupStatus!.isFirst;
  bool get isLastInGroup => groupStatus == null || groupStatus!.isLast;

  @override
  State<VideoMessageBubble> createState() => _VideoMessageBubbleState();
}

class _VideoMessageBubbleState extends State<VideoMessageBubble> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _initializing = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _hasError = false;
  double _aspectRatio = 16 / 9;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _initController() async {
    if (_initializing || _initialized) return;
    setState(() => _initializing = true);

    try {
      final uri = widget.message.source;
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(uri));
      await _ctrl!.initialize();
      _ctrl!.setLooping(false);
      _ctrl!.addListener(_onVideoEvent);
      if (mounted) {
        setState(() {
          _initialized = true;
          _initializing = false;
          _aspectRatio = _ctrl!.value.aspectRatio;
          _total = _ctrl!.value.duration;
        });
      }
    } catch (e) {
      debugPrint('VideoMessageBubble: $e');
      if (mounted) setState(() { _hasError = true; _initializing = false; });
    }
  }

  void _onVideoEvent() {
    if (!mounted) return;
    final v = _ctrl!.value;
    setState(() {
      _isPlaying = v.isPlaying;
      _position = v.position;
      _total = v.duration;
    });
    if (_isPlaying && _showControls) _startHideTimer();
    if (v.position >= v.duration && !v.isPlaying) {
      setState(() => _showControls = true);
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) setState(() => _showControls = false);
    });
  }

  Future<void> _togglePlay() async {
    if (!_initialized && !_initializing) {
      await _initController();
      if (_initialized && _ctrl != null) {
        _ctrl!.play();
        _startHideTimer();
      }
      return;
    }
    if (_ctrl == null || !_initialized) return;
    if (_isPlaying) {
      _ctrl!.pause();
      setState(() => _showControls = true);
    } else {
      _ctrl!.play();
      _startHideTimer();
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls && _isPlaying) _startHideTimer();
  }

  void _openFullscreen() {
    if (_ctrl == null || !_initialized) return;
    final wasPlaying = _isPlaying;
    _ctrl!.pause();
        Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) => _FullscreenVideoPlayer(
            videoUrl: widget.message.source,
            initialPosition: _position,
          ),
        ))
        .then((_) { if (wasPlaying) _ctrl!.play(); });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── Builder helpers ─────────────────────────────────────────────────────

  Widget _shimmer(double w, double h) => Shimmer.fromColors(
        baseColor: Colors.grey.shade900,
        highlightColor: Colors.grey.shade800,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

  Widget _errorWidget(BuildContext context, double w, double h) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white54, size: 40),
            const SizedBox(height: 8),
            Text(
              'Video unavailable',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewButton(double w, double h) => GestureDetector(
        onTap: _togglePlay,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  size: 36, color: Colors.white),
            ),
          ),
        ),
      );

  Widget _player(BuildContext context, double maxW) {
    double vW = maxW;
    double vH = vW / _aspectRatio;
    const maxH = 300.0;
    const minH = 150.0;
    if (vH > maxH) { vH = maxH; vW = vH * _aspectRatio; }
    if (vH < minH) vH = minH;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: vW,
        height: vH,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _ctrl!.value.size.width,
                  height: _ctrl!.value.size.height,
                  child: VideoPlayer(_ctrl!),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleControls,
                child: Container(color: Colors.transparent),
              ),
            ),
            if (_showControls)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: _openFullscreen,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.fullscreen_rounded,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Text(_fmt(_position),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.3),
                                  thumbColor: Colors.white,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 5),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 10),
                                  trackHeight: 2,
                                ),
                                child: Slider(
                                  value: _position.inMilliseconds
                                      .toDouble()
                                      .clamp(0, _total.inMilliseconds.toDouble()),
                                  max: _total.inMilliseconds.toDouble(),
                                  min: 0,
                                  onChanged: (v) => _ctrl?.seekTo(
                                      Duration(milliseconds: v.toInt())),
                                ),
                              ),
                            ),
                            Text(_fmt(_total),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
              _formatDt(widget.message.createdAt),
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
    final cs = Theme.of(context).colorScheme;
    final maxW = MediaQuery.of(context).size.width * 0.70;
    final fallbackH = (maxW / _aspectRatio).clamp(150.0, 300.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          widget.isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
              constraints: BoxConstraints(maxWidth: maxW),
              margin: EdgeInsets.only(
                left: 12,
                right: 12,
                top: widget.isFirstInGroup ? 8 : 1,
                bottom: widget.isLastInGroup ? 8 : 1,
              ),
              child: _hasError
                  ? _errorWidget(context, maxW, fallbackH)
                  : _initializing
                      ? _shimmer(maxW, fallbackH)
                      : !_initialized
                          ? _previewButton(maxW, fallbackH)
                          : _player(context, maxW),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Fullscreen player ────────────────────────────────────────────────────────

class _FullscreenVideoPlayer extends StatefulWidget {
  const _FullscreenVideoPlayer({
    required this.videoUrl,
    this.initialPosition = Duration.zero,
  });

  final String videoUrl;
  final Duration initialPosition;

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _init();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _ctrl?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _ctrl!.initialize();
      _ctrl!.setLooping(false);
      if (widget.initialPosition > Duration.zero) {
        await _ctrl!.seekTo(widget.initialPosition);
      }
      _ctrl!.addListener(() {
        if (!mounted) return;
        final v = _ctrl!.value;
        setState(() {
          _isPlaying = v.isPlaying;
          _position = v.position;
          _total = v.duration;
        });
        if (_isPlaying && _showControls) _startHide();
        if (v.position >= v.duration && !v.isPlaying) {
          setState(() => _showControls = true);
        }
      });
      if (mounted) {
        setState(() {
          _initialized = true;
          _total = _ctrl!.value.duration;
        });
        _ctrl!.play();
        setState(() => _showControls = false);
      }
    } catch (e) {
      debugPrint('FullscreenVideoPlayer: $e');
    }
  }

  void _startHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls && _isPlaying) _startHide();
  }

  void _togglePlay() {
    if (_ctrl == null || !_initialized) return;
    if (_isPlaying) {
      _ctrl!.pause();
      setState(() => _showControls = true);
    } else {
      _ctrl!.play();
      _startHide();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          if (_initialized)
            Center(
              child: AspectRatio(
                aspectRatio: _ctrl!.value.aspectRatio,
                child: VideoPlayer(_ctrl!),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading video…',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
              child: Container(color: Colors.transparent),
            ),
          ),
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.15, 0.85, 1.0],
                    colors: [
                      Color(0xAA000000),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xCC000000),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    color:
                                        Colors.white.withValues(alpha: 0.15),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Row(
                          children: [
                            Text(_fmt(_position),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.3),
                                  thumbColor: Colors.white,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 12),
                                  trackHeight: 2,
                                ),
                                child: Slider(
                                  value: _position.inMilliseconds
                                      .toDouble()
                                      .clamp(
                                          0,
                                          _total.inMilliseconds
                                              .toDouble()),
                                  max: _total.inMilliseconds.toDouble(),
                                  min: 0,
                                  onChanged: (v) => _ctrl?.seekTo(
                                      Duration(
                                          milliseconds: v.toInt())),
                                ),
                              ),
                            ),
                            Text(_fmt(_total),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDt(DateTime? dt) {
  if (dt == null) return '';
  final l = dt.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
