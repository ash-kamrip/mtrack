import 'package:flutter/material.dart';
import 'transaction.dart';
import 'transaction_item.dart';
import 'package:intl/intl.dart';

class RecentTransactionsSection extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onAddTransaction;
  final int? showOnlyTop;
  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
    this.showOnlyTop,
  });

  Map<String, List<Transaction>> _groupByDate(List<Transaction> txs) {
    Map<String, List<Transaction>> grouped = {};
    for (var tx in txs) {
      String dateStr = DateFormat('dd MMM yyyy').format(tx.dateTime);
      grouped.putIfAbsent(dateStr, () => []).add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final txs = showOnlyTop != null
        ? transactions.take(showOnlyTop!).toList()
        : transactions;
    final grouped = _groupByDate(txs);
    final sortedKeys = grouped.keys.toList()
      ..sort(
        (a, b) => DateFormat(
          'dd MMM yyyy',
        ).parse(b).compareTo(DateFormat('dd MMM yyyy').parse(a)),
      );
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.black54),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recent Transactions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: onAddTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '+ Add Transaction',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...sortedKeys.map(
              (dateStr) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  ...grouped[dateStr]!.map(
                    (tx) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TransactionItem(
                        isIncome: tx.type == 'Credit',
                        title: tx.description,
                        time: DateFormat('hh:mm a').format(tx.dateTime),
                        amount: tx.amount.toInt(),
                        date: dateStr,
                        label: tx.category,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AllTransactionsScreen extends StatelessWidget {
  final List<Transaction> transactions;
  const AllTransactionsScreen({super.key, required this.transactions});

  Map<String, List<Transaction>> _groupByDate(List<Transaction> txs) {
    Map<String, List<Transaction>> grouped = {};
    for (var tx in txs) {
      String dateStr = DateFormat('dd MMM yyyy').format(tx.dateTime);
      grouped.putIfAbsent(dateStr, () => []).add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(transactions);
    final sortedKeys = grouped.keys.toList()
      ..sort(
        (a, b) => DateFormat(
          'dd MMM yyyy',
        ).parse(b).compareTo(DateFormat('dd MMM yyyy').parse(a)),
      );
    return Scaffold(
      appBar: AppBar(title: Text('All Transactions')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ...sortedKeys.map(
            (dateStr) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                ...grouped[dateStr]!.map(
                  (tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TransactionItem(
                      isIncome: tx.type == 'Credit',
                      title: tx.description,
                      time: DateFormat('hh:mm a').format(tx.dateTime),
                      amount: tx.amount.toInt(),
                      date: dateStr,
                      label: tx.category,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
