class Transaction {
  final String type; // 'Debit' or 'Credit'
  final double amount;
  final String description;
  final String category;
  final String source;
  final DateTime dateTime;

  Transaction({
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.source,
    required this.dateTime,
  });
}
