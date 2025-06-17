import 'package:flutter/material.dart';
import 'widgets/transaction.dart';
import 'widgets/add_transaction_dialog.dart';
import 'widgets/recent_transactions_section.dart';
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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'User Profile',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
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

  void _onBottomNavChanged(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonthDebits = _transactions
        .where(
          (tx) =>
              tx.type == 'Debit' &&
              tx.dateTime.month == now.month &&
              tx.dateTime.year == now.year,
        )
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final currentMonthCredits = _transactions
        .where(
          (tx) =>
              tx.type == 'Credit' &&
              tx.dateTime.month == now.month &&
              tx.dateTime.year == now.year,
        )
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final totalDebits = _transactions
        .where((tx) => tx.type == 'Debit')
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    Widget body;
    switch (_selectedTab) {
      case 0:
        body = SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                MonthlySpendsCard(
                  currentMonthDebits: currentMonthDebits,
                  totalDebits: totalDebits,
                  currentMonthCredits: currentMonthCredits,
                ),
                SizedBox(height: 20),
                RecentTransactionsSection(
                  transactions: _transactions,
                  onAddTransaction: _showAddTransactionDialog,
                  showOnlyTop: 10,
                ),
              ],
            ),
          ),
        );
        break;
      case 1:
        body = SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnalyticsView(transactions: _transactions),
          ),
        );
        break;
      case 2:
        body = AllTransactionsScreen(transactions: _transactions);
        break;
      case 3:
        body = const ProfileScreen();
        break;
      default:
        body = Container();
    }
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
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: _onBottomNavChanged,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class MonthlySpendsCard extends StatelessWidget {
  final double currentMonthDebits;
  final double totalDebits;
  final double currentMonthCredits;
  const MonthlySpendsCard({
    super.key,
    required this.currentMonthDebits,
    required this.totalDebits,
    required this.currentMonthCredits,
  });

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
                    value: totalDebits == 0
                        ? 0
                        : (currentMonthDebits / totalDebits).clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                Text(
                  '₹${currentMonthDebits.toInt()}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  '+ ₹${currentMonthCredits.toInt()}',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '- ₹${currentMonthDebits.toInt()}',
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
