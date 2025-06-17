import 'package:flutter/material.dart';
import 'widgets/transaction.dart';
import 'widgets/add_transaction_dialog.dart';
import 'widgets/recent_transactions_section.dart';
import 'widgets/analytics_view.dart';
// --- sms related imports
import 'package:permission_handler/permission_handler.dart';
import 'widgets/sms_service.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:logger/logger.dart';
import 'widgets/transaction_helpers.dart';
// --- sms related imports - END

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
  // --- SMS related variables ---
  List<SmsMessage> messages = [];
  final SmsService _smsService = SmsService();
  List<Transaction> _smsTransactions = [];
  final Logger _logger = Logger();
  // --- END SMS related variables ---

  // --- UI State ---
  int _selectedTab = 0;
  // --- END UI State ---

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  // --- SMS and Permissions Logic ---
  Future<void> _requestPermissions() async {
    var status = await Permission.sms.request();
    if (status.isGranted) {
      _readMessages();
    } else {
      _logger.w('Permission denied');
    }
  }

  Future<void> _readMessages() async {
    messages = await _smsService.readMessages();
    _smsTransactions = _smsService.parseTransactionsFromMessages(messages);
    // Log the first 5 messages for debugging
    for (var i = 0; i < (messages.length < 5 ? messages.length : 5); i++) {
      final msg = messages[i];
      _logger.i(
        'SMS #$i: address=${msg.address}, date=${msg.date}, body=${msg.body}',
      );
    }
    setState(() {});
  }
  // --- END SMS and Permissions Logic ---

  void _showAddTransactionDialog() async {
    final Transaction? newTx = await showDialog<Transaction>(
      context: context,
      builder: (context) => AddTransactionDialog(),
    );
    if (newTx != null) {
      setState(() {
        _smsTransactions.insert(0, newTx);
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
    final allTransactions = [..._smsTransactions]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final latest10 = getLatestTransactions(allTransactions, count: 10);
    final currentMonthTxs = getCurrentMonthTransactions(allTransactions);
    final currentMonthDebits = getDebits(currentMonthTxs);
    final currentMonthCredits = getCredits(currentMonthTxs);
    final totalDebits = getDebits(currentMonthTxs);

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
                  transactions: latest10,
                  onAddTransaction: _showAddTransactionDialog,
                  showOnlyTop: 10,
                ),
              ],
            ),
          ),
        );
        break;
      case 1:
        // TODO: Fix AnalyticsView to support user-selected time periods
        body = SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnalyticsView(transactions: allTransactions),
          ),
        );
        break;
      case 2:
        body = AllTransactionsScreen(transactions: allTransactions);
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
