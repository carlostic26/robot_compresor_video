import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:robot_compresor_video/core/services/injection_container.dart';
import 'package:robot_compresor_video/core/services/ad_service.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/core/widgets/banner_ad_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/app_drawer.dart';
import 'package:robot_compresor_video/features/home/presentation/dialogs/app_info_dialog.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/compressor_section_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/result_section_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/subir_section_widget.dart';

class CompressorScreen extends StatefulWidget {
  const CompressorScreen({super.key});

  @override
  State<CompressorScreen> createState() => _CompressorScreenState();
}

class _CompressorScreenState extends State<CompressorScreen> {
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
          title: const Text('Compresor de video'),
          leading: _showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => GoRouter.of(context).pop(),
                )
              : Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    );
                  },
                ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => AppInfoDialog.show(context),
            ),
          ],
        ),
        body: BlocConsumer<VideoBloc, VideoState>(
          listener: (context, state) async {
            debugPrint("=================================");
            debugPrint("LISTENER -> ${state.status}");

            // Volver a la primera página al reiniciar/subir otro video
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

            // Cargar metadata extendida (bitrate real, fps) tras seleccionar video
            if (state.status == VideoStatus.success &&
                state.video != null &&
                state.video!.fps == 0 &&
                state.compressionResult == null &&
                state.advancedCompressionResult == null) {
              if (!context.mounted) return;
              context.read<VideoBloc>().add(
                const LoadExtendedMetadataRequested(),
              );
            }

            /// Cuando inicia la compresión
            if (state.status == VideoStatus.compressing) {
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

            /// Cuando termina la compresión
            if (state.status == VideoStatus.success &&
                state.compressionResult != null) {
              final result = state.compressionResult!;

              if (!context.mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              messenger.clearSnackBars();

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                  content: Text(
                    '🎉 Se redujo un ${result.savedPercentage.toStringAsFixed(1)}%',
                  ),
                ),
              );

              if (!context.mounted) return;
              await AdService.showInterstitialAd();
            }
          },

          builder: (context, videoState) {
            return PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: videoState.video == null
                  ? const [SubirSection(), ResultSection()]
                  : const [CompressorSection(), ResultSection()],
            );
          },
        ),
        drawer: const AppDrawer(),
        bottomNavigationBar: const BannerAdWidget(),
      ),
    );
  }
}
