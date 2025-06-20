import 'package:flutter/material.dart';

/// Widget that displays monthly spending information with a circular progress indicator
/// or net income/expense summary based on whether a spend limit is set.
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
            _buildHeader(colorScheme),
            const SizedBox(height: 16),
            _buildProgressIndicator(
              colorScheme,
              indicatorColor,
              netAmount,
              netColor,
            ),
            if (monthlySpendLimit == 0) ...[
              const SizedBox(height: 16),
              _buildCreditsDebitsSummary(
                currentMonthCredits,
                currentMonthDebits,
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Builds the header section with title and icon
  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
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
    );
  }

  /// Builds the circular progress indicator or net amount display
  Widget _buildProgressIndicator(
    ColorScheme colorScheme,
    Color indicatorColor,
    double netAmount,
    Color netColor,
  ) {
    return Stack(
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
                  : (currentMonthDebits / monthlySpendLimit).clamp(0.0, 1.0),
              strokeWidth: 10,
              backgroundColor: colorScheme.surfaceVariant,
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
                color: monthlySpendLimit > 0 ? indicatorColor : netColor,
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
    );
  }

  /// Builds the credits and debits summary section
  Widget _buildCreditsDebitsSummary(double credits, double debits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text(
              '₹${credits.toInt()}',
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
              '₹${debits.toInt()}',
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
    );
  }
}
