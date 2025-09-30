import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/expense_provider.dart';
import '../../utils/colors.dart';
import '../../models/expense_model.dart';
import '../../l10n/app_localizations.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  int _selectedTabIndex = 0;
  int _touchedIndex = -1;
  String _hoveredCategory = '';
  double _hoveredAmount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.charts ?? 'Charts'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          final expenses = expenseProvider.expenses;
          final incomeList = expenses.where((e) => e.isIncome).toList();
          final expenseList = expenses.where((e) => !e.isIncome).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Tab selector
                _buildTabSelector(),
                const SizedBox(height: 30),
                
                // Chart content
                if (_selectedTabIndex == 0) 
                  _buildIncomeChart(incomeList)
                else 
                  _buildExpenseChart(expenseList),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedTabIndex = 0;
                _touchedIndex = -1;
                _hoveredCategory = '';
                _hoveredAmount = 0;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? AppColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppLocalizations.of(context)?.income ?? 'Income',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTabIndex == 0 ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedTabIndex = 1;
                _touchedIndex = -1;
                _hoveredCategory = '';
                _hoveredAmount = 0;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? Colors.red : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppLocalizations.of(context)?.expenses ?? 'Expenses',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTabIndex == 1 ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeChart(List<ExpenseModel> incomeList) {
    if (incomeList.isEmpty) {
      return _buildEmptyState(
        AppLocalizations.of(context)?.noIncomeData ?? 'No Income Data',
        AppLocalizations.of(context)?.needToAddIncome ?? 'You need to add your income before you can see the pie chart 😊',
        Icons.trending_up,
        AppColors.green,
      );
    }

    final incomeByCategory = _groupByCategory(incomeList);
    final chartData = _generateChartData(incomeByCategory, _getIncomeColors());

    return Column(
      children: [
        // Chart title and total
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.green.withValues(alpha: 0.1), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, color: AppColors.green, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Total Income',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'RM ${_calculateTotal(incomeList).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        
        // Pie chart with hover info
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  sections: _generateInteractiveChartData(incomeByCategory, _getIncomeColors(), true),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (pieTouchResponse?.touchedSection?.touchedSectionIndex != null) {
                          _touchedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                          final sortedEntries = incomeByCategory.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                          if (_touchedIndex < sortedEntries.length) {
                            final entry = sortedEntries[_touchedIndex];
                            _hoveredCategory = entry.key;
                            _hoveredAmount = entry.value;
                          }
                        } else {
                          _touchedIndex = -1;
                          _hoveredCategory = '';
                          _hoveredAmount = 0;
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            // Hover information display
            if (_touchedIndex != -1)
              _buildHoverInfo(true),
          ],
        ),
        const SizedBox(height: 30),
        
        // Legend
        _buildLegend(incomeByCategory, _getIncomeColors()),
      ],
    );
  }

  Widget _buildExpenseChart(List<ExpenseModel> expenseList) {
    if (expenseList.isEmpty) {
      return _buildEmptyState(
        AppLocalizations.of(context)?.noExpenseData ?? 'No Expense Data',
        AppLocalizations.of(context)?.needToAddExpenses ?? 'You need to add your expenses before you can see the pie chart 😊',
        Icons.trending_down,
        Colors.red,
      );
    }

    final expensesByCategory = _groupByCategory(expenseList);
    final chartData = _generateChartData(expensesByCategory, _getExpenseColors());

    return Column(
      children: [
        // Chart title and total
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.withValues(alpha: 0.1), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_down, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Total Expenses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'RM ${_calculateTotal(expenseList).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        
        // Pie chart with hover info
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  sections: _generateInteractiveChartData(expensesByCategory, _getExpenseColors(), false),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (pieTouchResponse?.touchedSection?.touchedSectionIndex != null) {
                          _touchedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                          final sortedEntries = expensesByCategory.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                          if (_touchedIndex < sortedEntries.length) {
                            final entry = sortedEntries[_touchedIndex];
                            _hoveredCategory = entry.key;
                            _hoveredAmount = entry.value;
                          }
                        } else {
                          _touchedIndex = -1;
                          _hoveredCategory = '';
                          _hoveredAmount = 0;
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            // Hover information display
            if (_touchedIndex != -1)
              _buildHoverInfo(false),
          ],
        ),
        const SizedBox(height: 30),
        
        // Legend
        _buildLegend(expensesByCategory, _getExpenseColors()),
      ],
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: color,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              AppLocalizations.of(context)?.startByAddingTransactions ?? 'Start by adding some transactions!',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Map<String, double> categoryData, List<Color> colors) {
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Breakdown by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final categoryEntry = entry.value;
            final category = categoryEntry.key;
            final amount = categoryEntry.value;
            final percentage = (amount / _calculateTotalFromMap(categoryData) * 100);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'RM ${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Map<String, double> _groupByCategory(List<ExpenseModel> transactions) {
    final Map<String, double> categoryTotals = {};
    for (final transaction in transactions) {
      final category = transaction.category.isEmpty ? (AppLocalizations.of(context)?.other ?? 'Other') : transaction.category;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount;
    }
    return categoryTotals;
  }

  List<PieChartSectionData> _generateChartData(Map<String, double> categoryData, List<Color> colors) {
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final total = _calculateTotalFromMap(categoryData);
    
    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final categoryEntry = entry.value;
      final percentage = (categoryEntry.value / total * 100);
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: categoryEntry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _generateInteractiveChartData(Map<String, double> categoryData, List<Color> colors, bool isIncome) {
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final total = _calculateTotalFromMap(categoryData);
    
    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final categoryEntry = entry.value;
      final percentage = (categoryEntry.value / total * 100);
      final isTouched = index == _touchedIndex;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: categoryEntry.value,
        title: isTouched ? '' : '${percentage.toStringAsFixed(1)}%',
        radius: isTouched ? 110 : 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildHoverInfo(bool isIncome) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isIncome ? AppColors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isIncome ? AppColors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _hoveredCategory,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'RM ${_hoveredAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isIncome ? AppColors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Consumer<ExpenseProvider>(
            builder: (context, expenseProvider, child) {
              final expenses = expenseProvider.expenses;
              final relevantTransactions = isIncome 
                  ? expenses.where((e) => e.isIncome).toList()
                  : expenses.where((e) => !e.isIncome).toList();
              final total = _calculateTotal(relevantTransactions);
              final percentage = total > 0 ? (_hoveredAmount / total * 100) : 0.0;
              
              return Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  double _calculateTotal(List<ExpenseModel> transactions) {
    return transactions.fold(0, (sum, transaction) => sum + transaction.amount);
  }

  double _calculateTotalFromMap(Map<String, double> categoryData) {
    return categoryData.values.fold(0, (sum, amount) => sum + amount);
  }

  List<Color> _getIncomeColors() {
    return [
      AppColors.green,
      AppColors.green.withValues(alpha: 0.8),
      AppColors.green.withValues(alpha: 0.6),
      AppColors.lightBlue,
      AppColors.primaryBlue,
      Colors.teal,
      Colors.cyan,
      Colors.indigo,
    ];
  }

  List<Color> _getExpenseColors() {
    return [
      Colors.red,
      AppColors.orange,
      AppColors.yellow,
      Colors.purple,
      Colors.pink,
      Colors.deepOrange,
      Colors.amber,
      Colors.brown,
    ];
  }
}