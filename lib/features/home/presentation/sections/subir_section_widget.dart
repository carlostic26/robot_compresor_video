import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/section_pages.dart';

class SubirSection extends StatelessWidget {
  const SubirSection({super.key});

  void _onUploadPressed(BuildContext context) {
    context.read<VideoBloc>().add(const PickVideoRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final isLoading = state.status == VideoStatus.picking ||
            state.status == VideoStatus.loadingExtendedMetadata;

        return Stack(
          children: [
            Column(
            
              children: [
                Padding(
                  padding: EdgeInsets.all(screenWidth*0.03),
                  child: Container(
                    color: Colors.blueGrey[900],
                    child: SizedBox(
                      width: screenWidth * 0.95,
                      height: screenHeight * 0.35,
                      child: GestureDetector(
                        onTap: isLoading ? null : () => _onUploadPressed(context),
                        child: CustomPaint(
                          painter: DashedBorderPainter(
                            color: Colors.blue.withValues(alpha: 0.5),
                            strokeWidth: 4,
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
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 80,
                                  color: Colors.blue,
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                Text(
                                  'Sube tu video',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  'Toca para seleccionar',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey[400]),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'MP4, MOV, AVI, MKV',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[500]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tamaño máximo: 2 GB',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Loading overlay: cubre toda la sección mientras se carga el video
            // o se obtiene la metadata extendida via FFprobe.
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.65),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        state.status == VideoStatus.picking
                            ? 'Cargando video...'
                            : 'Obteniendo información...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
