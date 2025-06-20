import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'transaction.dart';
import 'package:logger/logger.dart';

class SmsService {
  Future<List<SmsMessage>> readMessages() async {
    SmsQuery query = SmsQuery();
    List<SmsMessage> smsMessages = await query.getAllSms;
    return smsMessages.where((message) {
      String body = message.body ?? '';
      return body.contains('Sent Rs') || body.contains('Credit Alert');
    }).toList();
  }
  // message parsing functions and populating transactions

  List<Transaction> parseTransactionsFromMessages(List<SmsMessage> messages) {
    final List<Transaction> transactions = [];
    final RegExp amountRegex = RegExp(
      r'^Sent[^\d]*([\d,]+(?:\.\d{1,2})?)$',
      caseSensitive: false,
      multiLine: true,
    );
    final RegExp descRegex = RegExp(r'^To\s+(.*)$', multiLine: true);
    for (final msg in messages) {
      final body = msg.body ?? '';
      if (body.contains('Sent Rs')) {
        // Debit
        final amountMatch = amountRegex.firstMatch(body);
        final descMatch = descRegex.firstMatch(body);
        if (messages.indexOf(msg) < 5) {
          Logger().i('SMS body: $body');
          Logger().i(
            'amountMatch: ${amountMatch != null ? amountMatch.group(1) : 'null'}',
          );
          Logger().i(
            'descMatch: ${descMatch != null ? descMatch.group(1) : 'null'}',
          );
        }
        final amount = amountMatch != null
            ? double.tryParse(amountMatch.group(1)!.replaceAll(',', '')) ?? 0.0
            : 0.0;
        final desc = descMatch != null ? descMatch.group(1)!.trim() : 'Unknown';
        transactions.add(
          Transaction(
            type: 'Debit',
            amount: amount,
            description: desc,
            category: '',
            source: 'SMS',
            dateTime: msg.date ?? DateTime.now(),
            excluded: false,
          ),
        );
      }
      // TODO: You can add more parsing for 'Credit Alert' if needed
    }
    return transactions;
  }
}
