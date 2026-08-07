import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';

import 'loading_placeholder_widget.dart';
import 'video_preview_widget.dart';

/// Widget que muestra la información del video en forma de tabla
class VideoInfoTableWidget extends StatelessWidget {
  final VideoFile videoFile;
  final bool isLoading;
  final String? thumbnailPath;

  const VideoInfoTableWidget({
    super.key,
    required this.videoFile,
    this.isLoading = false,
    this.thumbnailPath,
  });

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

        if (thumbnailPath != null || videoFile.thumbnailPath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: VideoPreviewWidget(
              thumbnailPath: thumbnailPath ?? videoFile.thumbnailPath,
              height: 180,
              mode: PreviewMode.play,
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
              _buildInfoRow(
                context,
                icon: Icons.description_outlined,
                label: 'Nombre',
                value: videoFile.shortName,
              ),

              _buildDivider(),

              _buildInfoRow(
                context,
                icon: Icons.calendar_today,
                label: 'Fecha',
                value: _formatDate(videoFile.createdAt),
              ),

              _buildDivider(),

              _buildInfoRow(
                context,
                icon: Icons.schedule,
                label: 'Duración',
                value: videoFile.formattedDuration,
              ),

              _buildDivider(),

              _buildInfoRow(
                context,
                icon: Icons.photo_size_select_large,
                label: 'Dimensión',
                value: '${videoFile.width}x${videoFile.height}p',
              ),

              _buildDivider(),

              _buildInfoRow(
                context,
                icon: Icons.storage,
                label: 'Peso',
                value: '${videoFile.sizeMB.toStringAsFixed(1)} MB',
              ),

              _buildDivider(),

              _buildInfoRow(
                context,
                icon: Icons.speed,
                label: 'Bit rate',
                value: _formatBitrate(videoFile.bitrate),
              ),

              _buildDivider(),

              _buildInfoRow(
                context,
                icon: Icons.show_chart,
                label: 'FPS',
                value: _formatFps(videoFile.fps),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                ),

                if (isLoading)
                  const LoadingPlaceholderWidget(width: 110, height: 14)
                else
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

  /// Convierte bps a una representación legible:
  /// ≥ 1 Mbps → "X.X Mbps", < 1 Mbps → "X kbps", 0 → "--"
  String _formatBitrate(int bps) {
    if (bps <= 0) return '--';
    if (bps >= 1000000) {
      final mbps = bps / 1000000;
      return '${mbps.toStringAsFixed(1)} Mbps';
    }
    final kbps = bps ~/ 1000;
    return '$kbps kbps';
  }

  String _formatFps(double fps) {
    if (fps <= 0) return '--';
    if (fps == fps.roundToDouble()) return '${fps.round()} fps';
    return '${fps.toStringAsFixed(2)} fps';
  }
}
