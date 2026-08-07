import 'package:flutter/material.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/advanced_compression_config.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';

/// Diálogo "Antes vs Después" para la compresión avanzada con FFmpeg.
///
/// Muestra una comparación de bitrate, FPS y peso estimado.
/// Devuelve [AdvancedCompressionConfig] al confirmar, o null al cancelar.
class AdvancedCompressionDialog extends StatelessWidget {
  // Ajusta estos porcentajes para cambiar el tamaño del diálogo.
  static const double _dialogWidthPercent = 92;
  static const double _dialogHeightPercent = 32;

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
    final dialogWidth = ScreenSizeService.widthPercent(context, _dialogWidthPercent);
    final dialogHeight = ScreenSizeService.heightPercent(context, _dialogHeightPercent);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Center(
        child: Text(
          'Confirmar compresión',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight*0.45,
        child: Center(
          child: _ComparisonTable(
            originalKbps: originalKbps,
            targetKbps: targetBitrateKbps,
            originalFps: originalFps,
            targetFps: targetFps != null ? targetFps!.toDouble() : originalFps,
            originalMB: video.sizeMB,
            estimatedMB: estimatedMB,
          ),
        ),
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
    final cellStyle = textTheme.bodySmall?.copyWith(
      color: Colors.grey[300],
      fontWeight: FontWeight.bold,
    );
    final headerStyle = textTheme.labelSmall?.copyWith(
      color: Colors.grey,
      letterSpacing: 1.2,
      fontWeight: FontWeight.bold,
    );
    final borderColor = Colors.grey[700]!;

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          children: [
            _buildCell(
              child: const SizedBox.shrink(),
            ),
            _buildCell(
              child: Text('ANTES', style: headerStyle, textAlign: TextAlign.center),
              isHeader: true,
              border: Border(
                top: BorderSide(color: borderColor, width: 1),
                left: BorderSide(color: borderColor, width: 1),
                right: BorderSide(color: borderColor, width: 1),
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
            _buildCell(
              child: Text('DESPUÉS', style: headerStyle, textAlign: TextAlign.center),
              isHeader: true,
              border: Border(
                top: BorderSide(color: borderColor, width: 1),
                right: BorderSide(color: borderColor, width: 1),
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
          ],
        ),
        _buildRow(
          label: 'Bit rate',
          before: '$originalKbps kbps',
          after: '$targetKbps kbps',
          cellStyle: cellStyle,
          borderColor: borderColor,
        ),
        if (originalFps != null)
          _buildRow(
            label: 'FPS',
            before: _formatFps(originalFps!),
            after: _formatFps(targetFps ?? originalFps!),
            cellStyle: cellStyle,
            borderColor: borderColor,
          ),
        if (estimatedMB != null)
          _buildRow(
            label: 'Peso est.',
            before: '${originalMB.toStringAsFixed(1)} MB',
            after: '${estimatedMB!.toStringAsFixed(1)} MB',
            cellStyle: cellStyle,
            borderColor: borderColor,
          ),
      ],
    );
  }

  TableRow _buildRow({
    required String label,
    required String before,
    required String after,
    required TextStyle? cellStyle,
    required Color borderColor,
  }) {
    return TableRow(
      children: [
        _buildCell(
          child: Text(label, style: cellStyle),
          fillColor: Colors.white.withValues(alpha: 0.03),
          border: Border(
            left: BorderSide(color: borderColor, width: 1),
            right: BorderSide(color: borderColor, width: 1),
            bottom: BorderSide(color: borderColor, width: 1),
          ),
        ),
        _buildCell(
          child: Text(before, style: cellStyle, textAlign: TextAlign.center),
          border: Border(
            right: BorderSide(color: borderColor, width: 1),
            bottom: BorderSide(color: borderColor, width: 1),
          ),
        ),
        _buildCell(
          child: Text(after, style: cellStyle, textAlign: TextAlign.center),
          border: Border(
            right: BorderSide(color: borderColor, width: 1),
            bottom: BorderSide(color: borderColor, width: 1),
          ),
        ),
      ],
    );
  }

  Widget _buildCell({
    required Widget child,
    bool isHeader = false,
    Border? border,
    Color? fillColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isHeader ? 10 : 9,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        border: border,
        color: fillColor ??
            (isHeader
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.transparent),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  String _formatFps(double fps) {
    if (fps == fps.roundToDouble()) return '${fps.round()} fps';
    return '${fps.toStringAsFixed(1)} fps';
  }
}
