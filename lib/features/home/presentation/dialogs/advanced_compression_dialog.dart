import 'package:flutter/material.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';

/// Diálogo "Antes vs Después" para la compresión avanzada con FFmpeg.
///
/// Muestra una comparación de bitrate, FPS y peso estimado.
/// Devuelve [AdvancedCompressionConfig] al confirmar, o null al cancelar.
class AdvancedCompressionDialog extends StatelessWidget {
  final VideoFile video;

  /// Bitrate objetivo en kbps introducido por el usuario.
  final int targetBitrateKbps;

  /// FPS objetivo introducido por el usuario. Null = conservar original.
  final int? targetFps;

  const AdvancedCompressionDialog({
    super.key,
    required this.video,
    required this.targetBitrateKbps,
    this.targetFps,
  });

  @override
  Widget build(BuildContext context) {
    final originalKbps = video.bitrate ~/ 1000;
    final originalFps = video.fps > 0 ? video.fps : null;
    final estimatedMB = _estimateSize();

    return AlertDialog(
      title: const Text('Confirmar compresión'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ComparisonTable(
            originalKbps: originalKbps,
            targetKbps: targetBitrateKbps,
            originalFps: originalFps,
            targetFps: targetFps != null ? targetFps!.toDouble() : originalFps,
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
              targetFps: targetFps,
            ),
          ),
          child: const Text('Comprimir'),
        ),
      ],
    );
  }

  double? _estimateSize() {
    if (video.bitrate <= 0) return null;
    final ratio = targetBitrateKbps * 1000 / video.bitrate;
    return video.sizeMB * ratio;
  }
}

class _ComparisonTable extends StatelessWidget {
  final int originalKbps;
  final int targetKbps;
  final double? originalFps;
  final double? targetFps;
  final double originalMB;
  final double? estimatedMB;

  const _ComparisonTable({
    required this.originalKbps,
    required this.targetKbps,
    required this.originalFps,
    required this.targetFps,
    required this.originalMB,
    required this.estimatedMB,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Mismo tamaño para etiquetas y valores — equilibrio visual
    final cellStyle = textTheme.bodySmall?.copyWith(color: Colors.grey[300]);
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
        _buildRow(
          label: 'Bit rate',
          before: '$originalKbps kbps',
          after: '$targetKbps kbps',
          cellStyle: cellStyle,
        ),
        if (originalFps != null)
          _buildRow(
            label: 'FPS',
            before: _formatFps(originalFps!),
            after: _formatFps(targetFps ?? originalFps!),
            cellStyle: cellStyle,
          ),
        if (estimatedMB != null)
          _buildRow(
            label: 'Peso est.',
            before: '${originalMB.toStringAsFixed(1)} MB',
            after: '${estimatedMB!.toStringAsFixed(1)} MB',
            cellStyle: cellStyle,
          ),
      ],
    );
  }

  TableRow _buildRow({
    required String label,
    required String before,
    required String after,
    required TextStyle? cellStyle,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(label, style: cellStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(before, style: cellStyle, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(after, style: cellStyle, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  String _formatFps(double fps) {
    if (fps == fps.roundToDouble()) return '${fps.round()} fps';
    return '${fps.toStringAsFixed(1)} fps';
  }
}
