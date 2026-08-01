import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/core/services/injection_container.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/bloc/home_section_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/advanced_compressor_section.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/advanced_result_section.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/animated_section_tabs.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/subir_section_widget.dart';
import 'package:robot_compresor_video/core/widgets/banner_ad_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/app_drawer.dart';
import 'package:robot_compresor_video/features/home/presentation/dialogs/app_info_dialog.dart';

/// Pantalla de compresión avanzada con FFmpeg.
///
/// Estructura idéntica a [HomeScreen] pero con:
/// - [AdvancedCompressorSection] en lugar de [CompressorSection].
/// - [AdvancedResultSection] en lugar de [ResultSection].
/// - Navega automáticamente a Resultado cuando inicia compresión avanzada.
/// - Carga metadata extendida (bitrate real, fps) via FFprobe al seleccionar video.
class AdvancedCompressionScreen extends StatefulWidget {
  const AdvancedCompressionScreen({super.key});

  @override
  State<AdvancedCompressionScreen> createState() =>
      _AdvancedCompressionScreenState();
}

class _AdvancedCompressionScreenState
    extends State<AdvancedCompressionScreen> {
  late PageController _pageController;
  late HomeSectionBloc _homeSectionBloc;

  @override
  void initState() {
    super.initState();
    _homeSectionBloc = HomeSectionBloc();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _homeSectionBloc.close();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _homeSectionBloc.add(PageChanged(index));
  }

  void _onTabPressed(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeSectionBloc>(
          create: (_) => _homeSectionBloc..add(const InitPage()),
        ),
        BlocProvider<VideoBloc>(create: (_) => getIt<VideoBloc>()),
      ],
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: const Text('Compresión avanzada'),
          leading: Builder(
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
            // Navegar a Resultado cuando inicia la compresión avanzada
            if (state.status == VideoStatus.compressingAdvanced) {
              if (_pageController.hasClients &&
                  _pageController.page?.round() != 1) {
                await _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                _homeSectionBloc.add(const PageChanged(1));
                _pageController.jumpToPage(1);
              }
            }

            // Cargar metadata extendida (bitrate real, fps) tras seleccionar video
            if (state.status == VideoStatus.success &&
                state.video != null &&
                state.video!.bitrate == 0 &&
                state.advancedCompressionResult == null) {
              if (!context.mounted) return;
              context
                  .read<VideoBloc>()
                  .add(const LoadExtendedMetadataRequested());
            }

            // Generar thumbnail del video original tras cargar metadata extendida
            if (state.status == VideoStatus.success &&
                state.video != null &&
                state.video!.bitrate > 0 &&
                state.video!.thumbnailPath == null &&
                state.advancedCompressionResult == null &&
                state.thumbnailPath == null) {
              if (!context.mounted) return;
              context
                  .read<VideoBloc>()
                  .add(GenerateThumbnailRequested(state.video!.path));
            }
          },
          builder: (context, videoState) {
            final sections = videoState.video == null
                ? const ['Subir', 'Resultado']
                : const ['Comprimir', 'Resultado'];

            return Column(
              children: [
                BlocBuilder<HomeSectionBloc, HomeSectionState>(
                  builder: (context, state) {
                    return AnimatedSectionTabs(
                      sections: sections,
                      currentIndex: state.currentPageIndex,
                      onTabPressed: _onTabPressed,
                    );
                  },
                ),
                SizedBox(height: ScreenSizeService.heightPercent(context, 2)),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: videoState.video == null
                        ? const [SubirSection(), AdvancedResultSection()]
                        : const [
                            AdvancedCompressorSection(),
                            AdvancedResultSection(),
                          ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: const BannerAdWidget(),
      ),
    );
  }
}
