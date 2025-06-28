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
    final body = message.body;

    // Only process SMS that contain transaction indicators
    if (!body.contains('Sent Rs') &&
        !body.contains('Rs.') &&
        !body.contains('Rs ') &&
        !body.contains('Credit') &&
        !body.contains('Received') &&
        !body.contains('credited')) {
      return null;
    }

    try {
      double amount = 0.0;
      String description = '';
      String transactionType = '';

      // Improved amount regex to match various formats
      final RegExp amountRegex = RegExp(
        r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)',
        caseSensitive: false,
      );

      // Check for debit transactions (money sent out)
      if (body.contains('Sent Rs') || body.contains('sent Rs')) {
        transactionType = 'Debit';

        // Improved description regex to match "To" on any line
        final RegExp descRegex = RegExp(
          r'To\s*:?\s*([A-Za-z\s]+?)(?:\s+Rs\.|$|\n)',
          caseSensitive: false,
          multiLine: true,
        );

        final descMatch = descRegex.firstMatch(body);
        if (descMatch != null) {
          description = descMatch.group(1)?.trim() ?? '';
        }
      }
      // Check for credit transactions (money received)
      else if (body.contains('Credit') ||
          body.contains('credited') ||
          body.contains('Received')) {
        transactionType = 'Credit';

        // Look for "From" or sender information
        final RegExp fromRegex = RegExp(
          r'From\s*:?\s*([A-Za-z\s]+?)(?:\s+Rs\.|$|\n)',
          caseSensitive: false,
          multiLine: true,
        );

        // Look for VPA/UPI sender information (like "from VPA gokullkb@okicici")
        final RegExp vpaRegex = RegExp(
          r'from\s+VPA\s+([^\s]+)',
          caseSensitive: false,
        );

        // Look for general sender patterns
        final RegExp senderRegex = RegExp(
          r'(?:credited|received|credit)\s+(?:by|from|to)\s+([A-Za-z\s]+?)(?:\s+Rs\.|$|\n)',
          caseSensitive: false,
          multiLine: true,
        );

        final fromMatch = fromRegex.firstMatch(body);
        final vpaMatch = vpaRegex.firstMatch(body);
        final senderMatch = senderRegex.firstMatch(body);

        if (vpaMatch != null) {
          // Extract VPA/UPI ID as description
          description = vpaMatch.group(1)?.trim() ?? '';
        } else if (fromMatch != null) {
          description = fromMatch.group(1)?.trim() ?? '';
        } else if (senderMatch != null) {
          description = senderMatch.group(1)?.trim() ?? '';
        }
      }

      // Extract amount for both debit and credit
      final amountMatch = amountRegex.firstMatch(body);
      if (amountMatch != null) {
        final amountStr = amountMatch.group(1)?.replaceAll(',', '') ?? '';
        amount = double.tryParse(amountStr) ?? 0.0;
      }

      // Log for debugging
      _logger.i('SMS body: $body');
      _logger.i('Transaction type: $transactionType');
      _logger.i(
        'amountMatch: ${amountMatch != null ? amountMatch.group(1) : 'null'}',
      );
      _logger.i('Amount: $amount, Desc: $description');

      // Only return transaction if we successfully parsed both amount and description
      if (amount > 0.0 &&
          description.isNotEmpty &&
          transactionType.isNotEmpty) {
        return Transaction(
          type: transactionType,
          amount: amount,
          description: description,
          category: '',
          source: 'SMS',
          dateTime: DateTime.fromMillisecondsSinceEpoch(message.date),
          excluded: false,
        );
      }

      // If we couldn't parse properly, return null
      _logger.w(
        'Failed to parse transaction from SMS: type=$transactionType, amount=$amount, desc="$description"',
      );
      return null;
    } catch (e) {
      _logger.e('Error parsing transaction from SMS: $e');
      return null;
    }
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
