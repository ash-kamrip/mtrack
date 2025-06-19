class Transaction {
  final String type; // 'Debit' or 'Credit'
  final double amount;
  final String description;
  final String category;
  final String source;
  final DateTime dateTime;
  // excluded from the total balance
  final bool excluded;

  Transaction({
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.source,
    required this.dateTime,
    this.excluded = false,
  });
}
