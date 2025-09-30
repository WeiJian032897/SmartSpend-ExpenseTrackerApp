import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../utils/colors.dart';
import '../../utils/categories.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String _selectedFilter = 'All';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedCategory = 'All';
  double? _minAmount;
  double? _maxAmount;
  String _searchQuery = '';
  String _selectedDatePreset = 'Last 30 days';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
    });
  }

  List<ExpenseModel> _getFilteredExpenses(List<ExpenseModel> expenses) {
    // Use all expenses (single account system)
    List<ExpenseModel> filtered = expenses;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((expense) {
        return expense.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               expense.payee.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               expense.note.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by date range
    filtered = filtered.where((expense) {
      return expense.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             expense.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    // Filter by type
    if (_selectedFilter == 'Income') {
      filtered = filtered.where((expense) => expense.isIncome).toList();
    } else if (_selectedFilter == 'Expenses') {
      filtered = filtered.where((expense) => !expense.isIncome).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((expense) => expense.category == _selectedCategory).toList();
    }

    // Filter by amount range
    if (_minAmount != null) {
      filtered = filtered.where((expense) => expense.amount >= _minAmount!).toList();
    }
    if (_maxAmount != null) {
      filtered = filtered.where((expense) => expense.amount <= _maxAmount!).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          if (expenseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (expenseProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading transactions',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expenseProvider.error!,
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => expenseProvider.loadExpenses(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final filteredExpenses = _getFilteredExpenses(expenseProvider.expenses);

          if (filteredExpenses.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Income',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RM ${_getTotalIncome(filteredExpenses).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Expenses',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RM ${_getTotalExpenses(filteredExpenses).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Balance',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RM ${(_getTotalIncome(filteredExpenses) - _getTotalExpenses(filteredExpenses)).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: (_getTotalIncome(filteredExpenses) - _getTotalExpenses(filteredExpenses)) >= 0
                                  ? AppColors.green
                                  : AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Active Filters Info
              if (_hasActiveFilters())
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 16, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getActiveFiltersText(),
                          style: TextStyle(color: AppColors.primaryBlue, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearAllFilters,
                        child: Text('Clear', style: TextStyle(color: AppColors.primaryBlue)),
                      ),
                    ],
                  ),
                ),
              
              // Filter Chips
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Type filters
                    ...['All', 'Income', 'Expenses'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                        ),
                      );
                    }),
                    // Date preset filters
                    ...['Last 7 days', 'Last 30 days', 'This month', 'Custom'].map((preset) {
                      final isSelected = _selectedDatePreset == preset;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(preset),
                          selected: isSelected,
                          selectedColor: AppColors.green.withValues(alpha: 0.2),
                          onSelected: (selected) {
                            if (selected) {
                              _applyDatePreset(preset);
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Transaction List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = filteredExpenses[index];
                    return ExpenseListItem(
                      expense: expense,
                      onTap: () => _editExpense(expense),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or add a new transaction',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _getTotalIncome(List<ExpenseModel> expenses) {
    return expenses
        .where((expense) => expense.isIncome)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double _getTotalExpenses(List<ExpenseModel> expenses) {
    return expenses
        .where((expense) => !expense.isIncome)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  void _editExpense(ExpenseModel expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(expense: expense),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterDialog(
        selectedCategory: _selectedCategory,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (category, minAmt, maxAmt, start, end) {
          setState(() {
            _selectedCategory = category;
            _minAmount = minAmt;
            _maxAmount = maxAmt;
            _startDate = start;
            _endDate = end;
            _selectedDatePreset = 'Custom';
          });
        },
        onClearAll: () {
          _clearAllFilters();
        },
      ),
    );
  }


  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Transactions'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by category, payee, or notes...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _applyDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _selectedDatePreset = preset;
      switch (preset) {
        case 'Last 7 days':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'Last 30 days':
          _startDate = now.subtract(const Duration(days: 30));
          _endDate = now;
          break;
        case 'This month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'Custom':
          // Keep current dates
          break;
      }
    });
  }

  bool _hasActiveFilters() {
    return _selectedFilter != 'All' ||
           _selectedCategory != 'All' ||
           _minAmount != null ||
           _maxAmount != null ||
           _searchQuery.isNotEmpty ||
           _selectedDatePreset != 'Last 30 days';
  }

  String _getActiveFiltersText() {
    List<String> filters = [];
    if (_selectedFilter != 'All') filters.add(_selectedFilter);
    if (_selectedCategory != 'All') filters.add(_selectedCategory);
    if (_searchQuery.isNotEmpty) filters.add('"$_searchQuery"');
    if (_minAmount != null || _maxAmount != null) {
      String amountFilter = 'Amount: ';
      if (_minAmount != null) amountFilter += 'RM${_minAmount!.toStringAsFixed(0)}+';
      if (_maxAmount != null) {
        if (_minAmount != null) amountFilter += ' - ';
        amountFilter += 'RM${_maxAmount!.toStringAsFixed(0)}';
      }
      filters.add(amountFilter);
    }
    if (_selectedDatePreset != 'Last 30 days') filters.add(_selectedDatePreset);
    
    return filters.isEmpty ? 'No active filters' : 'Active: ${filters.join(', ')}';
  }

  void _clearAllFilters() {
    setState(() {
      _selectedFilter = 'All';
      _selectedCategory = 'All';
      _minAmount = null;
      _maxAmount = null;
      _searchQuery = '';
      _selectedDatePreset = 'Last 30 days';
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class FilterDialog extends StatefulWidget {
  final String selectedCategory;
  final double? minAmount;
  final double? maxAmount;
  final DateTime startDate;
  final DateTime endDate;
  final Function(String category, double? minAmt, double? maxAmt, DateTime start, DateTime end) onApply;
  final VoidCallback onClearAll;

  const FilterDialog({
    super.key,
    required this.selectedCategory,
    required this.minAmount,
    required this.maxAmount,
    required this.startDate,
    required this.endDate,
    required this.onApply,
    required this.onClearAll,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late String _selectedCategory;
  late double? _minAmount;
  late double? _maxAmount;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _minAmount = widget.minAmount;
    _maxAmount = widget.maxAmount;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Advanced Filters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Filter
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Consumer<ExpenseProvider>(builder: (context, provider, child) {
                    final categories = ['All', ...provider.expenses.map((e) => e.category).toSet()];
                    return Wrap(
                      spacing: 8,
                      children: categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return FilterChip(
                          label: Text(category, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        );
                      }).toList(),
                    );
                  }),
                  const SizedBox(height: 20),
                  
                  // Amount Range
                  const Text('Amount Range (RM)', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Min Amount',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                          initialValue: _minAmount?.toString() ?? '',
                          onChanged: (value) {
                            _minAmount = double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Max Amount',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                          initialValue: _maxAmount?.toString() ?? '',
                          onChanged: (value) {
                            _maxAmount = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Date Range
                  const Text('Custom Date Range', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('From Date', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _selectStartDate(),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('To Date', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _selectEndDate(),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onClearAll();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_selectedCategory, _minAmount, _maxAmount, _startDate, _endDate);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }
}

class ExpenseListItem extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onTap;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = ExpenseCategories.getCategoryByName(expense.category);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (category?.color ?? AppColors.grey).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            category?.icon ?? Icons.category,
            color: category?.color ?? AppColors.grey,
          ),
        ),
        title: Text(
          expense.category,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expense.payee.isNotEmpty)
              Text(expense.payee),
            Text(
              '${expense.date.day}/${expense.date.month}/${expense.date.year} • ${expense.paymentType}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (expense.note.isNotEmpty)
              Text(
                expense.note,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Text(
          '${expense.isIncome ? '+' : '-'}RM${expense.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: expense.isIncome ? AppColors.green : AppColors.red,
          ),
        ),
      ),
    );
  }
}