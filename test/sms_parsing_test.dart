import 'package:flutter_test/flutter_test.dart';
import 'package:mtrack/services/native_sms_service.dart';

void main() {
  group('SMS Parsing Tests', () {
    late NativeSmsService smsService;

    setUp(() {
      smsService = NativeSmsService();
    });

    test('should parse debit transaction with Rs. format', () {
      final smsMessage = SmsMessage(
        id: 1,
        description: '',
        body: '''Sent Rs.150.00 
From HDFC Bank A/C *3341
To Jayanthi A
On 15-08
Ref 422888632270
Not You? Call 18002586161/SMS BLOCK UPI to 7308080808''',
        date: DateTime.now().millisecondsSinceEpoch,
        type: 1,
        amount: 0.0,
        source: '',
      );

      final transaction = smsService.parseTransactionsFromMessages([
        smsMessage,
      ]);

      expect(transaction.length, 1);
      expect(transaction.first.type, 'Debit');
      expect(transaction.first.amount, 150.0);
      expect(transaction.first.description, 'Jayanthi A');
    });

    test('first', () {
      final smsMessage = SmsMessage(
        id: 1,
        description: '',
        body: 'Sent Rs 500 to Jane Smith',
        date: DateTime.now().millisecondsSinceEpoch,
        type: 1,
        amount: 0.0,
        source: '',
      );

      final transaction = smsService.parseTransactionsFromMessages([
        smsMessage,
      ]);

      expect(transaction.length, 1);
      expect(transaction.first.type, 'Debit');
      expect(transaction.first.amount, 500.0);
      expect(transaction.first.description, 'Jane Smith');
    });

    test('should parse debit transaction with comma in amount', () {
      final smsMessage = SmsMessage(
        id: 1,
        description: '',
        body: 'Sent Rs. 1,000.50 to Business Name',
        date: DateTime.now().millisecondsSinceEpoch,
        type: 1,
        amount: 0.0,
        source: '',
      );

      final transaction = smsService.parseTransactionsFromMessages([
        smsMessage,
      ]);

      expect(transaction.length, 1);
      expect(transaction.first.type, 'Debit');
      expect(transaction.first.amount, 1000.50);
      expect(transaction.first.description, 'Business Name');
    });

    test('should parse debit transaction with To: format', () {
      final smsMessage = SmsMessage(
        id: 1,
        description: '',
        body: 'Sent Rs. 750.00 To: Alice Johnson',
        date: DateTime.now().millisecondsSinceEpoch,
        type: 1,
        amount: 0.0,
        source: '',
      );

      final transaction = smsService.parseTransactionsFromMessages([
        smsMessage,
      ]);

      expect(transaction.length, 1);
      expect(transaction.first.type, 'Debit');
      expect(transaction.first.amount, 750.0);
      expect(transaction.first.description, 'Alice Johnson');
    });

    test('should handle transaction with decimal amount', () {
      final smsMessage = SmsMessage(
        id: 1,
        description: '',
        body: 'Sent Rs. 99.99 to Test User',
        date: DateTime.now().millisecondsSinceEpoch,
        type: 1,
        amount: 0.0,
        source: '',
      );

      final transaction = smsService.parseTransactionsFromMessages([
        smsMessage,
      ]);

      expect(transaction.length, 1);
      expect(transaction.first.type, 'Debit');
      expect(transaction.first.amount, 99.99);
      expect(transaction.first.description, 'Test User');
    });

    test('should handle transaction with large amount', () {
      final smsMessage = SmsMessage(
        id: 1,
        description: '',
        body: 'Sent Rs. 50,000.00 to Big Transaction',
        date: DateTime.now().millisecondsSinceEpoch,
        type: 1,
        amount: 0.0,
        source: '',
      );

      final transaction = smsService.parseTransactionsFromMessages([
        smsMessage,
      ]);

      expect(transaction.length, 1);
      expect(transaction.first.type, 'Debit');
      expect(transaction.first.amount, 50000.0);
      expect(transaction.first.description, 'Big Transaction');
    });

    test('should return empty list for non-transaction SMS', () {
      final smsMessage = SmsMessage(
        id: 1,
        description: '',
        body: 'Hello, this is a regular SMS message',
        date: DateTime.now().millisecondsSinceEpoch,
        type: 1,
        amount: 0.0,
        source: '',
      );

      final transaction = smsService.parseTransactionsFromMessages([
        smsMessage,
      ]);

      expect(transaction.length, 0);
    });

    test('should not parse SMS with Rs but no transaction data', () {
      final smsMessage = SmsMessage(
        id: 1,
        description: '',
        body: 'Your balance is Rs. 5000.00. Thank you for using our service.',
        date: DateTime.now().millisecondsSinceEpoch,
        type: 1,
        amount: 0.0,
        source: '',
      );

      final transaction = smsService.parseTransactionsFromMessages([
        smsMessage,
      ]);

      expect(transaction.length, 0);
    });

    test('should handle multiple SMS messages', () {
      final smsMessages = [
        SmsMessage(
          id: 1,
          description: '',
          body: 'Sent Rs. 100 to User1',
          date: DateTime.now().millisecondsSinceEpoch,
          type: 1,
          amount: 0.0,
          source: '',
        ),
        SmsMessage(
          id: 2,
          description: '',
          body: 'Sent Rs. 200 to User2',
          date: DateTime.now().millisecondsSinceEpoch,
          type: 1,
          amount: 0.0,
          source: '',
        ),
        SmsMessage(
          id: 3,
          description: '',
          body: 'Regular SMS message',
          date: DateTime.now().millisecondsSinceEpoch,
          type: 1,
          amount: 0.0,
          source: '',
        ),
      ];

      final transactions = smsService.parseTransactionsFromMessages(
        smsMessages,
      );

      expect(transactions.length, 2);
      expect(transactions[0].amount, 100.0);
      expect(transactions[0].description, 'User1');
      expect(transactions[1].amount, 200.0);
      expect(transactions[1].description, 'User2');
    });

    test('should handle SMS with no description found', () {
      final smsMessage = SmsMessage(
        id: 1,
        description: '',
        body: 'Sent Rs. 500.00',
        date: DateTime.now().millisecondsSinceEpoch,
        type: 1,
        amount: 0.0,
        source: '',
      );

      final transaction = smsService.parseTransactionsFromMessages([
        smsMessage,
      ]);

      expect(transaction.length, 1);
      expect(transaction.first.type, 'Debit');
      expect(transaction.first.amount, 500.0);
      expect(transaction.first.description, 'Unknown');
    });

    test('should handle SMS with no amount found', () {
      final smsMessage = SmsMessage(
        id: 1,
        description: '',
        body: 'Sent to John Doe',
        date: DateTime.now().millisecondsSinceEpoch,
        type: 1,
        amount: 0.0,
        source: '',
      );

      final transaction = smsService.parseTransactionsFromMessages([
        smsMessage,
      ]);

      expect(transaction.length, 1);
      expect(transaction.first.type, 'Debit');
      expect(transaction.first.amount, 0.0);
      expect(transaction.first.description, 'John Doe');
    });

    test('should parse multiline debit transaction SMS', () {
      final smsMessage = SmsMessage(
        id: 1,
        description: '',
        body: '''Amt Sent Rs.150.00 
From HDFC Bank A/C *3341
To Jayanthi A
On 15-08
Ref 422888632270
Not You? Call 18002586161/SMS BLOCK UPI to 7308080808''',
        date: DateTime.now().millisecondsSinceEpoch,
        type: 1,
        amount: 0.0,
        source: '',
      );

      final transaction = smsService.parseTransactionsFromMessages([
        smsMessage,
      ]);

      expect(transaction.length, 1);
      expect(transaction.first.type, 'Debit');
      expect(transaction.first.amount, 150.0);
      expect(transaction.first.description, 'Jayanthi A');
    });

    test('should parse credit transaction SMS', () {
      final smsMessage = SmsMessage(
        id: 1,
        description: '',
        body: '''Credit Alert!
Rs.300.00 credited to HDFC Bank A/c xx3341 on 06-05-25 from VPA gokullkb@okicici (UPI 512656034180)''',
        date: DateTime.now().millisecondsSinceEpoch,
        type: 1,
        amount: 0.0,
        source: '',
      );

      final transaction = smsService.parseTransactionsFromMessages([
        smsMessage,
      ]);

      expect(transaction.length, 1);
      expect(transaction.first.type, 'Credit');
      expect(transaction.first.amount, 300.0);
      expect(transaction.first.description, 'gokullkb@okicici');
    });

    test('should parse credit transaction with different format', () {
      final smsMessage = SmsMessage(
        id: 1,
        description: '',
        body: '''Amount Received: Rs. 1000.00
From: Jane Smith
Transaction ID: TXN123456
Date: 15-12-2024''',
        date: DateTime.now().millisecondsSinceEpoch,
        type: 1,
        amount: 0.0,
        source: '',
      );

      final transaction = smsService.parseTransactionsFromMessages([
        smsMessage,
      ]);

      expect(transaction.length, 1);
      expect(transaction.first.type, 'Credit');
      expect(transaction.first.amount, 1000.0);
      expect(transaction.first.description, 'Jane Smith');
    });
  });
}
