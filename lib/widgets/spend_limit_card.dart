import 'package:flutter/material.dart';

/// Widget for displaying and managing monthly spend limit
class SpendLimitCard extends StatelessWidget {
  final double limit;
  final VoidCallback onSetLimit;

  const SpendLimitCard({
    super.key,
    required this.limit,
    required this.onSetLimit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          Icons.shield_outlined,
          color: colorScheme.secondary,
          size: 32,
        ),
        title: const Text(
          'Monthly Spend Limit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          limit > 0 ? '₹${limit.toInt()}' : 'Not Set',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: limit > 0 ? colorScheme.primary : Colors.grey,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onSetLimit,
          tooltip: 'Set Limit',
        ),
      ),
    );
  }
}
