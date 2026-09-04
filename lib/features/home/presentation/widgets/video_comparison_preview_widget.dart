import 'dart:io';

import 'package:before_after/before_after.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Widget interactivo para comparar video original y comprimido (Antes / Después)
/// con sincronización de reproducción y deslizador interactivo `before_after`.
class VideoComparisonPreviewWidget extends StatefulWidget {
  final String originalVideoPath;
  final String compressedVideoPath;
  final String? thumbnailPath;
  final double? width;
  final double? height;

  const VideoComparisonPreviewWidget({
    super.key,
    required this.originalVideoPath,
    required this.compressedVideoPath,
    this.thumbnailPath,
    this.width,
    this.height,
  });

  @override
  State<VideoComparisonPreviewWidget> createState() =>
      _VideoComparisonPreviewWidgetState();
}

class _VideoComparisonPreviewWidgetState
    extends State<VideoComparisonPreviewWidget> {
  VideoPlayerController? _controllerBefore;
  VideoPlayerController? _controllerAfter;

  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _hasError = false;
  String? _errorMessage;

  double _sliderValue = 0.5;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant VideoComparisonPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalVideoPath != widget.originalVideoPath ||
        oldWidget.compressedVideoPath != widget.compressedVideoPath) {
      _disposeControllers();
      _initControllers();
    }
  }

  Future<void> _initControllers() async {
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final fileBefore = File(widget.originalVideoPath);
      final fileAfter = File(widget.compressedVideoPath);

      if (!fileBefore.existsSync() || !fileAfter.existsSync()) {
        throw Exception('Uno de los archivos de video no existe.');
      }

      final cBefore = VideoPlayerController.file(fileBefore);
      final cAfter = VideoPlayerController.file(fileAfter);

      _controllerBefore = cBefore;
      _controllerAfter = cAfter;

      await Future.wait([cBefore.initialize(), cAfter.initialize()]);

      await cBefore.setLooping(true);
      await cAfter.setLooping(true);

      // Silenciamos el video comprimido para evitar duplicación de audio / eco
      await cBefore.setVolume(1.0);
      await cAfter.setVolume(0.0);

      cBefore.addListener(_onControllerTick);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _duration = cBefore.value.duration;
        });
      }
    } catch (e) {
      debugPrint('Error inicializando reproductores de comparación: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onControllerTick() {
    if (!mounted || _controllerBefore == null || _isSeeking) return;

    final pos = _controllerBefore!.value.position;
    final isPlaying = _controllerBefore!.value.isPlaying;

    // Corrección de deriva entre ambos videos si difieren por más de 200 ms
    if (_controllerAfter != null && _controllerAfter!.value.isInitialized) {
      final afterPos = _controllerAfter!.value.position;
      final drift = (pos - afterPos).inMilliseconds.abs();
      if (drift > 200) {
        _controllerAfter!.seekTo(pos);
      }
    }

    setState(() {
      _position = pos;
      _isPlaying = isPlaying;
    });
  }

  Future<void> _togglePlay() async {
    if (!_isInitialized ||
        _controllerBefore == null ||
        _controllerAfter == null) {
      return;
    }

    if (_isPlaying) {
      await Future.wait([
        _controllerBefore!.pause(),
        _controllerAfter!.pause(),
      ]);
    } else {
      final pos = _controllerBefore!.value.position;
      await _controllerAfter!.seekTo(pos);
      await Future.wait([_controllerBefore!.play(), _controllerAfter!.play()]);
    }

    if (mounted) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  Future<void> _seekTo(double valueMs) async {
    if (!_isInitialized ||
        _controllerBefore == null ||
        _controllerAfter == null) {
      return;
    }

    final target = Duration(milliseconds: valueMs.toInt());
    await Future.wait([
      _controllerBefore!.seekTo(target),
      _controllerAfter!.seekTo(target),
    ]);

    if (mounted) {
      setState(() {
        _position = target;
        _isSeeking = false;
      });
    }
  }

  Future<void> _toggleMute() async {
    if (_controllerBefore == null) return;
    final nextMuted = !_isMuted;
    await _controllerBefore!.setVolume(nextMuted ? 0.0 : 1.0);
    if (mounted) {
      setState(() {
        _isMuted = nextMuted;
      });
    }
  }

  void _disposeControllers() {
    _controllerBefore?.removeListener(_onControllerTick);
    _controllerBefore?.dispose();
    _controllerAfter?.dispose();
    _controllerBefore = null;
    _controllerAfter = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildFallback(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.amber, size: 36),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'No se pudo reproducir la comparación',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized ||
        _controllerBefore == null ||
        _controllerAfter == null) {
      return _buildFallback(
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Cargando comparativa...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final cBefore = _controllerBefore!;
    final cAfter = _controllerAfter!;
    final videoAspect = cBefore.value.aspectRatio > 0
        ? cBefore.value.aspectRatio
        : (16 / 9);

    final containerHeight = widget.height ?? 250;

    return Container(
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Área de visualización interactiva Antes / Después
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: Container(
              height: containerHeight,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: videoAspect,
                      child: BeforeAfter(
                        value: _sliderValue,
                        onValueChanged: (v) => setState(() => _sliderValue = v),
                        before: SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: cBefore.value.size.width,
                              height: cBefore.value.size.height,
                              child: VideoPlayer(cBefore),
                            ),
                          ),
                        ),
                        after: SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: cAfter.value.size.width,
                              height: cAfter.value.size.height,
                              child: VideoPlayer(cAfter),
                            ),
                          ),
                        ),
                        trackColor: Colors.white70,
                        thumbColor: Colors.blueAccent,
                      ),
                    ),
                  ),

                  // Insignia "Antes (Original)" en la esquina superior izquierda
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildBadge(
                      label: 'Antes (Original)',
                      color: Colors.blueAccent.withValues(alpha: 0.85),
                    ),
                  ),

                  // Insignia "Después (Comprimido)" en la esquina superior derecha
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _buildBadge(
                      label: 'Después (Comprimido)',
                      color: Colors.green.withValues(alpha: 0.85),
                    ),
                  ),

                  // Botón central de reproducción cuando está pausado
                  if (!_isPlaying)
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.65),
                          border: Border.all(color: Colors.white70, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Barra inferior de controles
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF181818),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
            ),
            child: Row(
              children: [
                // Play / Pause
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _togglePlay,
                  splashRadius: 20,
                  tooltip: _isPlaying ? 'Pausar' : 'Reproducir',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),

                const SizedBox(width: 4),

                // Tiempo actual / total
                Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(width: 6),

                // Scrubber de progreso
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      trackHeight: 3,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 10,
                      ),
                      activeTrackColor: Colors.blueAccent,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      min: 0,
                      max: _duration.inMilliseconds.toDouble() > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 1.0,
                      value: _position.inMilliseconds.toDouble().clamp(
                        0.0,
                        _duration.inMilliseconds.toDouble() > 0
                            ? _duration.inMilliseconds.toDouble()
                            : 1.0,
                      ),
                      onChangeStart: (_) => _isSeeking = true,
                      onChanged: (v) {
                        setState(() {
                          _position = Duration(milliseconds: v.toInt());
                        });
                      },
                      onChangeEnd: (v) => _seekTo(v),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Botón de silenciar/activar audio
                IconButton(
                  icon: Icon(
                    _isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: _isMuted ? Colors.white54 : Colors.white,
                    size: 20,
                  ),
                  onPressed: _toggleMute,
                  splashRadius: 18,
                  tooltip: _isMuted ? 'Activar sonido' : 'Silenciar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),

                // Botón para pantalla completa
                IconButton(
                  icon: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: _openFullScreen,
                  splashRadius: 18,
                  tooltip: 'Pantalla completa',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFullScreen() async {
    if (_isPlaying) {
      await _togglePlay();
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenComparisonScreen(
          originalVideoPath: widget.originalVideoPath,
          compressedVideoPath: widget.compressedVideoPath,
          initialPosition: _position,
          initialSliderValue: _sliderValue,
          initialIsMuted: _isMuted,
        ),
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 4),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildFallback({required Widget child}) {
    final hasThumbnail =
        widget.thumbnailPath != null &&
        File(widget.thumbnailPath!).existsSync();

    return Container(
      width: double.infinity,
      height: widget.height ?? 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[900],
        image: hasThumbnail
            ? DecorationImage(
                image: FileImage(File(widget.thumbnailPath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.5),
        ),
        child: Center(child: child),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hours = d.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

/// Pantalla completa inmersiva para la comparativa interactiva Antes / Después.
class FullScreenComparisonScreen extends StatefulWidget {
  final String originalVideoPath;
  final String compressedVideoPath;
  final Duration initialPosition;
  final double initialSliderValue;
  final bool initialIsMuted;

  const FullScreenComparisonScreen({
    super.key,
    required this.originalVideoPath,
    required this.compressedVideoPath,
    this.initialPosition = Duration.zero,
    this.initialSliderValue = 0.5,
    this.initialIsMuted = false,
  });

  @override
  State<FullScreenComparisonScreen> createState() =>
      _FullScreenComparisonScreenState();
}

class _FullScreenComparisonScreenState
    extends State<FullScreenComparisonScreen> {
  VideoPlayerController? _controllerBefore;
  VideoPlayerController? _controllerAfter;

  bool _isInitialized = false;
  bool _isPlaying = false;
  late bool _isMuted;
  late double _sliderValue;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isSeeking = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.initialIsMuted;
    _sliderValue = widget.initialSliderValue;
    _position = widget.initialPosition;
    _initControllers();
  }

  Future<void> _initControllers() async {
    try {
      final fileBefore = File(widget.originalVideoPath);
      final fileAfter = File(widget.compressedVideoPath);

      final cBefore = VideoPlayerController.file(fileBefore);
      final cAfter = VideoPlayerController.file(fileAfter);

      _controllerBefore = cBefore;
      _controllerAfter = cAfter;

      await Future.wait([cBefore.initialize(), cAfter.initialize()]);

      await cBefore.setLooping(true);
      await cAfter.setLooping(true);

      await cBefore.setVolume(_isMuted ? 0.0 : 1.0);
      await cAfter.setVolume(0.0);

      if (widget.initialPosition > Duration.zero) {
        await Future.wait([
          cBefore.seekTo(widget.initialPosition),
          cAfter.seekTo(widget.initialPosition),
        ]);
      }

      cBefore.addListener(_onControllerTick);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _duration = cBefore.value.duration;
        });
      }
    } catch (e) {
      debugPrint('Error inicializando pantalla completa de comparación: $e');
    }
  }

  void _onControllerTick() {
    if (!mounted || _controllerBefore == null || _isSeeking) return;

    final pos = _controllerBefore!.value.position;
    final isPlaying = _controllerBefore!.value.isPlaying;

    if (_controllerAfter != null && _controllerAfter!.value.isInitialized) {
      final afterPos = _controllerAfter!.value.position;
      final drift = (pos - afterPos).inMilliseconds.abs();
      if (drift > 200) {
        _controllerAfter!.seekTo(pos);
      }
    }

    setState(() {
      _position = pos;
      _isPlaying = isPlaying;
    });
  }

  Future<void> _togglePlay() async {
    if (!_isInitialized ||
        _controllerBefore == null ||
        _controllerAfter == null) {
      return;
    }

    if (_isPlaying) {
      await Future.wait([
        _controllerBefore!.pause(),
        _controllerAfter!.pause(),
      ]);
    } else {
      final pos = _controllerBefore!.value.position;
      await _controllerAfter!.seekTo(pos);
      await Future.wait([_controllerBefore!.play(), _controllerAfter!.play()]);
    }

    if (mounted) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  Future<void> _seekTo(double valueMs) async {
    if (!_isInitialized ||
        _controllerBefore == null ||
        _controllerAfter == null) {
      return;
    }

    final target = Duration(milliseconds: valueMs.toInt());
    await Future.wait([
      _controllerBefore!.seekTo(target),
      _controllerAfter!.seekTo(target),
    ]);

    if (mounted) {
      setState(() {
        _position = target;
        _isSeeking = false;
      });
    }
  }

  Future<void> _toggleMute() async {
    if (_controllerBefore == null) return;
    final nextMuted = !_isMuted;
    await _controllerBefore!.setVolume(nextMuted ? 0.0 : 1.0);
    if (mounted) {
      setState(() {
        _isMuted = nextMuted;
      });
    }
  }

  @override
  void dispose() {
    _controllerBefore?.removeListener(_onControllerTick);
    _controllerBefore?.dispose();
    _controllerAfter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video interactivo centrado ocupando el espacio disponible
            if (_isInitialized &&
                _controllerBefore != null &&
                _controllerAfter != null) ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                  });
                },
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controllerBefore!.value.aspectRatio > 0
                        ? _controllerBefore!.value.aspectRatio
                        : 16 / 9,
                    child: BeforeAfter(
                      value: _sliderValue,
                      onValueChanged: (v) => setState(() => _sliderValue = v),
                      before: SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _controllerBefore!.value.size.width,
                            height: _controllerBefore!.value.size.height,
                            child: VideoPlayer(_controllerBefore!),
                          ),
                        ),
                      ),
                      after: SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _controllerAfter!.value.size.width,
                            height: _controllerAfter!.value.size.height,
                            child: VideoPlayer(_controllerAfter!),
                          ),
                        ),
                      ),
                      trackColor: Colors.white70,
                      thumbColor: Colors.blueAccent,
                    ),
                  ),
                ),
              ),

              // Badges
              Positioned(
                top: 16,
                left: 16,
                child: _buildBadge(
                  label: 'Antes (Original)',
                  color: Colors.blueAccent.withValues(alpha: 0.85),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: _buildBadge(
                  label: 'Después (Comprimido)',
                  color: Colors.green.withValues(alpha: 0.85),
                ),
              ),

              // Botón central de play cuando está pausado
              if (!_isPlaying && _showControls)
                Center(
                  child: GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.65),
                        border: Border.all(color: Colors.white70, width: 2),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
            ] else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Barra inferior de controles
            if (_showControls && _isInitialized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _togglePlay,
                        tooltip: _isPlaying ? 'Pausar' : 'Reproducir',
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            trackHeight: 3,
                            activeTrackColor: Colors.blueAccent,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            min: 0,
                            max: _duration.inMilliseconds.toDouble() > 0
                                ? _duration.inMilliseconds.toDouble()
                                : 1.0,
                            value: _position.inMilliseconds.toDouble().clamp(
                              0.0,
                              _duration.inMilliseconds.toDouble() > 0
                                  ? _duration.inMilliseconds.toDouble()
                                  : 1.0,
                            ),
                            onChangeStart: (_) => _isSeeking = true,
                            onChanged: (v) {
                              setState(() {
                                _position = Duration(milliseconds: v.toInt());
                              });
                            },
                            onChangeEnd: (v) => _seekTo(v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Icon(
                          _isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: _isMuted ? Colors.white54 : Colors.white,
                          size: 22,
                        ),
                        onPressed: _toggleMute,
                        tooltip: _isMuted ? 'Activar sonido' : 'Silenciar',
                      ),
                      // Botón para salir de pantalla completa (contraer)
                      IconButton(
                        icon: const Icon(
                          Icons.fullscreen_exit_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Salir de pantalla completa',
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

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 4),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hours = d.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
