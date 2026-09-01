import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';
import 'loading_placeholder_widget.dart';
import 'video_preview_widget.dart';

/// Tabla de información del video para el modo avanzado.
///
/// Modos de uso:
/// - **Edición** (en [AdvancedCompressorSection]): Bit rate y FPS son editables.
///   Se inicializan con los valores del video original.
/// - **Resultado** (en [AdvancedResultSection]): campos de solo lectura.
///   Peso, Bit rate y FPS muestran shimmer mientras FFmpeg procesa.
///   Al terminar muestran los valores reales del archivo comprimido.
///
/// Unidades:
///   - FFprobe devuelve bitrate en bps → UI muestra/recibe kbps.
///   - [onBitrateChanged] devuelve kbps (int?). Null si inválido.
///   - [onFpsChanged] devuelve fps (int?). Null si inválido.
class AdvancedVideoInfoTable extends StatefulWidget {
  final VideoFile videoFile;
  final String? thumbnailPath;
  final PreviewMode previewMode;

  /// Callback cuando el usuario cambia el bitrate (kbps). Null si inválido.
  final ValueChanged<int?> onBitrateChanged;

  /// Callback cuando el usuario cambia los FPS. Null si inválido.
  /// Si es null, el campo FPS no es editable (modo resultado).
  final ValueChanged<int?>? onFpsChanged;

  /// Si true, muestra shimmer en Peso, Bit rate y FPS (modo resultado durante compresión).
  final bool isResultLoading;

  /// Tamaño final real del archivo (MB). Null mientras no esté disponible.
  final double? finalSizeMB;

  const AdvancedVideoInfoTable({
    super.key,
    required this.videoFile,
    this.thumbnailPath,
    this.previewMode = PreviewMode.play,
    required this.onBitrateChanged,
    this.onFpsChanged,
    this.isResultLoading = false,
    this.finalSizeMB,
  });

  // Mantener compatibilidad con el parámetro anterior isSizeLoading
  // que usaba solo shimmer en Peso. Ahora se usa isResultLoading.
  // ignore: unused_element
  bool get isSizeLoading => isResultLoading;

  @override
  State<AdvancedVideoInfoTable> createState() => _AdvancedVideoInfoTableState();
}

class _AdvancedVideoInfoTableState extends State<AdvancedVideoInfoTable> {
  late final TextEditingController _bitrateController;
  late final TextEditingController _fpsController;
  bool _bitrateTouched = false;
  bool _fpsTouched = false;
  bool _isEditingBitrate = false;
  bool _isEditingFps = false;

  @override
  void initState() {
    super.initState();
    _bitrateController = TextEditingController();
    _fpsController = TextEditingController();
    _syncDefaultValues(force: true);
  }

  @override
  void didUpdateWidget(covariant AdvancedVideoInfoTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDefaultValues();
  }

  @override
  void dispose() {
    _bitrateController.dispose();
    _fpsController.dispose();
    super.dispose();
  }

  void _onBitrateInput(String value) {
    _bitrateTouched = true;
    if (value.isEmpty) {
      widget.onBitrateChanged(null);
      return;
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0 || parsed > 100000) {
      widget.onBitrateChanged(null);
      return;
    }
    widget.onBitrateChanged(parsed);
  }

