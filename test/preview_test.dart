// Opt-in visual review: flutter test test/preview_test.dart --dart-define=VISUAL_REVIEW=true
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_todo/app.dart';
import 'package:daily_todo/domain/entities/reminder_settings.dart';
import 'package:daily_todo/domain/usecases/manage_tasks.dart';
import 'package:daily_todo/domain/usecases/manage_reminder.dart';
import 'package:daily_todo/presentation/controllers/planner_controller.dart';
import 'package:daily_todo/presentation/controllers/reminder_controller.dart';
import 'support/fakes.dart';
import 'support/figma_fixture.dart';

void main() {
  testWidgets(
    'Render all Figma screens and narrow layouts with the original font',
    (tester) async {
      await tester.runAsync(() async {
        await (FontLoader(
          'Google Sans',
        )..addFont(rootBundle.load('assets/fonts/GoogleSans.ttf'))).load();
      });
      await tester.runAsync(() async {
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      final repository = MemoryTaskRepository()..tasks.addAll(figmaFixture());
      final settings = MemoryReminderRepository()
        ..settings = const ReminderSettings(enabled: true);
      final planner = PlannerController(
        ManageTasks(repository),
        clock: () => DateTime(2025, 1, 15),
      );
      final reminder = ReminderController(
        ManageReminder(settings, FakeScheduler()),
      );
      await planner.initialize();
      await reminder.initialize();
      final key = GlobalKey();
      tester.view.physicalSize = const Size(370, 780);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(top: 28);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DailyApp(planner: planner, reminder: reminder),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        expect(tester.takeException(), isNull);
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

      await capture('figma-day');
      await tester.tap(find.byKey(const ValueKey('day-selector')));
      await tester.pumpAndSettle();
      await capture('day-picker');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Архив'));
      await tester.pumpAndSettle();
      await capture('figma-archive');
      await tester.tap(find.text('Статистика'));
      await tester.pumpAndSettle();
      await capture('figma-statistics');
      await tester.tap(find.byTooltip('Настройки статистики'));
      await tester.pumpAndSettle();
      await capture('figma-statistics-settings');
      await tester.tap(find.text('Проценты'));
      await tester.pumpAndSettle();
      await capture('figma-statistics-percent');
      await tester.tap(find.text('Ачивки'));
      await tester.pumpAndSettle();
      await capture('figma-awards');
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();
      await capture('figma-awards-more');
      tester.view.physicalSize = const Size(320, 780);
      await tester.pumpAndSettle();
      await capture('figma-awards-narrow');
      await tester.tap(find.text('Статистика'));
      await tester.pumpAndSettle();
      await capture('figma-statistics-narrow');
      await tester.tap(find.text('Сегодня'));
      await tester.pumpAndSettle();
      await capture('figma-day-narrow');
      await tester.pumpWidget(const SizedBox());
      planner.dispose();
      reminder.dispose();
    },
    skip: !const bool.fromEnvironment('VISUAL_REVIEW'),
  );
}
