import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_section_event.dart';
part 'home_section_state.dart';

class HomeSectionBloc extends Bloc<HomeSectionEvent, HomeSectionState> {
  HomeSectionBloc() : super(const HomeSectionState()) {
    // Escucha el evento PageChanged
    on<PageChanged>(_onPageChanged);

    // Escucha el evento InitPage
    on<InitPage>(_onInitPage);
  }

  /// Maneja el cambio de página
  /// Cuando el usuario desliza o toca un tab, esta función se ejecuta
  Future<void> _onPageChanged(
    PageChanged event,
    Emitter<HomeSectionState> emit,
  ) async {
    emit(state.copyWith(currentPageIndex: event.pageIndex));
  }

  /// Inicializa la página a 0
  Future<void> _onInitPage(
    InitPage event,
    Emitter<HomeSectionState> emit,
  ) async {
    emit(const HomeSectionState(currentPageIndex: 0));
  }
}
