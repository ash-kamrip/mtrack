import 'package:flutter/material.dart';

class MonthlySpendsCard extends StatelessWidget {
  final double currentMonthDebits;
  final double currentMonthCredits;
  final double monthlySpendLimit;

  const MonthlySpendsCard({
    super.key,
    required this.currentMonthDebits,
    required this.currentMonthCredits,
    required this.monthlySpendLimit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isOverLimit =
        currentMonthDebits > monthlySpendLimit && monthlySpendLimit > 0;
    final indicatorColor = isOverLimit ? Colors.red : colorScheme.primary;

    // Calculate net amount (credits - debits)
    final netAmount = currentMonthCredits - currentMonthDebits;
    final netColor = netAmount >= 0 ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, color: colorScheme.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  monthlySpendLimit > 0 ? 'Monthly Spends' : 'Monthly Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Visibility(
                    visible: monthlySpendLimit > 0,
                    child: CircularProgressIndicator(
                      value: monthlySpendLimit == 0
                          ? 0
                          : (currentMonthDebits / monthlySpendLimit).clamp(
                              0.0,
                              1.0,
                            ),
                      strokeWidth: 10,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      monthlySpendLimit > 0
                          ? '₹${currentMonthDebits.toInt()}'
                          : '₹${netAmount.toInt()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        color: monthlySpendLimit > 0
                            ? indicatorColor
                            : netColor,
                      ),
                    ),
                    if (monthlySpendLimit == 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        netAmount >= 0 ? 'Net Income' : 'Net Expense',
                        style: TextStyle(
                          fontSize: 12,
                          color: netColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (monthlySpendLimit == 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        '₹${currentMonthCredits.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        'Credits',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  Column(
                    children: [
                      Text(
                        '₹${currentMonthDebits.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.red,
                        ),
                      ),
                      const Text(
                        'Debits',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
