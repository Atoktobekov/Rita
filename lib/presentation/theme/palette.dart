import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette(this.dark);

  final bool dark;

  static AppPalette of(BuildContext context) =>
      AppPalette(Theme.of(context).brightness == Brightness.dark);

  Color get ink => dark ? const Color(0xFFF1E8DC) : const Color(0xFF2B2116);

  Color get paper => dark ? const Color(0xFF151413) : Colors.white;

  Color get card => dark ? const Color(0xFF23211F) : Colors.white;

  Color get cream => dark ? const Color(0xFF403329) : const Color(0xFFFAEEDD);

  Color get sage => dark ? const Color(0xFF51412B) : const Color(0xFFFFEDC2);

  Color get sand => dark ? const Color(0xFF302A23) : const Color(0xFFFFF3D6);

  Color inkOpacity(double opacity) => ink.withValues(alpha: opacity);
}
