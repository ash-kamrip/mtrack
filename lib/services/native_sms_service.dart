import 'dart:convert';
import 'package:flutter/services.dart';
import '../widgets/transaction.dart';
import 'package:logger/logger.dart';

class NativeSmsService {
  static const MethodChannel _channel = MethodChannel('sms_channel');
  final Logger _logger = Logger();

  /// Fetch SMS messages
  Future<List<SmsMessage>> fetchSmsMessages() async {
    try {
      final String result = await _channel.invokeMethod('fetchSmsMessages');

      final Map<String, dynamic> jsonResult = json.decode(result);

      if (jsonResult['success'] == true) {
        final List<dynamic> messages = jsonResult['messages'];
        final List<SmsMessage> smsMessages = messages
            .map((msg) => SmsMessage.fromJson(msg))
            .toList();

        return smsMessages;
      } else {
        _logger.e('Failed to fetch SMS messages: ${jsonResult['error']}');
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching SMS messages(native_sms_service): $e');
      return [];
    }
  }

  /// Fetch SMS messages since a specific timestamp
  Future<List<SmsMessage>> fetchSmsMessagesSince(DateTime since) async {
    try {
      final sinceTimestamp = since.millisecondsSinceEpoch;
      final String result = await _channel.invokeMethod(
        'fetchSmsMessagesSince',
        {'sinceTimestamp': sinceTimestamp},
      );

      final Map<String, dynamic> jsonResult = json.decode(result);

      if (jsonResult['success'] == true) {
        final List<dynamic> messages = jsonResult['messages'];
        final List<SmsMessage> smsMessages = messages
            .map((msg) => SmsMessage.fromJson(msg))
            .toList();

        return smsMessages;
      } else {
        _logger.e(
          'Failed to fetch SMS messages since timestamp: ${jsonResult['error']}',
        );
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching SMS messages since timestamp: $e');
      return [];
    }
  }

  /// Get total count of SMS messages
  Future<int> getSmsCount() async {
    try {
      final int count = await _channel.invokeMethod('getSmsCount');
      _logger.i('Total SMS count: $count');
      return count;
    } catch (e) {
      _logger.e('Error getting SMS count: $e');
      return 0;
    }
  }

  /// Parse SMS messages into transactions
  List<Transaction> parseTransactionsFromMessages(List<SmsMessage> messages) {
    final List<Transaction> transactions = [];

    for (final message in messages) {
      final transaction = _parseTransactionFromMessage(message);
      if (transaction != null) {
        transactions.add(transaction);
      }
    }

    return transactions;
  }

  /// Parse a single SMS message into a transaction
  Transaction? _parseTransactionFromMessage(SmsMessage message) {
    double amount = 0.0;
    String desc = '';

    final RegExp amountRegex = RegExp(
      r'Rs\.(\d+\.\d{2})',
      caseSensitive: false,
    );

    final RegExp descRegex = RegExp(r'^To\s+(.*)$', multiLine: true);
    final body = message.body;
    if (body.contains('Sent Rs')) {
      // Debit
      final amountMatch = amountRegex.firstMatch(body);
      final descMatch = descRegex.firstMatch(body);
      amount = amountMatch != null
          ? double.tryParse(amountMatch.group(1)!.replaceAll(',', '')) ?? 0.0
          : 0.0;
      desc = descMatch != null ? descMatch.group(1)!.trim() : 'Unknown';
      for (var i = 0; i < 5; i++) {}
      {
        Logger().i('SMS body: $body');
        Logger().i(
          'amountMatch: ${amountMatch != null ? amountMatch.group(1) : 'null'}',
        );
        Logger().i(
          'descMatch: ${descMatch != null ? descMatch.group(1) : 'null'}',
        );
      }
      // log the amount and desc
      _logger.i('Amount: $amount, Desc: $desc');
    }
    final Transaction tx = Transaction(
      type: 'Debit',
      amount: amount,
      description: desc,
      category: '',
      source: 'SMS',
      dateTime: DateTime.fromMillisecondsSinceEpoch(message.date),
      excluded: false,
    );
    // TODO: You can add more parsing for 'Credit Alert' if needed
    return tx;
  }
}

/// SMS Message model
class SmsMessage {
  final int id;
  final String description;
  final double amount;
  final String source;
  final String body;
  final int date;
  final int type;

  SmsMessage({
    required this.id,
    required this.description,
    required this.body,
    required this.date,
    required this.type,
    required this.amount,
    required this.source,
  });

  factory SmsMessage.fromJson(Map<String, dynamic> json) {
    return SmsMessage(
      id: json['id'] ?? 0,
      description: json['description'] ?? '',
      body: json['body'] ?? '',
      date: json['date'] ?? 0,
      type: json['type'] ?? 0,
      amount: json['amount'] ?? 0.0,
      source: json['source'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'body': body,
      'date': date,
      'type': type,
      'amount': amount,
      'source': source,
    };
  }
}
