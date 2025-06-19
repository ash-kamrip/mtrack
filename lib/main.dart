import 'package:flutter/material.dart';
import 'widgets/transaction.dart';
import 'widgets/add_transaction_dialog.dart';
import 'widgets/recent_transactions_section.dart';
import 'screen/analytics_view.dart';
// --- sms related imports
import 'package:permission_handler/permission_handler.dart';
import 'widgets/sms_service.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:logger/logger.dart';
import 'widgets/transaction_helpers.dart';
// --- sms related imports - END
import 'screen/profile_screen.dart';

void main() {
  runApp(const MTrackApp());
}

class MTrackApp extends StatelessWidget {
  const MTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTrack',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      home: const HomeScreen(),
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

  void _editTransaction(Transaction oldTx, Transaction newTx) {
    setState(() {
      final idx = _smsTransactions.indexWhere(
        (t) =>
            t.dateTime == oldTx.dateTime &&
            t.amount == oldTx.amount &&
            t.description == oldTx.description &&
            t.category == oldTx.category &&
            t.type == oldTx.type,
      );
      if (idx != -1) {
        _smsTransactions[idx] = newTx;
      }
    });
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
    // add few manual transactions
    allTransactions.add(
      Transaction(
        amount: 100,
        dateTime: DateTime.now(),
        description: 'Manual Transaction',
        type: 'Debit',
        category: 'Food',
        source: 'Manual',
        excluded: false,
      ),
    );
    final currentMonthTxs = getCurrentMonthTransactions(allTransactions);
    final currentMonthDebits = getDebits(currentMonthTxs);
    final currentMonthCredits = getCredits(currentMonthTxs);
    final totalDebits = getDebits(currentMonthTxs);
    final colorScheme = Theme.of(context).colorScheme;

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
                const SizedBox(height: 20),
                RecentTransactionsSection(
                  transactions: latest10,
                  onAddTransaction: _showAddTransactionDialog,
                  onEditTransaction: _editTransaction,
                  showOnlyTop: 10,
                  titleTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  amountTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  verticalSpacing: 10,
                  buttonPadding: const EdgeInsets.symmetric(vertical: 10),
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
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.account_balance_wallet,
              color: colorScheme.primary,
            ),
          ),
        ),
        title: Text(
          'MTrack',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            color: colorScheme.primary,
            onPressed: () {},
            tooltip: 'Settings',
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        height: 70,
        backgroundColor: Colors.white,
        indicatorColor: Colors.green.shade50,
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
    final colorScheme = Theme.of(context).colorScheme;
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
                  'Monthly Spends',
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
                  child: CircularProgressIndicator(
                    value: totalDebits == 0
                        ? 0
                        : (currentMonthDebits / totalDebits).clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  '₹${currentMonthDebits.toInt()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
