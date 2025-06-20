import 'package:hive/hive.dart';
import '../widgets/transaction.dart';

class TransactionStorageService {
  static const String _boxName = 'transactions';

  static Future<Box<Transaction>> openBox() async {
    return await Hive.openBox<Transaction>(_boxName);
  }

  static Future<List<Transaction>> getAllTransactions() async {
    final box = await openBox();
    return box.values.toList();
  }

  static Future<void> addTransaction(Transaction tx) async {
    final box = await openBox();
    await box.add(tx);
  }

  static Future<void> addTransactions(List<Transaction> txs) async {
    final box = await openBox();
    await box.addAll(txs);
  }

  static Future<bool> isEmpty() async {
    final box = await openBox();
    return box.isEmpty;
  }

  static Future<void> clearAll() async {
    final box = await openBox();
    await box.clear();
  }
}
