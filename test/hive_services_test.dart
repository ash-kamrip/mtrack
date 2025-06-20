import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mtrack/widgets/transaction.dart';
import 'package:mtrack/services/transaction_storage_service.dart';
import 'package:mtrack/services/settings_service.dart';

void main() {
  // Ensure Flutter bindings are initialized for plugin compatibility (not strictly needed here, but safe for all test types)
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up Hive with a manual directory before all tests
  setUpAll(() async {
    // Use a test-specific directory inside .dart_tool to avoid polluting real app data
    final testDir = Directory(
      path.join(Directory.current.path, '.dart_tool', 'test_hive'),
    );
    if (!testDir.existsSync()) {
      testDir.createSync(recursive: true);
    }
    // Initialize Hive and register the Transaction adapter
    Hive.init(testDir.path);
    Hive.registerAdapter(TransactionAdapter());
    // Open the boxes needed for the tests
    await Hive.openBox<Transaction>('transactions');
    await Hive.openBox('settings');
  });

  // Clean up Hive after all tests
  tearDownAll(() async {
    await Hive.box<Transaction>('transactions').clear();
    await Hive.box('settings').clear();
    await Hive.close();
  });

  // Test adding, retrieving, and checking if the transactions box is empty
  test('TransactionStorageService add/get/isEmpty', () async {
    // The box should be empty at the start
    expect(await TransactionStorageService.isEmpty(), true);
    // Create a sample transaction
    final tx = Transaction(
      type: 'Debit',
      amount: 100.0,
      description: 'Test',
      category: 'Food',
      source: 'Manual',
      dateTime: DateTime.now(),
      excluded: false,
    );
    // Add the transaction to Hive
    await TransactionStorageService.addTransaction(tx);
    // The box should no longer be empty
    expect(await TransactionStorageService.isEmpty(), false);
    // Retrieve all transactions and check the contents
    final all = await TransactionStorageService.getAllTransactions();
    expect(all.length, 1);
    expect(all.first.description, 'Test');
  });

  // Test storing and retrieving the last processed SMS timestamp in settings
  test('SettingsService set/get last processed SMS timestamp', () async {
    // Store the current time as the last processed timestamp
    final now = DateTime.now();
    await SettingsService.setLastProcessedSmsTimestamp(now);
    // Retrieve the stored timestamp
    final stored = await SettingsService.getLastProcessedSmsTimestamp();
    // It should not be null and should match what was stored
    expect(stored, isNotNull);
    expect(stored!.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
  });
}
