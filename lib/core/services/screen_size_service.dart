import 'package:flutter/material.dart';

class ScreenSizeService {
  ScreenSizeService._();

  static double widthPercent(BuildContext context, double percent) {
    assert(
      percent > 0 && percent <= 100,
      'El porcentaje debe estar entre 0 y 100',
    );
    return MediaQuery.of(context).size.width * (percent / 100);
  }

  static double heightPercent(BuildContext context, double percent) {
    assert(
      percent > 0 && percent <= 100,
      'El porcentaje debe estar entre 0 y 100',
    );
    return MediaQuery.of(context).size.height * (percent / 100);
  }

  static double shortestSidePercent(BuildContext context, double percent) {
    assert(
      percent > 0 && percent <= 100,
      'El porcentaje debe estar entre 0 y 100',
    );
    return MediaQuery.of(context).size.shortestSide * (percent / 100);
  }
}
