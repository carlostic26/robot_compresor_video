import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:robot_compresor_video/core/services/injection_container.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/advanced_compressor_section.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/advanced_result_section.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/subir_section_widget.dart';
import 'package:robot_compresor_video/core/widgets/banner_ad_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/app_drawer.dart';
import 'package:robot_compresor_video/features/home/presentation/dialogs/app_info_dialog.dart';

/// Pantalla de compresión avanzada con FFmpeg.
///
/// - Muestra [SubirSection] inicialmente y [AdvancedCompressorSection] tras elegir video.
/// - Navega automáticamente a [AdvancedResultSection] cuando inicia la compresión avanzada.
/// - Carga metadata extendida (bitrate real, fps) via FFprobe al seleccionar video.
class AdvancedCompressionScreen extends StatefulWidget {
  const AdvancedCompressionScreen({super.key});

  @override
  State<AdvancedCompressionScreen> createState() =>
      _AdvancedCompressionScreenState();
}

class _AdvancedCompressionScreenState extends State<AdvancedCompressionScreen> {
  late PageController _pageController;

  bool get _showBackButton => GoRouter.of(context).canPop();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VideoBloc>(
      create: (_) => getIt<VideoBloc>(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: const Text('Compresión avanzada'),
          leading: _showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => GoRouter.of(context).pop(),
                )
              : Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => AppInfoDialog.show(context),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: BlocConsumer<VideoBloc, VideoState>(
          listener: (context, state) async {
            // Volver a la primera página al reiniciar/subir otro video.
            if ((state.status == VideoStatus.initial ||
                    state.status == VideoStatus.picking) &&
                _pageController.hasClients &&
                _pageController.page?.round() != 0) {
              await _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
              _pageController.jumpToPage(0);
            }

            // Navegar a Resultado cuando inicia la compresión avanzada
            if (state.status == VideoStatus.compressingAdvanced) {
              if (_pageController.hasClients &&
                  _pageController.page?.round() != 1) {
                await _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                _pageController.jumpToPage(1);
              }
            }

            // Cargar metadata extendida (bitrate real, fps) tras seleccionar video
            if (state.status == VideoStatus.success &&
                state.video != null &&
                state.video!.fps == 0 &&
                state.advancedCompressionResult == null) {
              if (!context.mounted) return;
              context.read<VideoBloc>().add(
                const LoadExtendedMetadataRequested(),
              );
            }

            // Generar thumbnail del video original tras cargar metadata extendida
            if (state.status == VideoStatus.success &&
                state.video != null &&
                state.video!.bitrate > 0 &&
                state.video!.thumbnailPath == null &&
                state.advancedCompressionResult == null &&
                state.thumbnailPath == null) {
              if (!context.mounted) return;
              context.read<VideoBloc>().add(
                GenerateThumbnailRequested(state.video!.path),
              );
            }
          },
          builder: (context, videoState) {
            return PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: videoState.video == null
                  ? const [SubirSection(), AdvancedResultSection()]
                  : const [
                      AdvancedCompressorSection(),
                      AdvancedResultSection(),
                    ],
            );
          },
        ),
        bottomNavigationBar: const BannerAdWidget(),
      ),
    );
  }
}
