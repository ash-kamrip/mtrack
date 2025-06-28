import 'package:hive/hive.dart';
import '../widgets/transaction.dart';

class TransactionStorageService {
  static const String _boxName = 'transactions';
  static Box<Transaction>? _cachedBox;

  static Future<Box<Transaction>> openBox() async {
    if (_cachedBox == null || !_cachedBox!.isOpen) {
      _cachedBox = await Hive.openBox<Transaction>(_boxName);
    }
    return _cachedBox!;
  }

  static Future<List<Transaction>> getAllTransactions() async {
    final box = await openBox();
    return box.values.toList();
  }

  // Synchronous method to get all transactions (requires box to be already opened)
  static List<Transaction> getAllTransactionsSync() {
    if (_cachedBox == null || !_cachedBox!.isOpen) {
      // If box is not open, return empty list
      return [];
    }
    final allTransactions = _cachedBox!.values.toList();
    // Sort by date descending (newest first)
    allTransactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return allTransactions;
  }

  // Get only the latest N transactions, sorted by date descending
  static Future<List<Transaction>> getLatestTransactions(int count) async {
    final box = await openBox();
    final allTransactions = box.values.toList();

    // Sort by date descending (newest first)
    allTransactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // Return only the first N transactions
    return allTransactions.take(count).toList();
  }

  static Future<void> addTransaction(Transaction tx) async {
    final box = await openBox();
    await box.add(tx);
  }

  static Future<void> addTransactions(List<Transaction> txs) async {
    final box = await openBox();
    await box.addAll(txs);
  }

  // Update an existing transaction by its key
  static Future<void> updateTransaction(int key, Transaction updatedTx) async {
    final box = await openBox();
    await box.put(key, updatedTx);
  }

  // Delete a transaction by its key
  static Future<void> deleteTransaction(int key) async {
    final box = await openBox();
    await box.delete(key);
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
