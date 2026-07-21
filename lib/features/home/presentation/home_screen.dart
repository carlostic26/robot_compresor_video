import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/core/services/injection_container.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/bloc/home_section_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/sections/advanced_section_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/sections/animated_section_tabs.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/sections/compressor_section_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/sections/result_section_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/sections/subir_section_widget.dart';

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
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
          ],
        ),
        body: BlocConsumer<VideoBloc, VideoState>(
          listener: (context, state) {
            if (state.status == VideoStatus.success &&
                state.compressionResult != null) {
              final result = state.compressionResult!;
              final messenger = ScaffoldMessenger.of(context);

              messenger.clearSnackBars();

              messenger.showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                  content: Text(
                    '✅ Video comprimido y guardado en\n'
                    '${result.compressedVideo.path}',
                  ),
                ),
              );

              Future.delayed(const Duration(milliseconds: 3200), () {
                if (!context.mounted) return;

                messenger.showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                    content: Text(
                      '🎉 Se redujo un ${result.savedPercentage.toStringAsFixed(1)}%',
                    ),
                  ),
                );
              });
            }
          },
          builder: (context, videoState) {
            final sections = videoState.video == null
                ? const ['Subir', 'Avanzado', 'Resultado']
                : const ['Compresor', 'Avanzado', 'Resultado'];

            /*          final isLoading =
                videoState.status == VideoStatus.picking ||
                videoState.status == VideoStatus.compressing; */

            return Column(
              children: [
                /// TABS DE SECCIONES
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

                /// PAGEVIEW DE LAS 3 SECCIONES
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: videoState.video == null
                        ? const [
                            SubirSection(),
                            AvanzadoSection(),
                            ResultSection(),
                          ]
                        : const [
                            CompressorSection(),
                            AvanzadoSection(),
                            ResultSection(),
                          ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: SizedBox(
          height: ScreenSizeService.heightPercent(context, 8),
          child: const Placeholder(),
        ),
      ),
    );
  }
}
