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
        onTap: () {
          // when you tap on a button it should set the value on a variable
          // based on this variable we perform calculations
          setState(() => _selectedTab = index);
          // Always reload bar chart data when tab changes
          _loadBarChartData();
        },
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

  int? _touchedBarIndex;
  List<String> _barLabels = [];
  List<double> _barValues = [];
  // No loading state needed

  @override
  void initState() {
    super.initState();
    _loadBarChartData();
  }

  // Loads and prepares the data for the bar chart (last 6 months or 6 weeks of spending)
  // since the data needs to be calculated this is async
  Future<void> _loadBarChartData() async {
    // 1. Get all transactions from the widget (not from Hive directly)
    //    If you want live data, fetch from Hive here instead.
    final allTx = widget.transactions;
    final now = DateTime.now();
    List<String> labels = [];
    List<double> values = [];
    if (_selectedTab == 0) {
      // Weekly: show last 6 weeks (each bar = 1 week)
      for (int i = 5; i >= 0; i--) {
        final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
        final weekEnd = weekStart.add(Duration(days: 6));
        final label = '${weekStart.day}/${weekStart.month}';
        labels.add(label);
        final weekTx = allTx.where(
          (tx) =>
              tx.type == 'Debit' &&
              !tx.excluded &&
              tx.dateTime.isAfter(
                weekStart.subtract(const Duration(seconds: 1)),
              ) &&
              tx.dateTime.isBefore(weekEnd.add(const Duration(days: 1))),
        );
        final total = weekTx.fold(0.0, (sum, tx) => sum + tx.amount);
        values.add(total);
      }
    } else {
      // Monthly: show last 6 months (each bar = 1 month)
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final label = _monthShort(month.month).toUpperCase();
        labels.add(label);
        final monthTx = allTx.where(
          (tx) =>
              tx.type == 'Debit' &&
              !tx.excluded &&
              tx.dateTime.year == month.year &&
              tx.dateTime.month == month.month,
        );
        final total = monthTx.fold(0.0, (sum, tx) => sum + tx.amount);
        values.add(total);
      }
    }
    setState(() {
      _barLabels = labels;
      _barValues = values;
    });
  }

  // Card showing a bar chart of monthly/weekly/custom spending trend
  Widget _buildSpendingTrendCard() {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Monthly Spending Trend',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(height: 220, child: BarChart(_buildBarChartData())),
        ],
      ),
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

  // displays the data for the bar chart (spending per range)
  BarChartData _buildBarChartData() {
    final count = _barLabels.length;
    final barColor = const LinearGradient(
      colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: _barValues.isNotEmpty ? (_barValues.reduce(max) * 1.2) : 4,
      minY: 0,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final value = _barValues[group.x.toInt()];
            return BarTooltipItem(
              '₹${value.toStringAsFixed(2)}',
              TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            );
          },
        ),
        touchCallback: (event, response) {
          setState(() {
            if (response != null &&
                response.spot != null &&
                event.isInterestedForInteractions) {
              _touchedBarIndex = response.spot!.touchedBarGroupIndex;
            } else {
              _touchedBarIndex = null;
            }
          });
        },
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) =>
            FlLine(color: Colors.grey.shade200, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            getTitlesWidget: (v, meta) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                v == 0
                    ? '0'
                    : v >= 1000
                    ? '${(v ~/ 1000)}k'
                    : v.toInt().toString(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            interval: _barValues.isNotEmpty
                ? (_barValues.reduce(max) / 4).ceilToDouble()
                : 1,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (v, meta) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _barLabels.isNotEmpty ? _barLabels[v.toInt()] : '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                  letterSpacing: 1,
                ),
              ),
            ),
            interval: 1,
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barGroups: List.generate(count, (i) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _barValues[i],
              borderRadius: BorderRadius.circular(8),
              width: 14,
              gradient: barColor,
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _barValues.isNotEmpty ? (_barValues.reduce(max) * 1.2) : 4,
                color: Colors.grey.shade100,
              ),
            ),
          ],
        );
      }),
    );
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Category Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            );
          }),
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Overall Spending by Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
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
    );
  }
}
