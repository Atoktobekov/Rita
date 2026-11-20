// Opt-in visual review: flutter test test/preview_test.dart --dart-define=VISUAL_REVIEW=true
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_todo/app.dart';
import 'package:daily_todo/domain/usecases/manage_tasks.dart';
import 'package:daily_todo/domain/usecases/manage_reminder.dart';
import 'package:daily_todo/presentation/controllers/planner_controller.dart';
import 'package:daily_todo/presentation/controllers/reminder_controller.dart';
import 'package:daily_todo/presentation/controllers/theme_controller.dart';
import 'package:daily_todo/presentation/theme/palette.dart';
import 'package:daily_todo/presentation/widgets/task_card.dart';
import 'support/fakes.dart';
import 'support/figma_fixture.dart';

void main() {
  testWidgets(
    'Render four designs, both brightness modes and inherited sheets with bundled fonts',
    (tester) async {
      await tester.runAsync(() async {
        for (final (family, path) in [
          ('Golos Text', 'assets/fonts/GolosText.ttf'),
          ('DM Sans', 'assets/fonts/DMSans.ttf'),
          ('Literata', 'assets/fonts/Literata.ttf'),
          ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
        ]) {
          await (FontLoader(family)..addFont(rootBundle.load(path))).load();
        }
      });
      final repository = MemoryTaskRepository()..tasks.addAll(figmaFixture());
      final planner = PlannerController(
        ManageTasks(repository),
        clock: () => DateTime(2026, 6, 18),
      );
      final reminder = ReminderController(
        ManageReminder(MemoryReminderRepository(), FakeScheduler()),
      );
      final appearance = ThemeController();
      await planner.initialize();
      await reminder.initialize();
      final key = GlobalKey();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(top: 28);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DailyApp(
            planner: planner,
            reminder: reminder,
            appearance: appearance,
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> capture(String name) async {
        expect(tester.takeException(), isNull, reason: name);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/qa').create(recursive: true);
          await File(
            'build/qa/$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      for (final design in AppDesign.values) {
        await appearance.updateDesign(design);
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          await appearance.update(mode);
          await tester.pumpAndSettle();
          for (final (index, name) in [
            'day',
            'archive',
            'statistics',
            'awards',
          ].indexed) {
            if (index > 0) {
              await tester.tap(find.byKey(ValueKey('nav-section-$index')));
              await tester.pumpAndSettle();
            }
            await capture('theme-${design.name}-${mode.name}-$name');
          }
          await tester.tap(find.byKey(const ValueKey('nav-section-0')));
          await tester.pumpAndSettle();
          await tester.longPress(find.byType(TaskCard).first);
          await tester.pumpAndSettle();
          await capture('theme-${design.name}-${mode.name}-menu');
          Navigator.of(
            tester.element(find.byKey(const ValueKey('task-edit'))),
          ).pop();
          await tester.pumpAndSettle();
        }
      }
      await tester.tap(find.byKey(const ValueKey('nav-section-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Дизайн приложения'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('design-editorial')),
        150,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last,
      );
      await capture('theme-selector-dark');
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
      planner.dispose();
      reminder.dispose();
    },
    skip: !const bool.fromEnvironment('VISUAL_REVIEW'),
  );
}
