import 'package:hive/hive.dart';
part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String type; // 'Debit' or 'Credit'
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String category;
  @HiveField(4)
  final String source;
  @HiveField(5)
  final DateTime dateTime;
  // excluded from the total balance
  @HiveField(6)
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
