import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/core/services/injection_container.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/core/services/ad_service.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/bloc/home_section_bloc.dart';
import 'package:robot_compresor_video/core/widgets/banner_ad_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/app_drawer.dart';
import 'package:robot_compresor_video/features/home/presentation/dialogs/app_info_dialog.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/animated_section_tabs.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/compressor_section_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/result_section_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/sections/subir_section_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
          title: const Text('Compresor de video'),
          leading: Builder(
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

            // Cargar metadata extendida (bitrate real, fps) tras seleccionar video
            if (state.status == VideoStatus.success &&
                state.video != null &&
                state.video!.bitrate == 0 &&
                state.compressionResult == null &&
                state.advancedCompressionResult == null) {
              context.read<VideoBloc>().add(const LoadExtendedMetadataRequested());
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
                _homeSectionBloc.add(const PageChanged(1));
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
              messenger.showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                  content: Text(
                    '✅ Video comprimido\n${result.compressedVideo.path}',
                  ),
                ),
              );

              await Future.delayed(const Duration(milliseconds: 3200));

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
                    onPageChanged: (index) {
                      debugPrint("PAGEVIEW -> $index");
                      _onPageChanged(index);
                    },
                    children: videoState.video == null
                        ? const [SubirSection(), ResultSection()]
                        : const [CompressorSection(), ResultSection()],
                  ),
                ),
              ],
            );
          },
        ),
        drawer: const AppDrawer(),
        bottomNavigationBar: const BannerAdWidget(),
      ),
    );
  }
}
