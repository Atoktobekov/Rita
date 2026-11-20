import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:daily_todo/app.dart';
import 'package:daily_todo/domain/entities/task.dart';
import 'package:daily_todo/domain/usecases/manage_tasks.dart';
import 'package:daily_todo/domain/usecases/manage_reminder.dart';
import 'package:daily_todo/presentation/controllers/planner_controller.dart';
import 'package:daily_todo/presentation/controllers/reminder_controller.dart';
import 'package:daily_todo/presentation/controllers/theme_controller.dart';
import 'package:daily_todo/presentation/theme/palette.dart';
import 'support/fakes.dart';

void main() {
  test(
    'Warm design is the default and unknown stored values safely fall back',
    () {
      final controller = ThemeController();
      expect(controller.design, AppDesign.warm);
      expect(controller.mode, ThemeMode.system);
      expect(AppDesign.fromStorage(null), AppDesign.warm);
      expect(AppDesign.fromStorage('unknown'), AppDesign.warm);
      expect(AppDesign.fromStorage(42), AppDesign.warm);
      for (final design in AppDesign.values) {
        expect(AppDesign.fromStorage(design.name), design);
      }
      controller.dispose();
    },
  );

  test(
    'Design survives real Hive reopen without overwriting the saved brightness',
    () async {
      final directory = await Directory.systemTemp.createTemp('daily_design_');
      Hive.init(directory.path);
      var box = await Hive.openBox<dynamic>('settings_v1');
      await box.put(
        'theme_mode',
        'dark',
      ); // Existing installations have no design key.
      final appearance = ThemeController(
        mode: ThemeMode.dark,
        design: AppDesign.fromStorage(box.get('design_theme')),
        saveDesign: (design) => box.put('design_theme', design.name),
      );
      expect(appearance.design, AppDesign.warm);
      for (final design in AppDesign.values) {
        await appearance.updateDesign(design);
        expect(appearance.mode, ThemeMode.dark);
      }
      await box.close();
      box = await Hive.openBox<dynamic>('settings_v1');
      expect(box.get('theme_mode'), 'dark');
      final reopened = ThemeController(
        mode: ThemeMode.dark,
        design: AppDesign.fromStorage(box.get('design_theme')),
        save: (mode) => box.put('theme_mode', mode.name),
      );
      expect(reopened.design, AppDesign.editorial);
      await reopened.update(ThemeMode.light);
      expect(box.get('design_theme'), 'editorial');
      appearance.dispose();
      reopened.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    },
  );

  test(
    'Failed design save keeps the previous appearance and serializes other settings',
    () async {
      final pending = Completer<void>();
      final appearance = ThemeController(saveDesign: (_) => pending.future);
      final change = appearance.updateDesign(AppDesign.play);
      expect(appearance.busy, true);
      expect(appearance.design, AppDesign.warm);
      await appearance.update(ThemeMode.dark);
      expect(appearance.mode, ThemeMode.system);
      final failure = expectLater(change, throwsStateError);
      pending.completeError(StateError('disk full'));
      await failure;
      expect(appearance.design, AppDesign.warm);
      expect(appearance.busy, false);
      appearance.dispose();
    },
  );

  test(
    'All eight palettes have readable text and distinct dark backgrounds',
    () {
      double contrast(Color a, Color b) {
        final first = a.computeLuminance(), second = b.computeLuminance();
        return (first > second ? first + .05 : second + .05) /
            (first > second ? second + .05 : first + .05);
      }

      final darkBackgrounds = <Color>{};
      for (final design in AppDesign.values) {
        for (final dark in [false, true]) {
          final palette = AppPalette(dark, design: design);
          expect(
            contrast(palette.ink, palette.paper),
            greaterThanOrEqualTo(4.5),
            reason: '$design/$dark main text',
          );
          expect(
            contrast(palette.muted, palette.card),
            greaterThanOrEqualTo(4.5),
            reason: '$design/$dark secondary text',
          );
          expect(
            contrast(palette.onAction, palette.action),
            greaterThanOrEqualTo(4.5),
            reason: '$design/$dark actions',
          );
          expect(
            contrast(palette.onHero, palette.hero),
            greaterThanOrEqualTo(4.5),
            reason: '$design/$dark progress',
          );
          if (dark) darkBackgrounds.add(palette.paper);
        }
      }
      expect(darkBackgrounds, hasLength(4));
    },
  );

  testWidgets(
    'Every design and mode fits all tabs at 320 px with 200% text; sheets inherit it',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final planner = PlannerController(
        ManageTasks(MemoryTaskRepository()),
        clock: () => DateTime(2027, 1, 2),
      );
      final reminder = ReminderController(
        ManageReminder(MemoryReminderRepository(), FakeScheduler()),
      );
      final appearance = ThemeController();
      await planner.initialize();
      await reminder.initialize();
      await planner.save(
        const Task(
          id: 'today',
          title: 'Прочитать двадцать страниц любимой книги',
          day: '2027-01-02',
        ),
      );
      await planner.save(
        const Task(
          id: 'past',
          title: 'Прогуляться',
          day: '2027-01-01',
          done: true,
        ),
      );
      await tester.pumpWidget(
        DailyApp(planner: planner, reminder: reminder, appearance: appearance),
      );
      await tester.pumpAndSettle();
      for (final design in AppDesign.values) {
        await appearance.updateDesign(design);
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          await appearance.update(mode);
          await tester.pumpAndSettle();
          for (var index = 0; index < 4; index++) {
            await tester.tap(find.byKey(ValueKey('nav-section-$index')));
            await tester.pumpAndSettle();
            final context = tester.element(
              find.byKey(ValueKey('nav-section-$index')),
            );
            expect(AppPalette.of(context).design, design);
            expect(AppPalette.of(context).dark, mode == ThemeMode.dark);
            expect(
              tester.takeException(),
              isNull,
              reason: '$design/$mode/tab$index',
            );
          }
          await tester.tap(find.byKey(const ValueKey('nav-section-0')));
          await tester.pumpAndSettle();
          final target = find.byKey(const ValueKey('task-card-today'));
          await tester.scrollUntilVisible(
            target,
            120,
            scrollable: find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .first,
          );
          await Scrollable.ensureVisible(tester.element(target), alignment: .5);
          await tester.pumpAndSettle();
          await tester.longPress(target);
          await tester.pumpAndSettle();
          final menu = find.byKey(const ValueKey('task-edit'));
          expect(AppPalette.of(tester.element(menu)).design, design);
          Navigator.of(tester.element(menu)).pop();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
      expect(planner.tasks, hasLength(2));
      expect(planner.tasks.first.done, false);
      await tester.pumpWidget(const SizedBox());
      planner.dispose();
      reminder.dispose();
      appearance.dispose();
    },
  );

  testWidgets(
    'Design selection from statistics is live and failure is visible',
    (tester) async {
      final planner = PlannerController(ManageTasks(MemoryTaskRepository()));
      final reminder = ReminderController(
        ManageReminder(MemoryReminderRepository(), FakeScheduler()),
      );
      var fail = false;
      final appearance = ThemeController(
        saveDesign: (_) async {
          if (fail) throw StateError('disk full');
        },
      );
      await planner.initialize();
      await reminder.initialize();
      await tester.pumpWidget(
        DailyApp(planner: planner, reminder: reminder, appearance: appearance),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-section-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      Future<void> select(AppDesign design) async {
        final tile = find.byKey(ValueKey('design-${design.name}'));
        await tester.scrollUntilVisible(
          tile,
          120,
          scrollable: find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .last,
        );
        await tester.tap(tile);
        await tester.pumpAndSettle();
      }

      await select(AppDesign.strict);
      expect(appearance.design, AppDesign.strict);
      expect(
        AppPalette.of(
          tester.element(find.byKey(const ValueKey('design-strict'))),
        ).design,
        AppDesign.strict,
      );
      fail = true;
      await select(AppDesign.play);
      expect(appearance.design, AppDesign.strict);
      expect(
        find.text('Не удалось сохранить дизайн. Попробуйте ещё раз.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      planner.dispose();
      reminder.dispose();
      appearance.dispose();
    },
  );
}
