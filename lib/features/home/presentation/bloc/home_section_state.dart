part of 'home_section_bloc.dart';

class HomeSectionState extends Equatable {
  /// Índice de la página actual (0 = subir, 1 = compresor, 2 = avanzado, 3 = resultado)
  final int currentPageIndex;

  const HomeSectionState({this.currentPageIndex = 0});

  /// Copia el estado con nuevos valores
  HomeSectionState copyWith({int? currentPageIndex}) {
    return HomeSectionState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
    );
  }

  @override
  List<Object> get props => [currentPageIndex];
}
