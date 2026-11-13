import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode mode = ThemeMode.system, this.save})
    : _mode = mode;
  final Future<void> Function(ThemeMode)? save;
  ThemeMode _mode;

  ThemeMode get mode => _mode;
  bool busy = false;

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
