import 'package:flutter/material.dart';

class TransactionItem extends StatelessWidget {
  final bool isIncome;
  final String title;
  final String time;
  final int amount;
  final String date;
  final String label;

  const TransactionItem({
    super.key,
    required this.isIncome,
    required this.title,
    required this.time,
    required this.amount,
    required this.date,
    required this.label,
  });

  Color _getLabelColor(String label) {
    switch (label.toLowerCase()) {
      case 'food':
        return Colors.green.shade100;
      case 'income':
        return Colors.yellow.shade100;
      case 'transport':
        return Colors.blue.shade100;
      case 'shopping':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getLabelTextColor(String label) {
    switch (label.toLowerCase()) {
      case 'food':
        return Colors.green.shade900;
      case 'income':
        return Colors.yellow.shade900;
      case 'transport':
        return Colors.blue.shade900;
      case 'shopping':
        return Colors.purple.shade900;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
          child: Icon(
            isIncome ? Icons.trending_up : Icons.trending_down,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Text(
                    time,
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  if (label.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getLabelColor(label),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getLabelTextColor(label),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Text(
          (isIncome ? '+₹' : '-₹') + amount.toString(),
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
