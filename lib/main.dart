import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mtrack/screen/all_transactions_screen.dart';
import 'widgets/transaction.dart';
import 'widgets/add_transaction_dialog.dart';
import 'widgets/recent_transactions_section.dart';
import 'screen/analytics_view.dart';
// --- sms related imports
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'widgets/transaction_helpers.dart';
// --- sms related imports - END
import 'screen/profile_screen.dart';
import 'services/settings_service.dart';
import 'services/transaction_storage_service.dart';
import 'services/sms_transaction_service.dart';
import 'services/edit_transaction_service.dart';

/// Main entry point of the MTrack application.
/// Initializes Hive and starts the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  await Hive.openBox<Transaction>('transactions');
  runApp(const MTrackApp());
}

/// Root widget of the MTrack application.
/// Sets up the theme and initial screen.
class MTrackApp extends StatelessWidget {
  const MTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTrack',
      theme: _buildAppTheme(),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  /// Builds the app's theme configuration
  ThemeData _buildAppTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.green,
      fontFamily: 'Inter',
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }
}

/// Main screen of the application with bottom navigation.
/// Handles all transaction management and UI state.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ==================== SERVICES ====================
  final Logger _logger = Logger();
  final SmsTransactionService _smsTransactionService = SmsTransactionService();

  // ==================== UI STATE ====================
  int _selectedTab = 0;
  double _monthlySpendLimit = 0;
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndSync();
  }

  // ==================== PERMISSIONS & DATA SYNC ====================

  /// Requests SMS permissions and syncs transaction data
  Future<void> _requestPermissionsAndSync() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      await _syncTransactionsFromSms();
    } else {
      _logger.w('SMS permission denied');
    }
  }

  /// Syncs transactions from SMS messages, handling first launch vs subsequent launches
  Future<void> _syncTransactionsFromSms() async {
    final isFirstLaunch = await TransactionStorageService.isEmpty();

    if (isFirstLaunch) {
      await _handleFirstLaunch();
    } else {
      await _handleSubsequentLaunch();
    }

    await _loadAndSortTransactions();
  }

  /// Handles the first launch by reading all SMS messages
  Future<void> _handleFirstLaunch() async {
    _logger.i('First launch: reading all SMS messages.');
    final smsTxs = await _smsTransactionService.getAllTransactionsFromSms();
    if (smsTxs.isNotEmpty) {
      await TransactionStorageService.addTransactions(smsTxs);
      await _updateLastProcessedTimestamp(smsTxs);
    }
  }

  /// Handles subsequent launches by reading only new SMS messages
  Future<void> _handleSubsequentLaunch() async {
    final lastTimestamp = await SettingsService.getLastProcessedSmsTimestamp();
    if (lastTimestamp != null) {
      _logger.i('Reading SMS since $lastTimestamp');
      final newSmsTxs = await _smsTransactionService
          .getTransactionsFromSmsSince(lastTimestamp);
      if (newSmsTxs.isNotEmpty) {
        await TransactionStorageService.addTransactions(newSmsTxs);
        await _updateLastProcessedTimestamp(newSmsTxs, lastTimestamp);
      }
    }
  }

  /// Updates the last processed SMS timestamp based on SMS transactions only
  Future<void> _updateLastProcessedTimestamp(
    List<Transaction> transactions, [
    DateTime? baseTimestamp,
  ]) async {
    final latestSms = transactions
        .where((t) => t.source == 'SMS')
        .map((t) => t.dateTime)
        .fold<DateTime?>(
          baseTimestamp,
          (prev, dt) => prev == null || dt.isAfter(prev) ? dt : prev,
        );

    if (latestSms != null &&
        (baseTimestamp == null || latestSms.isAfter(baseTimestamp))) {
      await SettingsService.setLastProcessedSmsTimestamp(latestSms);
    }
  }

  /// Loads all transactions from Hive and sorts them by date
  Future<void> _loadAndSortTransactions() async {
    _transactions = await TransactionStorageService.getAllTransactions();
    _transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    setState(() {});
  }

  // ==================== TRANSACTION MANAGEMENT ====================

  /// Shows dialog to add a new transaction
  void _showAddTransactionDialog() async {
    final Transaction? newTx = await showDialog<Transaction>(
      context: context,
      builder: (context) => AddTransactionDialog(),
    );
    if (newTx != null) {
      await TransactionStorageService.addTransaction(newTx);
      setState(() {
        _transactions.insert(0, newTx);
      });
    }
  }

  /// Edits an existing transaction
  void _editTransaction(Transaction oldTx, Transaction newTx) async {
    await EditTransactionService.editTransaction(oldTx, newTx);
    await _loadAndSortTransactions();
  }

  /// Deletes a transaction with confirmation dialog
  void _deleteTransaction(Transaction tx) async {
    final shouldDelete = await _showDeleteConfirmationDialog(tx);
    if (shouldDelete == true) {
      await EditTransactionService.deleteTransaction(tx);
      setState(() {
        _transactions.removeWhere((transaction) => transaction.key == tx.key);
      });
    }
  }

  /// Shows confirmation dialog for transaction deletion
  Future<bool?> _showDeleteConfirmationDialog(Transaction tx) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "${tx.description}"?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  // ==================== SPEND LIMIT MANAGEMENT ====================

  /// Shows dialog to set or update the monthly spend limit
  Future<void> _showSetSpendLimitDialog() async {
    final newLimit = await _showSpendLimitDialog();
    if (newLimit != null) {
      setState(() {
        _monthlySpendLimit = newLimit;
      });
    }
  }

  /// Shows the spend limit input dialog
  Future<double?> _showSpendLimitDialog() {
    return showDialog<double>(
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
  }

  // ==================== UI BUILDING ====================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final latest10 = _transactions.take(10).toList();
    final allTransactions = _getAllTransactionsWithManual();
    final monthlyData = _calculateMonthlyData(allTransactions);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(colorScheme),
      body: _buildBody(latest10, allTransactions, monthlyData),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Gets all transactions including the manual test transaction
  List<Transaction> _getAllTransactionsWithManual() {
    final allTransactions = [..._transactions];
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
    return allTransactions;
  }

  /// Calculates monthly transaction data
  Map<String, double> _calculateMonthlyData(List<Transaction> allTransactions) {
    final currentMonthTxs = getCurrentMonthTransactions(allTransactions);
    return {
      'debits': getDebits(currentMonthTxs),
      'credits': getCredits(currentMonthTxs),
    };
  }

  /// Builds the app bar
  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.account_balance_wallet, color: colorScheme.primary),
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
    );
  }

  /// Builds the main body content based on selected tab
  Widget _buildBody(
    List<Transaction> latest10,
    List<Transaction> allTransactions,
    Map<String, double> monthlyData,
  ) {
    switch (_selectedTab) {
      case 0:
        return _buildHomeTab(latest10, monthlyData);
      case 1:
        return _buildAnalyticsTab(allTransactions);
      case 2:
        return AllTransactionsScreen(
          transactions: allTransactions,
          onEditTransaction: _editTransaction,
          onDeleteTransaction: _deleteTransaction,
        );
      case 3:
        return const ProfileScreen();
      default:
        return Container();
    }
  }

  /// Builds the home tab content
  Widget _buildHomeTab(
    List<Transaction> latest10,
    Map<String, double> monthlyData,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MonthlySpendsCard(
              currentMonthDebits: monthlyData['debits']!,
              currentMonthCredits: monthlyData['credits']!,
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
              onDeleteTransaction: _deleteTransaction,
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
  }

  /// Builds the analytics tab content
  Widget _buildAnalyticsTab(List<Transaction> allTransactions) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnalyticsView(transactions: allTransactions),
      ),
    );
  }

  /// Builds the bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return NavigationBar(
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
