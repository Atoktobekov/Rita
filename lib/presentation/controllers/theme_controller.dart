import 'package:flutter/material.dart';
import '../theme/palette.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({
    ThemeMode mode = ThemeMode.system,
    AppDesign design = AppDesign.warm,
    this.save,
    this.saveDesign,
  }) : _mode = mode,
       _design = design;
  final Future<void> Function(ThemeMode)? save;
  ThemeMode _mode;
  AppDesign _design;
  final Future<void> Function(AppDesign)? saveDesign;
  AppDesign get design => _design;

  ThemeMode get mode => _mode;
  bool busy = false;

  Future<void> updateDesign(AppDesign next) async {
    if (busy || next == _design) return;
    busy = true;
    notifyListeners();
    try {
      await saveDesign?.call(next);
      _design = next;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> update(ThemeMode next) async {
    if (busy || next == _mode) return;
    busy = true;
    notifyListeners();
    try {
      await save?.call(next);
      _mode = next;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
