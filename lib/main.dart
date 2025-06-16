import 'package:flutter/material.dart';
import 'widgets/transaction.dart';
import 'widgets/add_transaction_dialog.dart';
import 'widgets/recent_transactions_section.dart';
import 'widgets/transaction_item.dart';
import 'widgets/analytics_view.dart';

void main() {
  runApp(MTrackApp());
}

class MTrackApp extends StatelessWidget {
  const MTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTrack',
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Inter'),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Transaction> _transactions = [
    Transaction(
      type: 'Credit',
      amount: 10000,
      description: 'salary',
      category: 'Income',
      source: 'Manual',
      dateTime: DateTime(2025, 6, 16, 1, 33),
    ),
    Transaction(
      type: 'Debit',
      amount: 250,
      description: 'ice cream',
      category: '',
      source: 'Manual',
      dateTime: DateTime(2025, 6, 16, 1, 33),
    ),
  ];

  int _selectedTab = 0;

  void _showAddTransactionDialog() async {
    final Transaction? newTx = await showDialog<Transaction>(
      context: context,
      builder: (context) => AddTransactionDialog(),
    );
    if (newTx != null) {
      setState(() {
        _transactions.insert(0, newTx);
      });
    }
  }

  void _onTabChanged(int index) {
    if (_selectedTab == index && index == 0) {
      // Already on Transactions tab, navigate to all transactions
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AllTransactionsScreen(transactions: _transactions),
        ),
      );
    } else {
      setState(() {
        _selectedTab = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Color(0xFF4CB8C4),
            child: Icon(Icons.account_balance_wallet, color: Colors.white),
          ),
        ),
        title: Text(
          'MTrack',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CB8C4), Color(0xFF3CD3AD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const MonthlySpendsCard(),
              SizedBox(height: 20),
              TransactionsAnalyticsTabs(
                selectedIndex: _selectedTab,
                onTabChanged: _onTabChanged,
              ),
              SizedBox(height: 20),
              if (_selectedTab == 0)
                RecentTransactionsSection(
                  transactions: _transactions,
                  onAddTransaction: _showAddTransactionDialog,
                  showOnlyTop: 10,
                ),
              if (_selectedTab == 1) AnalyticsView(transactions: _transactions),
            ],
          ),
        ),
      ),
    );
  }
}

class MonthlySpendsCard extends StatelessWidget {
  const MonthlySpendsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Monthly Spends',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: 0.5,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                Text(
                  '₹250',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  '+ ₹10,000',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '- ₹250',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionsAnalyticsTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  const TransactionsAnalyticsTabs({
    super.key,
    this.selectedIndex = 0,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onTabChanged(0),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selectedIndex == 0 ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, color: Colors.black54),
                  SizedBox(width: 8),
                  Text(
                    'Transactions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onTabChanged(1),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selectedIndex == 1 ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, color: Colors.black54),
                  SizedBox(width: 8),
                  Text(
                    'Analytics',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
