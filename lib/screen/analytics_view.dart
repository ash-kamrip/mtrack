import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/transaction.dart';
import 'dart:math';

class AnalyticsView extends StatefulWidget {
  final List<Transaction> transactions;
  const AnalyticsView({super.key, required this.transactions});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  int _selectedTab = 1; // 0: Weekly, 1: Monthly, 2: Custom

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTabButton('Weekly', 0),
            SizedBox(width: 8),
            _buildTabButton('Monthly', 1),
            SizedBox(width: 8),
            _buildTabButton('Custom', 2),
          ],
        ),
        SizedBox(height: 20),
        _buildSpendingTrendCard(),
        SizedBox(height: 20),
        _buildCategorySummaryCard(),
        SizedBox(height: 20),
        _buildPieChartCard(),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                color: isSelected ? Colors.white : Colors.black,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingTrendCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Spending Trend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            SizedBox(height: 16),
            SizedBox(height: 220, child: LineChart(_buildLineChartData())),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData() {
    // Dummy data for 6 months
    final months = [
      'Jan 2025',
      'Feb 2025',
      'Mar 2025',
      'Apr 2025',
      'May 2025',
      'Jun 2025',
    ];
    final values = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    for (var tx in widget.transactions) {
      if (tx.type == 'Debit') {
        final idx = months.indexWhere(
          (m) => m.contains(_monthYear(tx.dateTime)),
        );
        if (idx != -1) values[idx] += tx.amount;
      }
    }
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (v) =>
            FlLine(color: Colors.grey.shade300, dashArray: [5, 5]),
        getDrawingVerticalLine: (v) =>
            FlLine(color: Colors.grey.shade300, dashArray: [5, 5]),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, meta) => Text(
              '₹${v.toInt()}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, meta) => Text(
              months[v.toInt()],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            interval: 1,
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      minX: 0,
      maxX: 5,
      minY: 0,
      maxY: max(4, values.reduce(max)),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(6, (i) => FlSpot(i.toDouble(), values[i])),
          isCurved: false,
          color: Colors.blue,
          barWidth: 2,
          dotData: FlDotData(show: false),
        ),
      ],
    );
  }

  String _monthYear(DateTime dt) => '${_monthShort(dt.month)} ${dt.year}';
  String _monthShort(int m) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  Widget _buildCategorySummaryCard() {
    final Map<String, double> categoryTotals = {};
    for (var tx in widget.transactions) {
      if (tx.type == 'Debit') {
        categoryTotals[tx.category] =
            (categoryTotals[tx.category] ?? 0) + tx.amount;
      }
    }
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.brown,
    ];
    int colorIdx = 0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            SizedBox(height: 16),
            ...categoryTotals.entries.map((e) {
              final color = colors[colorIdx++ % colors.length];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 8, backgroundColor: color),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Text(
                      '₹${e.value.toInt()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard() {
    final Map<String, double> categoryTotals = {};
    double total = 0;
    for (var tx in widget.transactions) {
      if (tx.type == 'Debit') {
        categoryTotals[tx.category] =
            (categoryTotals[tx.category] ?? 0) + tx.amount;
        total += tx.amount;
      }
    }
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.brown,
    ];
    int colorIdx = 0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Spending by Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: categoryTotals.entries.map((e) {
                    final color = colors[colorIdx++ % colors.length];
                    final percent = total == 0
                        ? 0
                        : (e.value / total * 100).round();
                    return PieChartSectionData(
                      color: color,
                      value: e.value,
                      title: percent > 0 ? '${e.key} $percent%' : '',
                      titleStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color == Colors.orange
                            ? Colors.white
                            : Colors.black,
                      ),
                      radius: 60,
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
