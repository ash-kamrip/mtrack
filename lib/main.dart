import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  await Hive.openBox<Transaction>('transactions');
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
  double _monthlySpendLimit = 0; // Default spend limit
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

  Future<void> _showSetSpendLimitDialog() async {
    final newLimit = await showDialog<double>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
          text: _monthlySpendLimit > 0
              ? _monthlySpendLimit.toStringAsFixed(0)
              : '',
        );
        return AlertDialog(
          title: const Text('Set Monthly Spend Limit'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: '₹',
              labelText: 'Limit',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Unset'),
              onPressed: () => Navigator.of(context).pop(0.0),
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null && value > 0) {
                  Navigator.of(context).pop(value);
                }
              },
            ),
          ],
        );
      },
    );

    if (newLimit != null) {
      setState(() {
        _monthlySpendLimit = newLimit;
      });
    }
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
                  currentMonthCredits: currentMonthCredits,
                  monthlySpendLimit: _monthlySpendLimit,
                ),
                const SizedBox(height: 8),
                SpendLimitCard(
                  limit: _monthlySpendLimit,
                  onSetLimit: _showSetSpendLimitDialog,
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
  final double currentMonthCredits;
  final double monthlySpendLimit;
  // constructor
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
