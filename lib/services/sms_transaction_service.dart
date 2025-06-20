import '../widgets/sms_service.dart';
import '../widgets/transaction.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';

class SmsTransactionService {
  final SmsService _smsService = SmsService();

  Future<List<Transaction>> getAllTransactionsFromSms() async {
    final List<SmsMessage> messages = await _smsService.readMessages();
    return _smsService.parseTransactionsFromMessages(messages);
  }

  Future<List<Transaction>> getTransactionsFromSmsSince(DateTime since) async {
    final List<SmsMessage> messages = await _smsService.readMessages();
    final filtered = messages
        .where((msg) => msg.date != null && msg.date!.isAfter(since))
        .toList();
    return _smsService.parseTransactionsFromMessages(filtered);
  }
}
