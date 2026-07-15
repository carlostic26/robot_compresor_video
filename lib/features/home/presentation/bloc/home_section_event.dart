part of 'home_section_bloc.dart';

abstract class HomeSectionEvent extends Equatable {
  const HomeSectionEvent();

  @override
  List<Object> get props => [];
}

/// Evento que se dispara cuando el usuario cambia de página
class PageChanged extends HomeSectionEvent {
  final int pageIndex;

  const PageChanged(this.pageIndex);

  @override
  List<Object> get props => [pageIndex];
}

/// Evento para inicializar el bloc a la primera página
class InitPage extends HomeSectionEvent {
  const InitPage();
}
