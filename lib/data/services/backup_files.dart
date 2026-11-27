import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/task.dart';
import 'task_backup.dart';

class BackupFiles {
  Future<TaskBackup?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Открыть копию задач',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
      withReadStream: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    if (file.size > TaskBackup.maxBytes) {
      throw const FormatException('Файл больше 10 МБ');
    }
    final stream = file.readStream;
    if (stream == null) {
      throw const FormatException('Не удалось прочитать файл');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (bytes.length + chunk.length > TaskBackup.maxBytes) {
        throw const FormatException('Файл больше 10 МБ');
      }
      bytes.add(chunk);
    }
    return TaskBackup.decode(bytes.takeBytes());
  }

  Future<bool> save(List<Task> tasks) async {
    final now = DateTime.now();
    final bytes = Uint8List.fromList(TaskBackup.encode(tasks, now));
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить копию задач',
      fileName: 'Rita-${now.toIso8601String().replaceAll(':', '-')}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
    if (kIsWeb) return true;
    if (path == null) return false;
    // Android, iOS and web write bytes in the picker. Desktop returns a path.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      await XFile.fromData(bytes, mimeType: 'application/json').saveTo(path);
    }
    return true;
  }
}
