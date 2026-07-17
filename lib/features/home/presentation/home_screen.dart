import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/core/services/injection_container.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/compress_video/presentation/bloc/video_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/bloc/home_section_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/advanced_section_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/animated_section_tabs.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/compressor_section_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/result_section_widget.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/subir_section_widget.dart';

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

        BlocProvider<VideoBloc>(create: (_) => sl<VideoBloc>()),
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
        body: BlocBuilder<VideoBloc, VideoState>(
          builder: (context, videoState) {
            final sections = videoState.video == null
                ? const ['Subir', 'Avanzado', 'Resultado']
                : const ['Compresor', 'Avanzado', 'Resultado'];

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

                /// PAGEVIEW 3 SECCIONES DINAMICAS
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: videoState.video == null
                        ? const [
                            SubirSection(),
                            AvanzadoSection(),
                            ResultadoSection(),
                          ]
                        : const [
                            CompressorSection(),
                            AvanzadoSection(),
                            ResultadoSection(),
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
