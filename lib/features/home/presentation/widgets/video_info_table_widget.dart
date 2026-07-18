import 'package:flutter/material.dart';
import 'package:robot_compresor_video/features/compress_video/domain/entities/video_file.dart';

/// Widget que muestra la información del video en forma de tabla
class VideoInfoTableWidget extends StatelessWidget {
  /// Información del video a mostrar
  final VideoFile videoFile;

  const VideoInfoTableWidget({super.key, required this.videoFile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Título de la sección
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Información del vídeo',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.blue, fontSize: 16),
          ),
        ),

        /// Tabla de información
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
                value: videoFile.name,
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
                icon: Icons.calendar_today,
                label: 'Fecha',
                value: '--',
              ),
              _buildDivider(),
              _buildInfoRow(
                context,
                icon: Icons.storage,
                label: 'Peso',
                value:  '${videoFile.sizeMB.toStringAsFixed(2)} MB',
              ),
              _buildDivider(),
              _buildInfoRow(
                context,
                icon: Icons.speed,
                label: 'Bit rate',
                value: videoFile.bitrate == 0 ? '--' : '${videoFile.bitrate} kbps',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget que construye una fila de información
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          /// Icono
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),

          /// Etiqueta y valor
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
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  /// Divisor entre filas
  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey[800],
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}
