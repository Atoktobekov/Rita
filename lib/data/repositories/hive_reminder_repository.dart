import 'package:hive_ce/hive.dart';
import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/reminder_repository.dart';

class HiveReminderRepository implements ReminderRepository {
  const HiveReminderRepository(this.box);
  final Box<dynamic> box;

  @override
  Future<ReminderSettings> load() async {
    final value = box.get('evening_reminder');
    if (value is! Map) return const ReminderSettings();
    final hour = value['hour'];
    final minute = value['minute'];
    return ReminderSettings(
      enabled: value['enabled'] == true,
      hour: hour is int && hour >= 0 && hour <= 23 ? hour : 21,
      minute: minute is int && minute >= 0 && minute <= 59 ? minute : 30,
    );
  }

  @override
  Future<void> save(ReminderSettings settings) => box.put('evening_reminder', {
    'enabled': settings.enabled,
    'hour': settings.hour,
    'minute': settings.minute,
  });
}
