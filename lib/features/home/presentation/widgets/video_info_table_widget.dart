import 'package:flutter/material.dart';

/// Modelo para la información del video (mock)
class VideoInfo {
  final String name;
  final String duration;
  final String date;
  final String size;
  final String bitRate;

  const VideoInfo({
    required this.name,
    required this.duration,
    required this.date,
    required this.size,
    required this.bitRate,
  });

  /// Factory para crear datos mock
  factory VideoInfo.mock() {
    return const VideoInfo(
      name: 'Viaje a la playa.mp4',
      duration: '00:02:45',
      date: '14 jul. 2025 10:30 a. m.',
      size: '52.4 MB',
      bitRate: '2540 kbps',
    );
  }
}

/// Widget que muestra la información del video en forma de tabla
class VideoInfoTableWidget extends StatelessWidget {
  /// Información del video a mostrar
  final VideoInfo videoInfo;

  const VideoInfoTableWidget({super.key, required this.videoInfo});

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
                value: videoInfo.name,
              ),
              _buildDivider(),
              _buildInfoRow(
                context,
                icon: Icons.schedule,
                label: 'Duración',
                value: videoInfo.duration,
              ),
              _buildDivider(),
              _buildInfoRow(
                context,
                icon: Icons.calendar_today,
                label: 'Fecha',
                value: videoInfo.date,
              ),
              _buildDivider(),
              _buildInfoRow(
                context,
                icon: Icons.storage,
                label: 'Peso',
                value: videoInfo.size,
              ),
              _buildDivider(),
              _buildInfoRow(
                context,
                icon: Icons.speed,
                label: 'Bit rate',
                value: videoInfo.bitRate,
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
