import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'presentation/controllers/planner_controller.dart';
import 'presentation/controllers/reminder_controller.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/theme/palette.dart';
import 'presentation/controllers/theme_controller.dart';

class DailyApp extends StatefulWidget {
  const DailyApp({
    super.key,
    required this.planner,
    required this.reminder,
    this.appearance,
  });

  final PlannerController planner;
  final ReminderController reminder;

  final ThemeController? appearance;

  @override
  State<DailyApp> createState() => _DailyAppState();
}

class _DailyAppState extends State<DailyApp> {
  late final appearance = widget.appearance ?? ThemeController();

  @override
  void dispose() {
    if (widget.appearance == null) appearance.dispose();
    super.dispose();
  }

  ThemeData makeTheme(Brightness brightness) {
    final colors = AppPalette(
      brightness == Brightness.dark,
      design: appearance.design,
    );
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: 'Golos Text',
      extensions: [colors],
      scaffoldBackgroundColor: colors.paper,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: colors.strong,
            brightness: brightness,
          ).copyWith(
            primary: colors.ink,
            onPrimary: colors.paper,
            primaryContainer: colors.cream,
            onPrimaryContainer: colors.ink,
            surface: colors.card,
            onSurface: colors.ink,
            onSurfaceVariant: colors.muted,
            outline: colors.line,
            outlineVariant: colors.line,
            secondary: colors.strong,
            secondaryContainer: colors.sage,
            onSecondaryContainer: colors.ink,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.paper,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: colors.heading.copyWith(fontSize: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(colors.radius),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.line),
      listTileTheme: ListTileThemeData(
        selectedColor: colors.ink,
        selectedTileColor: colors.sage,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(colors.radius),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: colors.heading,
        headlineMedium: colors.heading.copyWith(fontSize: 28),
        titleLarge: colors.heading.copyWith(fontSize: 22),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: colors.ink),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: colors.ink),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: appearance,
    builder: (context, _) => MaterialApp(
      title: 'Daily To-Do',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: makeTheme(Brightness.light),
      darkTheme: makeTheme(Brightness.dark),
      themeMode: appearance.mode,
      builder: (context, child) {
        final theme = Theme.of(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: theme.brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: SafeArea(top: false, child: child!),
          ),
        );
      },
      home: HomePage(
        planner: widget.planner,
        reminder: widget.reminder,
        appearance: appearance,
      ),
    ),
  );
}
