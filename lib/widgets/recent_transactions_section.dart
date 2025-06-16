import 'package:flutter/material.dart';
import 'transaction.dart';
import 'transaction_item.dart';

class RecentTransactionsSection extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onAddTransaction;
  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
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
            ...transactions.asMap().entries.map((entry) {
              final tx = entry.value;
              return Column(
                children: [
                  TransactionItem(
                    isIncome: tx.type == 'Credit',
                    title: tx.description,
                    time: TimeOfDay.fromDateTime(tx.dateTime).format(context),
                    amount: tx.amount.toInt(),
                    date: '',
                    label: tx.category,
                  ),
                  if (entry.key != transactions.length - 1) Divider(),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
