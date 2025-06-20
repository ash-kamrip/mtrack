import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/transaction.dart';
import '../widgets/transaction_item.dart';

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
                      excluded: tx.excluded,
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
