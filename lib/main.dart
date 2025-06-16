import 'package:flutter/material.dart';

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

class Transaction {
  final String type; // 'Debit' or 'Credit'
  final double amount;
  final String description;
  final String category;
  final String source;
  final DateTime dateTime;

  Transaction({
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.source,
    required this.dateTime,
  });
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
              MonthlySpendsCard(),
              SizedBox(height: 20),
              TransactionsAnalyticsTabs(),
              SizedBox(height: 20),
              RecentTransactionsSection(
                transactions: _transactions,
                onAddTransaction: _showAddTransactionDialog,
              ),
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

class TransactionsAnalyticsTabs extends StatefulWidget {
  const TransactionsAnalyticsTabs({super.key});

  @override
  _TransactionsAnalyticsTabsState createState() =>
      _TransactionsAnalyticsTabsState();
}

class _TransactionsAnalyticsTabsState extends State<TransactionsAnalyticsTabs> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedIndex = 0),
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
            onTap: () => setState(() => selectedIndex = 1),
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

class RecentTransactionsSection extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onAddTransaction;
  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.black54),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recent Transactions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: onAddTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '+ Add Transaction',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...transactions.asMap().entries.map((entry) {
              final tx = entry.value;
              return Column(
                children: [
                  TransactionItem(
                    isIncome: tx.type == 'Credit',
                    title: tx.description,
                    time: TimeOfDay.fromDateTime(tx.dateTime).format(context),
                    amount: tx.amount.toInt(),
                    date: '',
                    label: tx.category,
                  ),
                  if (entry.key != transactions.length - 1) Divider(),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final bool isIncome;
  final String title;
  final String time;
  final int amount;
  final String date;
  final String label;

  const TransactionItem({
    super.key,
    required this.isIncome,
    required this.title,
    required this.time,
    required this.amount,
    required this.date,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  Text(time, style: TextStyle(color: Colors.grey)),
                  if (label.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Text(
          (isIncome ? '+₹' : '-₹') + amount.toString(),
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class AddTransactionDialog extends StatefulWidget {
  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  String _type = 'Debit';
  double _amount = 0.0;
  String _description = '';
  String _category = '';
  final _formKey = GlobalKey<FormState>();
  final List<String> _categories = [
    'Food',
    'Shopping',
    'Bills',
    'Travel',
    'Salary',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add New Transaction',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Debit', 'Credit']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _type = val ?? 'Debit'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount (₹)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter amount';
                          if (double.tryParse(val) == null)
                            return 'Invalid number';
                          return null;
                        },
                        onSaved: (val) =>
                            _amount = double.tryParse(val ?? '0') ?? 0.0,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter transaction description',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (val) => _description = val ?? '',
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category.isEmpty ? null : _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _category = val ?? ''),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Source: Manual',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _formKey.currentState?.save();
                          Navigator.of(context).pop(
                            Transaction(
                              type: _type,
                              amount: _amount,
                              description: _description,
                              category: _category,
                              source: 'Manual',
                              dateTime: DateTime.now(),
                            ),
                          );
                        }
                      },
                      child: Text('Add Transaction'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
