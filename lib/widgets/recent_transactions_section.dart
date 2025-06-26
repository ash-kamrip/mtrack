import 'package:flutter/material.dart';
import 'transaction.dart';
import 'transaction_item.dart';
import 'add_transaction_dialog.dart';
import 'package:intl/intl.dart';

class RecentTransactionsSection extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onAddTransaction;
  final void Function(Transaction oldTx, Transaction newTx) onEditTransaction;
  final void Function(Transaction tx) onDeleteTransaction;
  final int? showOnlyTop;
  final TextStyle? amountTextStyle;
  final TextStyle? titleTextStyle;
  final double verticalSpacing;
  final EdgeInsetsGeometry? buttonPadding;
  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
    this.showOnlyTop,
    this.titleTextStyle,
    this.amountTextStyle,
    this.verticalSpacing = 8,
    this.buttonPadding,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      buttonPadding ?? const EdgeInsets.symmetric(vertical: 6),
                  child: ElevatedButton(
                    onPressed: onAddTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      '+ Add Transaction',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              height: 350, // Adjust as needed or make dynamic
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  final dateStr = sortedKeys[index];
                  final txList = grouped[dateStr]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Text(
                          dateStr,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      ...txList.map(
                        (tx) => TransactionItem(
                          isIncome: tx.type == 'Credit',
                          title: tx.description,
                          time: DateFormat('hh:mm a').format(tx.dateTime),
                          amount: tx.amount.toInt(),
                          date: dateStr,
                          label: tx.category,
                          amountTextStyle:
                              amountTextStyle ??
                              const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                          verticalSpacing: verticalSpacing,
                          onEdit: () async {
                            final editedTx = await showDialog<Transaction>(
                              context: context,
                              builder: (context) => AddTransactionDialog(
                                initialTransaction: tx,
                                isEdit: true,
                              ),
                            );
                            if (editedTx != null) {
                              onEditTransaction(tx, editedTx);
                            }
                          },
                          onDelete: () => onDeleteTransaction(tx),
                          excluded: tx.excluded,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
