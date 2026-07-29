import 'package:flutter/material.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';

/// Diálogo "Antes vs Después" para la compresión avanzada con FFmpeg.
///
/// Muestra una comparación de bitrate, FPS y peso estimado (si es calculable).
/// Devuelve [AdvancedCompressionConfig] al confirmar, o null al cancelar.
///
/// Unidades:
///   - UI muestra kbps (ej. 2500 kbps)
///   - [AdvancedCompressionConfig.targetVideoBitrate] recibe bps (ej. 2500000)
///   - Estimación de peso: tamaño_original × (bitrate_objetivo / bitrate_original)
class AdvancedCompressionDialog extends StatelessWidget {
  final VideoFile video;

  /// Bitrate objetivo en bps (ya convertido desde kbps por el caller).
  final int targetBitrateKbps;

  const AdvancedCompressionDialog({
    super.key,
    required this.video,
    required this.targetBitrateKbps,
  });

  @override
  Widget build(BuildContext context) {
    final originalKbps = video.bitrate ~/ 1000;
    final fps = video.fps > 0 ? video.fps : null;
    final estimatedMB = _estimateSize();

    return AlertDialog(
      title: const Text('Confirmar compresión'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ComparisonTable(
            originalKbps: originalKbps,
            targetKbps: targetBitrateKbps,
            fps: fps,
            originalMB: video.sizeMB,
            estimatedMB: estimatedMB,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            AdvancedCompressionConfig(
              targetVideoBitrate: targetBitrateKbps * 1000,
            ),
          ),
          child: const Text('Comprimir'),
        ),
      ],
    );
  }

  /// Estimación: tamaño_original × (bitrate_objetivo / bitrate_original).
  /// Devuelve null si el bitrate original es 0 (no se puede calcular).
  ///
  /// NOTA: es una aproximación — el audio permanece constante y el codec
  /// puede producir variaciones. Se presenta como "Peso estimado".
  double? _estimateSize() {
    if (video.bitrate <= 0) return null;
    final ratio = targetBitrateKbps * 1000 / video.bitrate;
    return video.sizeMB * ratio;
  }
}

class _ComparisonTable extends StatelessWidget {
  final int originalKbps;
  final int targetKbps;
  final double? fps;
  final double originalMB;
  final double? estimatedMB;

  const _ComparisonTable({
    required this.originalKbps,
    required this.targetKbps,
    required this.fps,
    required this.originalMB,
    required this.estimatedMB,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.bodySmall?.copyWith(color: Colors.grey);
    final headerStyle = textTheme.labelSmall?.copyWith(
      color: Colors.grey,
      letterSpacing: 1.2,
    );

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      children: [
        // Cabecera
        TableRow(
          children: [
            const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('ANTES', style: headerStyle, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('DESPUÉS', style: headerStyle, textAlign: TextAlign.center),
            ),
          ],
        ),
        // Bitrate
        _buildRow(
          label: 'Bit rate',
          before: '$originalKbps kbps',
          after: '$targetKbps kbps',
          labelStyle: labelStyle,
          context: context,
        ),
        // FPS
        if (fps != null)
          _buildRow(
            label: 'FPS',
            before: _formatFps(fps!),
            after: _formatFps(fps!),
            labelStyle: labelStyle,
            context: context,
          ),
        // Peso estimado — solo si es calculable
        if (estimatedMB != null)
          _buildRow(
            label: 'Peso est.',
            before: '${originalMB.toStringAsFixed(2)} MB',
            after: '${estimatedMB!.toStringAsFixed(2)} MB',
            labelStyle: labelStyle,
            context: context,
          ),
      ],
    );
  }

  TableRow _buildRow({
    required String label,
    required String before,
    required String after,
    required TextStyle? labelStyle,
    required BuildContext context,
  }) {
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: labelStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(before, style: valueStyle, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(after, style: valueStyle, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  String _formatFps(double fps) {
    if (fps == fps.roundToDouble()) return '${fps.round()} fps';
    return '${fps.toStringAsFixed(2)} fps';
  }
}
