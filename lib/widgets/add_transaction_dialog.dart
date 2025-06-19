import 'package:flutter/material.dart';
import 'transaction.dart';

class AddTransactionDialog extends StatefulWidget {
  final Transaction? initialTransaction;
  final bool isEdit;
  const AddTransactionDialog({
    super.key,
    this.initialTransaction,
    this.isEdit = false,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  late String _type;
  late double _amount;
  late String _description;
  late String _category;
  final _formKey = GlobalKey<FormState>();
  final List<String> _categories = [
    'Food',
    'Shopping',
    'Bills',
    'Travel',
    'Salary',
    'Transport',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTransaction != null) {
      _type = widget.initialTransaction!.type;
      _amount = widget.initialTransaction!.amount;
      _description = widget.initialTransaction!.description;
      _category = widget.initialTransaction!.category;
    } else {
      _type = 'Debit';
      _amount = 0.0;
      _description = '';
      _category = '';
    }
  }

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
                    Expanded(
                      child: Text(
                        widget.isEdit
                            ? 'Edit Transaction'
                            : 'Add New Transaction',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
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
                        initialValue: _amount != 0.0 ? _amount.toString() : '',
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount (₹)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter amount';
                          if (double.tryParse(val) == null) {
                            return 'Invalid number';
                          }
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
                  initialValue: _description,
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
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Select a category';
                    return null;
                  },
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
                              dateTime:
                                  widget.isEdit &&
                                      widget.initialTransaction != null
                                  ? widget.initialTransaction!.dateTime
                                  : DateTime.now(),
                            ),
                          );
                        }
                      },
                      child: Text(
                        widget.isEdit ? 'Save Changes' : 'Add Transaction',
                      ),
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
