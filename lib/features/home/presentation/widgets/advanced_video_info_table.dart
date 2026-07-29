import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'loading_placeholder_widget.dart';

/// Tabla de información del video para el modo avanzado.
///
/// Muestra: Nombre, Duración, Fecha, Bit rate (editable), FPS.
///
/// Unidades:
///   - FFprobe devuelve bitrate en bps.
///   - La UI muestra y recibe kbps.
///   - [onBitrateChanged] devuelve el valor en kbps introducido por el usuario.
class AdvancedVideoInfoTable extends StatefulWidget {
  final VideoFile videoFile;

  /// Callback invocado cuando el usuario cambia el bitrate.
  /// Recibe el valor en kbps. Null si el campo es inválido.
  final ValueChanged<int?> onBitrateChanged;

  /// Si true, muestra shimmer en el campo Peso (usado en la sección Resultado).
  final bool isSizeLoading;

  /// Tamaño final real del archivo (en MB). Null mientras no esté disponible.
  final double? finalSizeMB;

  const AdvancedVideoInfoTable({
    super.key,
    required this.videoFile,
    required this.onBitrateChanged,
    this.isSizeLoading = false,
    this.finalSizeMB,
  });

  @override
  State<AdvancedVideoInfoTable> createState() => _AdvancedVideoInfoTableState();
}

class _AdvancedVideoInfoTableState extends State<AdvancedVideoInfoTable> {
  late final TextEditingController _bitrateController;
  String? _bitrateError;

  @override
  void initState() {
    super.initState();
    final initialKbps = widget.videoFile.bitrate ~/ 1000;
    _bitrateController = TextEditingController(
      text: initialKbps > 0 ? initialKbps.toString() : '',
    );
  }

  @override
  void dispose() {
    _bitrateController.dispose();
    super.dispose();
  }

  void _onBitrateInput(String value) {
    if (value.isEmpty) {
      setState(() => _bitrateError = 'Introduce un bit rate válido');
      widget.onBitrateChanged(null);
      return;
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      setState(() => _bitrateError = 'El bit rate debe ser mayor que 0');
      widget.onBitrateChanged(null);
      return;
    }
    if (parsed > 100000) {
      setState(() => _bitrateError = 'Valor demasiado alto (máx. 100 000 kbps)');
      widget.onBitrateChanged(null);
      return;
    }
    setState(() => _bitrateError = null);
    widget.onBitrateChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Información del vídeo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.blue,
                  fontSize: 16,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildRow(
                context,
                icon: Icons.description_outlined,
                label: 'Nombre',
                value: widget.videoFile.shortName,
              ),
              _buildDivider(),
              _buildRow(
                context,
                icon: Icons.schedule,
                label: 'Duración',
                value: widget.videoFile.formattedDuration,
              ),
              _buildDivider(),
              _buildRow(
                context,
                icon: Icons.calendar_today,
                label: 'Fecha',
                value: _formatDate(widget.videoFile.createdAt),
              ),
              if (widget.isSizeLoading || widget.finalSizeMB != null) ...[
                _buildDivider(),
                _buildSizeRow(context),
              ],
              _buildDivider(),
              _buildBitrateRow(context),
              _buildDivider(),
              _buildRow(
                context,
                icon: Icons.speed,
                label: 'FPS',
                value: _formatFps(widget.videoFile.fps),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[400]),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fila de Peso con shimmer granular mientras FFmpeg procesa.
  Widget _buildSizeRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.storage, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Peso',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[400]),
                ),
                if (widget.isSizeLoading)
                  const LoadingPlaceholderWidget(width: 80, height: 14)
                else
                  Text(
                    '${widget.finalSizeMB!.toStringAsFixed(2)} MB',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fila de Bit rate con TextField editable.
  Widget _buildBitrateRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.tune, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Bit rate',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[400]),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 36,
                      child: TextField(
                        controller: _bitrateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          suffixText: 'kbps',
                          suffixStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                        onChanged: _onBitrateInput,
                      ),
                    ),
                    if (_bitrateError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _bitrateError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(
        height: 1,
        color: Colors.grey[800],
        margin: const EdgeInsets.symmetric(horizontal: 16),
      );

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatFps(double fps) {
    if (fps <= 0) return '--';
    if (fps == fps.roundToDouble()) return '${fps.round()} fps';
    return '${fps.toStringAsFixed(2)} fps';
  }
}
