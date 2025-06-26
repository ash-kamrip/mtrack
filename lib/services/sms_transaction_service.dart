import '../widgets/sms_service.dart';
import '../widgets/transaction.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'settings_service.dart';

class SmsTransactionService {
  final SmsService _smsService = SmsService();

  Future<List<Transaction>> getAllTransactionsFromSms() async {
    final List<SmsMessage> messages = await _smsService.readMessages();
    final transactions = _smsService.parseTransactionsFromMessages(messages);
    // Update last processed SMS ID if any messages exist
    if (messages.isNotEmpty) {
      final maxId = messages
          .map((m) => m.id ?? 0)
          .reduce((a, b) => a > b ? a : b);
      await SettingsService.setLastProcessedSmsId(maxId);
    }
    return transactions;
  }

  Future<List<Transaction>> getTransactionsFromSmsSince(DateTime since) async {
    final lastProcessedId = await SettingsService.getLastProcessedSmsId();
    final List<SmsMessage> messages = await _smsService.readMessages();
    final filtered = messages.where((msg) {
      final afterDate = msg.date != null && msg.date!.isAfter(since);
      final afterId =
          lastProcessedId == null ||
          (msg.id != null && msg.id! > lastProcessedId);
      return afterDate && afterId;
    }).toList();
    // Update last processed SMS ID if any new messages exist
    if (messages.isNotEmpty) {
      final maxId = messages
          .map((m) => m.id ?? 0)
          .reduce((a, b) => a > b ? a : b);
      await SettingsService.setLastProcessedSmsId(maxId);
    }
    return _smsService.parseTransactionsFromMessages(filtered);
  }
}
