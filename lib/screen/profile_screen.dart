import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// create a bar chart example class and use it in the profile screen
class BarChartExample extends StatelessWidget {
  const BarChartExample({super.key});
  @override
  Widget build(BuildContext context) {
    final List<BarChartGroupData> barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: 8,
            color: Colors.blue,
            width: 20,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: 10,
            color: Colors.green,
            width: 20,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: 14,
            color: Colors.orange,
            width: 20,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [
          BarChartRodData(
            toY: 15,
            color: Colors.red,
            width: 20,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
      BarChartGroupData(
        x: 4,
        barRods: [
          BarChartRodData(
            toY: 13,
            color: Colors.purple,
            width: 20,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Bar Chart Example')),
      body: BarChart(
        BarChartData(barGroups: barGroups, gridData: FlGridData(show: false)),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BarChartExample();
  }
}
