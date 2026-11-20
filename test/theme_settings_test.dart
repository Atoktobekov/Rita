import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:daily_todo/app.dart';
import 'package:daily_todo/domain/usecases/manage_tasks.dart';
import 'package:daily_todo/domain/usecases/manage_reminder.dart';
import 'package:daily_todo/presentation/controllers/planner_controller.dart';
import 'package:daily_todo/presentation/controllers/reminder_controller.dart';
import 'package:daily_todo/presentation/controllers/theme_controller.dart';
import 'support/fakes.dart';

void main() {
  test(
    'Theme persists after reopening Hive; failed save keeps previous mode',
    () async {
      final directory = await Directory.systemTemp.createTemp('daily_theme_');
      Hive.init(directory.path);
      var box = await Hive.openBox<dynamic>('settings_v1');
      final theme = ThemeController(
        save: (mode) => box.put('theme_mode', mode.name),
      );
      await theme.update(ThemeMode.dark);
      await box.close();
      box = await Hive.openBox<dynamic>('settings_v1');
      expect(box.get('theme_mode'), 'dark');
      final failed = ThemeController(
        mode: ThemeMode.dark,
        save: (_) async => throw StateError('disk full'),
      );
      await expectLater(failed.update(ThemeMode.light), throwsStateError);
      expect(failed.mode, ThemeMode.dark);
      expect(failed.busy, false);
      theme.dispose();
      failed.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    },
  );

  testWidgets(
    'Archive owns backups; settings switch themes and follow the system',
    (tester) async {
      final planner = PlannerController(ManageTasks(MemoryTaskRepository()));
      final reminder = ReminderController(
        ManageReminder(MemoryReminderRepository(), FakeScheduler()),
      );
      final appearance = ThemeController();
      await planner.initialize();
      await reminder.initialize();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(
        DailyApp(planner: planner, reminder: reminder, appearance: appearance),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Копии задач'), findsNothing);
      expect(find.text('Вечернее напоминание'), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('day-progress'))).height,
        lessThan(90),
      );
      await tester.tap(find.text('Архив'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Копии задач'), findsOneWidget);
      await tester.tap(find.byTooltip('Копии задач'));
      await tester.pumpAndSettle();
      expect(find.text('Импортировать JSON'), findsOneWidget);
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Статистика'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      Brightness brightness() =>
          Theme.of(tester.element(find.text('Как вам удобно'))).brightness;
      await tester.tap(find.byKey(const ValueKey('dark-switch')));
      await tester.pumpAndSettle();
      expect(brightness(), Brightness.dark);
      await tester.tap(find.byKey(const ValueKey('dark-switch')));
      await tester.pumpAndSettle();
      expect(brightness(), Brightness.light);
      await tester.tap(find.text('Дизайн приложения'));
      await tester.pumpAndSettle();
      final system = find.byKey(const ValueKey('theme-system'));
      await tester.ensureVisible(system);
      await tester.tap(system);
      await tester.pumpAndSettle();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(brightness(), Brightness.dark);
      await tester.tap(find.byTooltip('Закрыть').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reminder-switch')));
      await tester.pumpAndSettle();
      expect(reminder.settings.enabled, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      planner.dispose();
      reminder.dispose();
      appearance.dispose();
    },
  );
}
