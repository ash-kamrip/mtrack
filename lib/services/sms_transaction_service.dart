import 'native_sms_service.dart';
import '../widgets/transaction.dart';
import 'settings_service.dart';
import 'package:logger/logger.dart';

class SmsTransactionService {
  final NativeSmsService _nativeSmsService = NativeSmsService();
  final Logger _logger = Logger();

  /// Get top 10 transactions from SMS for quick display
  Future<List<Transaction>> getTop10Tx() async {
    //TODO: these 10 txs are not from sms, they are from the db
    return [];
  }

  /// Get all transactions from SMS
  Future<List<Transaction>> getAllTransactionsFromSms() async {
    try {
      _logger.i('Getting all transaction SMS messages...');

      // Get total count first
      final totalCount = await _nativeSmsService.getSmsCount();
      _logger.i('Total SMS count: $totalCount');

      // Fetch all SMS messages (no pagination in native code)
      final smsMessages = await _nativeSmsService.fetchSmsMessages();
      _logger.i('Fetched ${smsMessages.length} SMS messages from native code');

      // Parse and filter for transaction messages
      final transactions = _nativeSmsService.parseTransactionsFromMessages(
        smsMessages,
      );

      _logger.i('Total transactions found: ${transactions.length}');

      // Update last processed SMS timestamp if any messages exist
      if (transactions.isNotEmpty) {
        final latestSms = transactions
            .where((t) => t.source == 'SMS')
            .map((t) => t.dateTime)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        await SettingsService.setLastProcessedSmsTimestamp(latestSms);
        _logger.i('Updated last processed timestamp to: $latestSms');
      }

      return transactions;
    } catch (e) {
      _logger.e('Error getting all transactions from SMS: $e');
      return [];
    }
  }

  /// Get transactions from SMS since a specific timestamp
  Future<List<Transaction>> getTransactionsFromSmsSince(DateTime since) async {
    try {
      _logger.i('Getting SMS transactions since $since...');

      // Fetch SMS messages since the given timestamp
      final smsMessages = await _nativeSmsService.fetchSmsMessagesSince(since);

      _logger.i('Found ${smsMessages.length} SMS messages since $since');

      // Parse SMS messages into transactions
      final transactions = _nativeSmsService.parseTransactionsFromMessages(
        smsMessages,
      );

      _logger.i(
        'Parsed ${transactions.length} transactions from SMS since $since',
      );

      // Update last processed SMS timestamp if any messages exist
      if (transactions.isNotEmpty) {
        final latestSms = transactions
            .where((t) => t.source == 'SMS')
            .map((t) => t.dateTime)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        await SettingsService.setLastProcessedSmsTimestamp(latestSms);
        _logger.i('Updated last processed timestamp to: $latestSms');
      }

      return transactions;
    } catch (e) {
      _logger.e('Error getting transactions from SMS since timestamp: $e');
      return [];
    }
  }
}