  void _onFpsInput(String value) {
    _fpsTouched = true;
    if (value.isEmpty) {
      widget.onFpsChanged?.call(null);
      return;
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0 || parsed > 240) {
      widget.onFpsChanged?.call(null);
      return;
    }
    widget.onFpsChanged?.call(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = widget.onFpsChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.previewMode == PreviewMode.processing ||
            widget.thumbnailPath != null ||
            widget.videoFile.thumbnailPath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: VideoPreviewWidget(
              thumbnailPath:
                  widget.thumbnailPath ?? widget.videoFile.thumbnailPath,
              height: 180,
              mode: widget.previewMode,
            ),
          ),

        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Información del vídeo',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.blue, fontSize: 16),
          ),
        ),
        if (isEditable)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Puedes modificar el Bit Rate y los FPS antes de comprimir.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        const Divider(),

        SizedBox(height: ScreenSizeService.heightPercent(context, 1)),

        //table
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
                icon: Icons.calendar_today,
                label: 'Fecha',
                value: _formatDate(widget.videoFile.createdAt),
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
                icon: Icons.photo_size_select_large,
                label: 'Dimensión',
                value: '${widget.videoFile.width}x${widget.videoFile.height}p',
              ),
              _buildDivider(),
              _buildSizeRow(context),
              _buildDivider(),
              _buildBitrateRow(context, isEditable: isEditable),
              _buildDivider(),
              _buildFpsRow(context, isEditable: isEditable),
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
    return SizedBox(
      height: 38,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                  ),
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fila de Peso: shimmer durante compresión, valor real al terminar.
  Widget _buildSizeRow(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.storage, color: Colors.blue, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Peso',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                  ),
                  if (widget.isResultLoading)
                    const LoadingPlaceholderWidget(width: 80, height: 14)
                  else
                    Flexible(
                      child: Text(
                        '${(widget.finalSizeMB ?? widget.videoFile.sizeMB).toStringAsFixed(2)} MB',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fila de Bit rate: editable en modo compresión, shimmer/valor en resultado.
  Widget _buildBitrateRow(BuildContext context, {required bool isEditable}) {
    if (!isEditable) {
      // Modo resultado: shimmer o valor real
      return SizedBox(
        height: 38,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.tune, color: Colors.blue, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bit rate',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                    ),
                    if (widget.isResultLoading)
                      const LoadingPlaceholderWidget(width: 80, height: 14)
                    else
                      Flexible(
                        child: Text(
                          _formatBitrate(widget.videoFile.bitrate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Modo edición: texto + lápiz para activar input
    return SizedBox(
      height: 38,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.tune, color: Colors.blue, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Bit rate',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        color: Colors.blue,
                        splashRadius: 16,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(right: 6),
                        onPressed: () {
                          setState(() {
                            _isEditingBitrate = !_isEditingBitrate;
                          });
                        },
                      ),
                      if (_isEditingBitrate)
                        _buildTextField(
                          controller: _bitrateController,
                          suffix: 'kbps',
                          onChanged: _onBitrateInput,
                          autofocus: true,
                        )
                      else
                        Text(
                          _formatBitrateFromInput(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fila de FPS: editable en modo compresión, shimmer/valor en resultado.
  Widget _buildFpsRow(BuildContext context, {required bool isEditable}) {
    if (!isEditable) {
      // Modo resultado: shimmer o valor real
      return SizedBox(
        height: 38,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.speed, color: Colors.blue, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FPS',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                    ),
                    if (widget.isResultLoading)
                      const LoadingPlaceholderWidget(width: 80, height: 14)
                    else
                      Flexible(
                        child: Text(
                          _formatFps(widget.videoFile.fps),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Modo edición: texto + lápiz para activar input
    return SizedBox(
      height: 38,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.speed, color: Colors.blue, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'FPS',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        color: Colors.blue,
                        splashRadius: 16,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(right: 6),
                        onPressed: () {
                          setState(() {
                            _isEditingFps = !_isEditingFps;
                          });
                        },
                      ),
                      if (_isEditingFps)
                        _buildTextField(
                          controller: _fpsController,
                          suffix: 'fps',
                          onChanged: _onFpsInput,
                          autofocus: true,
                          width: ScreenSizeService.widthPercent(context, 17),
                        )
                      else
                        Text(
                          _formatFpsFromInput(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String suffix,
    required ValueChanged<String> onChanged,
    bool autofocus = false,
    double width = 110,
  }) {
    return SizedBox(
      width: width,
      height: 26,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.right,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          suffixText: suffix,
          suffixStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
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
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildFieldError(String message) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(
      message,
      style: const TextStyle(color: Colors.red, fontSize: 10),
    ),
  );

  void _syncDefaultValues({bool force = false}) {
    final defaultKbps = widget.videoFile.bitrate > 0
        ? (widget.videoFile.bitrate ~/ 1000).toString()
        : '';
    final defaultFps = widget.videoFile.fps > 0
        ? widget.videoFile.fps.round().toString()
        : '';

    if ((force || !_bitrateTouched) && defaultKbps.isNotEmpty) {
      _bitrateController.text = defaultKbps;
    }

    if ((force || !_fpsTouched) && defaultFps.isNotEmpty) {
      _fpsController.text = defaultFps;
    }
  }

  String _formatBitrateFromInput() {
    final text = _bitrateController.text.trim();
    if (text.isEmpty) return '--';
    return '$text kbps';
  }

  String _formatFpsFromInput() {
    final text = _fpsController.text.trim();
    if (text.isEmpty) return '--';
    return '$text fps';
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

  String _formatBitrate(int bps) {
    if (bps <= 0) return '--';
    if (bps >= 1000000) return '${(bps / 1000000).toStringAsFixed(1)} Mbps';
    return '${bps ~/ 1000} kbps';
  }

  String _formatFps(double fps) {
    if (fps <= 0) return '--';
    if (fps == fps.roundToDouble()) return '${fps.round()} fps';
    return '${fps.toStringAsFixed(2)} fps';
  }
}
