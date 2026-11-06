import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'presentation/controllers/planner_controller.dart';
import 'presentation/controllers/reminder_controller.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/theme/palette.dart';

class DailyApp extends StatelessWidget {
  const DailyApp({super.key, required this.planner, required this.reminder});
  final PlannerController planner;
  final ReminderController reminder;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Daily To-Do',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Google Sans',
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: peach).copyWith(
        primary: ink,
        onPrimary: Colors.white,
        primaryContainer: peach,
        onPrimaryContainer: ink,
        surface: Colors.white,
        onSurface: ink,
        secondaryContainer: peach,
        onSecondaryContainer: ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        centerTitle: false,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: peach,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: peach,
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: peach,
        foregroundColor: ink,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        selectedColor: peach,
        side: const BorderSide(color: Color(0xFFE7E1D9)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: const Color(0xFFE7E1D9),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: ink),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: ink),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    ),
    home: HomePage(planner: planner, reminder: reminder),
  );
}
