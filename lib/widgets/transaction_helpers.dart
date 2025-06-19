import 'transaction.dart';

List<Transaction> getLatestTransactions(
  List<Transaction> all, {
  int count = 10,
}) {
  final sorted = [...all]..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  return sorted.take(count).toList();
}

List<Transaction> getCurrentMonthTransactions(List<Transaction> all) {
  final now = DateTime.now();
  return all
      .where(
        (tx) => tx.dateTime.month == now.month && tx.dateTime.year == now.year,
      )
      .toList();
}

double getDebits(List<Transaction> txs) => txs
    .where((tx) => tx.type == 'Debit' && !tx.excluded)
    .fold<double>(0, (sum, tx) => sum + tx.amount);

double getCredits(List<Transaction> txs) => txs
    .where((tx) => tx.type == 'Credit' && !tx.excluded)
    .fold<double>(0, (sum, tx) => sum + tx.amount);
