import 'native_sms_service.dart';
import '../widgets/transaction.dart';
import 'hive_services.dart';
import 'settings_service.dart';
import 'package:logger/logger.dart';

/// Example usage of the native SMS service
class NativeSmsExample {
  final NativeSmsService _nativeSmsService = NativeSmsService();
  final Logger _logger = Logger();

  /// Example: Get new SMS messages since last sync
  Future<List<Transaction>> getNewSmsSinceLastSync() async {
    try {
      _logger.i('Getting new SMS messages since last sync...');

      // Get last processed timestamp
      final lastTimestamp =
          await SettingsService.getLastProcessedSmsTimestamp();

      _logger.i('Last sync timestamp: $lastTimestamp');

      // Fetch SMS messages since last timestamp
      final smsMessages = await _nativeSmsService.fetchSmsMessagesSince(
        lastTimestamp!,
      );

      _logger.i('Found ${smsMessages.length} new SMS messages');

      // Parse SMS messages into transactions
      final transactions = _nativeSmsService.parseTransactionsFromMessages(
        smsMessages,
      );

      _logger.i('Parsed ${transactions.length} new transactions');

      return transactions;
    } catch (e) {
      _logger.e('Error getting new SMS since last sync: $e');
      return [];
    }
  }

  /// Example: Save transactions to Hive and update timestamp
  Future<void> saveTransactionsToHive(List<Transaction> transactions) async {
    try {
      if (transactions.isNotEmpty) {
        _logger.i('Saving ${transactions.length} transactions to Hive...');

        // Save to Hive
        await TransactionStorageService.addTransactions(transactions);

        // Update last processed timestamp
        final latestSms = transactions
            .where((t) => t.source == 'SMS')
            .map((t) => t.dateTime)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        await SettingsService.setLastProcessedSmsTimestamp(latestSms);

        _logger.i('Successfully saved transactions and updated timestamp');
      }
    } catch (e) {
      _logger.e('Error saving transactions to Hive: $e');
    }
  }
}
