import 'package:flutter/material.dart';

/// Widget que renderiza los tabs animados con indicador de subrayado
/// El subrayado se anima suavemente cuando cambias de página
class AnimatedSectionTabs extends StatelessWidget {
  /// Lista de nombres de las secciones
  final List<String> sections;

  /// Índice de la sección activa
  final int currentIndex;

  /// Callback cuando se presiona un tab
  final Function(int) onTabPressed;

  const AnimatedSectionTabs({
    super.key,
    required this.sections,
    required this.currentIndex,
    required this.onTabPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tabWidth = MediaQuery.of(context).size.width / sections.length;

    return Column(
      children: [
        // Fila de tabs
        Container(
          color: Colors.transparent,
          child: Row(
            children: List.generate(
              sections.length,
              (index) => Expanded(
                child: GestureDetector(
                  onTap: () => onTabPressed(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      sections[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: currentIndex == index
                            ? Colors.blue
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Indicador animado de subrayado
        Stack(
          children: [
            // Fondo gris claro
            Container(height: 2, color: Colors.grey[300]),
            // Indicador azul animado
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: currentIndex * tabWidth,
              child: Container(width: tabWidth, height: 2, color: Colors.blue),
            ),
          ],
        ),
      ],
    );
  }
}
