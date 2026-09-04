import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';

import 'loading_placeholder_widget.dart';

/// Widget que muestra la información del video en forma de tabla
class VideoInfoTableWidget extends StatefulWidget {
  final VideoFile videoFile;
  final VideoFile? originalVideoFile;
  final bool isLoading;
  final String? thumbnailPath;
  final ValueChanged<String>? onNameChanged;

  const VideoInfoTableWidget({
    super.key,
    required this.videoFile,
    this.originalVideoFile,
    this.isLoading = false,
    this.thumbnailPath,
    this.onNameChanged,
  });

  @override
  State<VideoInfoTableWidget> createState() => _VideoInfoTableWidgetState();
}

class _VideoInfoTableWidgetState extends State<VideoInfoTableWidget> {
  late final TextEditingController _nameController;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.videoFile.name);
  }

  @override
  void didUpdateWidget(covariant VideoInfoTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoFile.name != widget.videoFile.name && !_isEditingName) {
      _nameController.text = widget.videoFile.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Título
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Información del vídeo',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.blue, fontSize: 16),
          ),
        ),

        /// Tabla
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildNameRow(context),

              _buildDivider(),

              _buildInfoRow(
                context,
                icon: Icons.calendar_today,
                label: 'Fecha',
                value: _formatDate(widget.videoFile.createdAt),
              ),

              _buildDivider(),

              _buildInfoRow(
                context,
                icon: Icons.schedule,
                label: 'Duración',
                value: widget.videoFile.formattedDuration,
              ),

              _buildDivider(),

              _buildInfoRow(
                context,
                icon: Icons.photo_size_select_large,
                label: 'Dimensión',
                value: '${widget.videoFile.width}x${widget.videoFile.height}p',
              ),

              _buildDivider(),

              _buildInfoRow(
                context,
                icon: Icons.storage,
                label: 'Peso',
                value: '${widget.videoFile.sizeMB.toStringAsFixed(2)} MB',
                previousValue: widget.originalVideoFile != null
                    ? '${widget.originalVideoFile!.sizeMB.toStringAsFixed(2)} MB'
                    : null,
              ),

              _buildDivider(),

              _buildInfoRow(
                context,
                icon: Icons.speed,
                label: 'Bit rate',
                value: _formatBitrate(widget.videoFile.bitrate),
                previousValue: widget.originalVideoFile != null
                    ? _formatBitrate(widget.originalVideoFile!.bitrate)
                    : null,
              ),

              _buildDivider(),

              _buildInfoRow(
                context,
                icon: Icons.show_chart,
                label: 'FPS',
                value: _formatFps(widget.videoFile.fps),
                previousValue: widget.originalVideoFile != null
                    ? _formatFps(widget.originalVideoFile!.fps)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameRow(BuildContext context) {
    final canEdit = widget.onNameChanged != null;

    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              color: Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nombre',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                  ),
                  if (widget.isLoading)
                    const LoadingPlaceholderWidget(width: 110, height: 14)
                  else if (canEdit)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isEditingName
                                  ? Icons.check
                                  : Icons.edit_outlined,
                              size: 16,
                            ),
                            color: _isEditingName
                                ? Colors.greenAccent
                                : Colors.blue,
                            splashRadius: 16,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(right: 6),
                            onPressed: () {
                              setState(() {
                                if (_isEditingName) {
                                  widget.onNameChanged?.call(
                                    _nameController.text.trim(),
                                  );
                                  _isEditingName = false;
                                } else {
                                  _isEditingName = true;
                                }
                              });
                            },
                          ),
                          if (_isEditingName)
                            Flexible(
                              child: SizedBox(
                                height: 30,
                                child: TextField(
                                  controller: _nameController,
                                  autofocus: true,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (val) {
                                    setState(() {
                                      widget.onNameChanged?.call(val.trim());
                                      _isEditingName = false;
                                    });
                                  },
                                  onChanged: (val) {
                                    widget.onNameChanged?.call(val.trim());
                                  },
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: Colors.grey[700]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: Colors.grey[700]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Flexible(
                              child: Text(
                                widget.videoFile.shortName,
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
                    )
                  else
                    Flexible(
                      child: Text(
                        widget.videoFile.shortName,
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

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? previousValue,
  }) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue, size: 20),

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

                  if (widget.isLoading)
                    const LoadingPlaceholderWidget(width: 110, height: 14)
                  else
                    Flexible(
                      child: _buildComparisonText(
                        context,
                        previousValue: previousValue,
                        currentValue: value,
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

  Widget _buildComparisonText(
    BuildContext context, {
    String? previousValue,
    required String currentValue,
  }) {
    final hasDifference =
        previousValue != null &&
        previousValue.isNotEmpty &&
        previousValue != '--' &&
        previousValue != currentValue;

    if (hasDifference) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: previousValue,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: Colors.grey[500],
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.grey[400],
                decorationThickness: 1.5,
              ),
            ),
            TextSpan(
              text: ' → ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: currentValue,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
      );
    }

    return Text(
      currentValue,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey[800],
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  /// Formatea la fecha de procesamiento del video.
  /// Muestra la fecha de modificación del archivo (= fecha de compresión).
  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Convierte bps a kbps:
  /// e.g. 1900000 -> "1900 kbps", 997000 -> "997 kbps", <= 0 -> "--"
  String _formatBitrate(int bps) {
    if (bps <= 0) return '--';
    return '${bps ~/ 1000} kbps';
  }

  String _formatFps(double fps) {
    if (fps <= 0) return '--';
    if (fps == fps.roundToDouble()) return '${fps.round()} fps';
    return '${fps.toStringAsFixed(2)} fps';
  }
}
