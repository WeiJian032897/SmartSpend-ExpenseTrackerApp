import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/account_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';
import '../../utils/categories.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? expense; // For editing existing expense

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isIncome = false;
  String _selectedCategory = '';
  String _selectedSubCategory = '';
  String _selectedPaymentType = 'Cash';
  DateTime _selectedDate = DateTime.now();
  String _currency = 'RM';

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _initializeWithExistingExpense();
    } else {
      _selectedCategory = ExpenseCategories.categories.first.name;
      _selectedSubCategory = ExpenseCategories.categories.first.subCategories.first;
    }
  }

  void _initializeWithExistingExpense() {
    final expense = widget.expense!;
    _amountController.text = expense.amount.toString();
    _payeeController.text = expense.payee;
    _noteController.text = expense.note;
    _isIncome = expense.isIncome;
    _selectedCategory = expense.category;
    _selectedSubCategory = expense.subCategory;
    _selectedPaymentType = expense.paymentType;
    _selectedDate = expense.date;
    _currency = expense.currency;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _payeeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<ExpenseCategory> get _availableCategories =>
      _isIncome ? ExpenseCategories.incomeCategories : ExpenseCategories.categories;

  void _updateSubCategories() {
    final category = ExpenseCategories.getCategoryByName(_selectedCategory);
    if (category != null && category.subCategories.isNotEmpty) {
      _selectedSubCategory = category.subCategories.first;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(context, listen: false);

    if (authService.currentUser == null) {
      _showErrorDialog('User not authenticated');
      return;
    }

    // Get current account ID
    final currentAccount = accountProvider.currentAccount;
    if (currentAccount == null) {
      _showErrorDialog('No account selected. Please add an account first.');
      return;
    }

    final expense = ExpenseModel(
      id: _isEditing ? widget.expense!.id : '',
      userId: authService.currentUser!.uid,
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      subCategory: _selectedSubCategory,
      paymentType: _selectedPaymentType,
      payee: _payeeController.text.trim(),
      note: _noteController.text.trim(),
      date: _selectedDate,
      currency: _currency,
      isIncome: _isIncome,
    );

    bool success;
    if (_isEditing) {
      success = await expenseProvider.updateExpense(expense);
    } else {
      success = await expenseProvider.addExpense(expense, authService: authService, accountProvider: accountProvider);
    }

    if (success) {
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
              ? '${_isIncome ? "Income" : "Expense"} updated!' 
              : '${_isIncome ? "Income" : "Expense"} added!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } else {
      _showErrorDialog(expenseProvider.error ?? 'An error occurred');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear the error when user dismisses the dialog
              final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
              expenseProvider.clearError();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing 
          ? 'Edit ${_isIncome ? "Income" : "Expense"}' 
          : 'Add ${_isIncome ? "Income" : "Expense"}'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.red),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Income/Expense Toggle
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isIncome = false;
                              _selectedCategory = ExpenseCategories.categories.first.name;
                              _updateSubCategories();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isIncome ? AppColors.red : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'EXPENSE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: !_isIncome ? Colors.white : AppColors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isIncome = true;
                              _selectedCategory = ExpenseCategories.incomeCategories.first.name;
                              _updateSubCategories();
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isIncome ? AppColors.green : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'INCOME',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _isIncome ? Colors.white : AppColors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),


                  // Amount
                  const Text('Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _amountController,
                    hintText: '0.00',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    prefixText: '$_currency ',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Category
                  const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _availableCategories.map((category) {
                      return DropdownMenuItem(
                        value: category.name,
                        child: Row(
                          children: [
                            Icon(category.icon, color: category.color, size: 20),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                        _updateSubCategories();
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Sub Category
                  const Text('Sub Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSubCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: ExpenseCategories.getCategoryByName(_selectedCategory)?.subCategories
                        .map((subCategory) => DropdownMenuItem(
                              value: subCategory,
                              child: Text(subCategory),
                            ))
                        .toList() ?? [],
                    onChanged: (value) {
                      setState(() {
                        _selectedSubCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Payment Type
                  const Text('Payment Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedPaymentType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: ExpenseCategories.getPaymentTypes()
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Payee
                  const Text('Payee/From', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _payeeController,
                    hintText: _isIncome ? 'Income source' : 'Who did you pay?',
                  ),
                  const SizedBox(height: 20),

                  // Date
                  const Text('Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Note
                  const Text('Note (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _noteController,
                    hintText: 'Add a note...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  CustomButton(
                    text: _isEditing 
                      ? 'Update ${_isIncome ? "Income" : "Expense"}' 
                      : 'Add ${_isIncome ? "Income" : "Expense"}',
                    onPressed: expenseProvider.isLoading ? null : _saveExpense,
                    isLoading: expenseProvider.isLoading,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${widget.expense!.isIncome ? "Income" : "Expense"}'),
        content: Text('Are you sure you want to delete this ${widget.expense!.isIncome ? "income" : "expense"}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
              Navigator.pop(context);
              final success = await expenseProvider.deleteExpense(widget.expense!.id);
              if (success && mounted) {
                if (context.mounted) {
                  Navigator.pop(context, true); // Return true to indicate success
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.expense!.isIncome ? "Income" : "Expense"} deleted!'),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}