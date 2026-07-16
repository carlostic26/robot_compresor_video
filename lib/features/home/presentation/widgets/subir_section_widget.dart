import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/section_pages.dart';



class SubirSection extends StatelessWidget {
  const SubirSection({super.key});

  void _onUploadPressed(BuildContext context) {
    context.read<VideoBloc>().add(const PickVideoRequested());
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        Container(
          color: Colors.blueGrey[900],
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            height: screenHeight * 0.3,
            child: GestureDetector(
              onTap: () => _onUploadPressed(context),
              child: CustomPaint(
                painter: DashedBorderPainter(
                  color: Colors.blue.withValues(alpha: 0.5),
                  strokeWidth: 2,
                  dashWidth: 10,
                  dashSpace: 8,
                  borderRadius: 12,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono de nube con flecha hacia arriba
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 80,
                        color: Colors.blue,
                      ),
                      SizedBox(height: screenHeight * 0.015),

                      // Título principal
                      Text(
                        'Sube tu video',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                      ),
                      SizedBox(height: screenHeight * 0.005),

                      // Subtítulo
                      Text(
                        'Toca para seleccionar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Formatos soportados
                      Text(
                        'MP4, MOV, AVI, MKV',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tamaño máximo
                      Text(
                        'Tamaño máximo: 2 GB',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
