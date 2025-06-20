import 'package:hive/hive.dart';

class SettingsService {
  static const String _boxName = 'settings';
  static const String _lastProcessedSmsTimestampKey =
      'lastProcessedSmsTimestamp';

  static Future<Box> openBox() async {
    return await Hive.openBox(_boxName);
  }

  static Future<DateTime?> getLastProcessedSmsTimestamp() async {
    final box = await openBox();
    final millis = box.get(_lastProcessedSmsTimestampKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static Future<void> setLastProcessedSmsTimestamp(DateTime timestamp) async {
    final box = await openBox();
    await box.put(
      _lastProcessedSmsTimestampKey,
      timestamp.millisecondsSinceEpoch,
    );
  }
}
