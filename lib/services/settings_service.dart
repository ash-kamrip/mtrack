import 'package:hive/hive.dart';

/// Service for managing app settings using Hive local storage.
/// Currently used for storing and retrieving the last processed SMS timestamp.
class SettingsService {
  // Name of the Hive box for settings
  static const String _boxName = 'settings';
  // Key for storing the last processed SMS timestamp
  static const String _lastProcessedSmsTimestampKey =
      'lastProcessedSmsTimestamp';

  /// Opens (or creates) the Hive box for settings.
  static Future<Box> openBox() async {
    return await Hive.openBox(_boxName);
  }

  /// Retrieves the last processed SMS timestamp from settings.
  /// Returns null if not set.
  static Future<DateTime?> getLastProcessedSmsTimestamp() async {
    final box = await openBox();
    final millis = box.get(_lastProcessedSmsTimestampKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Stores the last processed SMS timestamp in settings.
  static Future<void> setLastProcessedSmsTimestamp(DateTime timestamp) async {
    final box = await openBox();
    await box.put(
      _lastProcessedSmsTimestampKey,
      timestamp.millisecondsSinceEpoch,
    );
  }
}
