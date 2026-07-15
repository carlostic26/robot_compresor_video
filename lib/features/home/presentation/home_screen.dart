import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';
import 'package:robot_compresor_video/features/home/presentation/bloc/home_section_bloc.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/animated_section_tabs.dart';
import 'package:robot_compresor_video/features/home/presentation/widgets/section_pages.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  late HomeSectionBloc _homeSectionBloc;

  /// Lista de secciones en el mismo orden que las páginas
  static const List<String> _sections = [
    'Subir',
    'Compresor',
    'Avanzado',
    'Resultado',
  ];

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

  /// Maneja el cambio de página desde el PageView
  void _onPageChanged(int index) {
    _homeSectionBloc.add(PageChanged(index));
  }

  /// Maneja cuando se presiona un tab
  void _onTabPressed(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeSectionBloc>(
      create: (context) => _homeSectionBloc..add(const InitPage()),
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
        body: Column(
          children: [
            /// TABS DE SECCIONES
            BlocBuilder<HomeSectionBloc, HomeSectionState>(
              builder: (context, state) {
                return AnimatedSectionTabs(
                  sections: _sections,
                  currentIndex: state.currentPageIndex,
                  onTabPressed: _onTabPressed,
                );
              },
            ),

            SizedBox(height: ScreenSizeService.heightPercent(context, 2)),

            /// PAGEVIEW CON LAS 4 SECCIONES
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: const [
                  SubirSection(),
                  CompressorSection(),
                  AvanzadoSection(),
                  ResultadoSection(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SizedBox(
          height: ScreenSizeService.heightPercent(context, 8),
          child: const Placeholder(),
        ),
      ),
    );
  }
}
