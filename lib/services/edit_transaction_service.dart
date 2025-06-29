import '../widgets/transaction.dart';
import 'hive_services.dart';

/// Service for editing and deleting existing transactions in Hive.
class EditTransactionService {
  /// Update an existing transaction by its key.
  static Future<void> editTransaction(
    Transaction oldTx,
    Transaction newTx,
  ) async {
    // Use the key from the old transaction to update it in Hive
    await TransactionStorageService.updateTransaction(oldTx.key as int, newTx);
  }

  /// Delete a transaction by its key.
  static Future<void> deleteTransaction(Transaction tx) async {
    await TransactionStorageService.deleteTransaction(tx.key as int);
  }
}
