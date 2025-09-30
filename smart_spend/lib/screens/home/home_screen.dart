import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../utils/colors.dart';
import '../../widgets/bottom_navigation.dart';
import '../statistics/statistics_screen.dart';
import '../charts/charts_screen.dart';
import '../ai/ai_screen.dart';
import '../planning/planning_screen.dart';
import '../settings/settings_screen.dart';
import '../expense/add_expense_screen.dart';
import '../expense/expense_list_screen.dart';
import 'add_account_screen.dart';
import '../../providers/expense_provider.dart';
import '../../providers/account_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/categories.dart';
import '../../models/account_model.dart';
import '../auth/login_screen.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  
  const HomeScreen({super.key, this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _authCheckTimer;
  
  List<Widget> get _screens => [
    const HomeContent(),
    const StatisticsScreen(),
    const ChartsScreen(),
    const AIScreen(),
    const PlanningScreen(),
    SettingsScreen(onLogout: widget.onLogout),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPeriodicAuthCheck();
  }

  @override
  void dispose() {
    _authCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App became active, validate auth state
      _validateAuthOnResume();
    }
  }

  Future<void> _validateAuthOnResume() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isValid = await authService.validateAuthState();
    
    if (!isValid && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.sessionExpired ?? 'Session expired. Please sign in again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _startPeriodicAuthCheck() {
    // Check auth state every 5 minutes
    _authCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final isValid = await authService.validateAuthState();
      if (!isValid && mounted) {
        // Auth state is invalid, redirect to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.sessionExpired ?? 'Session expired. Please sign in again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: (_currentIndex == 2 || _currentIndex == 3 || _currentIndex == 4) ? null : FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  int _selectedWeekOffset = 0; // 0 = current week, -1 = last week, etc.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.currentUser != null) {
      Provider.of<ExpenseProvider>(context, listen: false).loadExpenses(authService: authService);
      Provider.of<AccountProvider>(context, listen: false).loadAccounts(authService: authService);
    }
  }

  String _getWeekLabel() {
    if (_selectedWeekOffset == 0) {
      return AppLocalizations.of(context)?.thisWeek ?? 'This Week';
    } else if (_selectedWeekOffset == -1) {
      return AppLocalizations.of(context)?.lastWeek ?? 'Last Week';
    } else {
      return AppLocalizations.of(context)?.weeksAgo(-_selectedWeekOffset) ?? '${(-_selectedWeekOffset)} Weeks Ago';
    }
  }

  void _showWeekSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.selectWeek ?? 'Select Week'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 4, // Show current week + 3 past weeks
            itemBuilder: (context, index) {
              final weekOffset = -index; // 0, -1, -2, -3 range (current to 3 weeks ago)
              final isSelected = weekOffset == _selectedWeekOffset;
              
              return ListTile(
                title: Text(_getWeekLabelForOffset(weekOffset)),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedWeekOffset = weekOffset;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
        ],
      ),
    );
  }

  String _getWeekLabelForOffset(int offset) {
    if (offset == 0) {
      return 'This Week';
    } else if (offset == -1) {
      return 'Last Week';
    } else if (offset == -2) {
      return '2 Weeks Ago';
    } else if (offset == -3) {
      return '3 Weeks Ago';
    } else {
      return '${(-offset)} Week${(-offset) > 1 ? 's' : ''} Ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Consumer2<ExpenseProvider, AccountProvider>(
          builder: (context, expenseProvider, accountProvider, child) {
            if (expenseProvider.isLoading || accountProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (expenseProvider.error != null || accountProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.errorLoadingData ?? 'Error loading data',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      expenseProvider.error ?? accountProvider.error ?? (AppLocalizations.of(context)?.unknownError ?? 'Unknown error'),
                      style: TextStyle(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        expenseProvider.clearError();
                        accountProvider.clearError();
                        expenseProvider.loadExpenses();
                        accountProvider.loadAccounts();
                      },
                      child: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Account Display
                  _buildAccountDisplay(accountProvider),
            
            // Expense Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)?.expend ?? 'Expend',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showWeekSelector(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getWeekLabel()),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Weekly Chart - Improved Design
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_getWeekLabel()} Spending',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'RM ${_getWeekTotal(expenseProvider).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxDailyExpense(expenseProvider),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => Colors.black87,
                            tooltipRoundedRadius: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              return BarTooltipItem(
                                '${days[group.x.toInt()]}\nRM ${rod.toY.toStringAsFixed(2)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('');
                                return Text(
                                  'RM${value.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                final today = DateTime.now().weekday - 1;
                                final isCurrentWeek = _selectedWeekOffset == 0;
                                final isToday = isCurrentWeek && value.toInt() == today;
                                
                                return Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    days[value.toInt() % 7],
                                    style: TextStyle(
                                      color: isToday ? AppColors.primaryBlue : Colors.grey.shade600,
                                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _getMaxDailyExpense(expenseProvider) / 4,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        barGroups: _getWeeklyBarData(expenseProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildWeeklyInsights(expenseProvider),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
                // Top Expenses
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)?.topExpenses ?? 'Top Expenses',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppLocalizations.of(context)?.viewAll ?? 'View All'),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 20),
            
                // Expense List
                SizedBox(
                  height: 300, // Fixed height for the expense list
                  child: _buildExpensesList(expenseProvider.expensesByCategory),
                ),
                const SizedBox(height: 20), // Add bottom spacing
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountDisplay(AccountProvider accountProvider) {
    if (accountProvider.accounts.isEmpty) {
      return _buildEmptyAccountCard();
    }

    final currentAccount = accountProvider.currentAccount!;
    
    return _buildAccountCard(currentAccount);
  }

  Widget _buildEmptyAccountCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.1),
            AppColors.lightBlue.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)?.noAccountSetup ?? 'No Account Setup',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.createFirstAccount ?? 'Create your first account to start\ntracking your expenses',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.lightBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddAccountScreen()),
                );
                if (result == true) {
                  _loadData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)?.createAccount ?? 'Create Account',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AccountModel currentAccount) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddAccountScreen()),
        );
        if (result == true) {
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)?.currentAccount ?? 'Current Account',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentAccount.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.availableBalance ?? 'Available Balance',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${currentAccount.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.tapToSwitch ?? 'Tap to switch',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(Map<String, double> expensesByCategory) {
    if (expensesByCategory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.noExpensesYet ?? 'No expenses yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.tapToAddExpense ?? 'Tap the + button to add your first expense',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort categories by amount (highest first)
    final sortedEntries = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxAmount = sortedEntries.isNotEmpty ? sortedEntries.first.value : 1.0;

    return ListView.separated(
      itemCount: sortedEntries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 15),
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final category = ExpenseCategories.getCategoryByName(entry.key);
        
        return ExpenseItem(
          title: entry.key,
          amount: 'RM${entry.value.toStringAsFixed(2)}',
          color: category?.color ?? AppColors.grey,
          percentage: entry.value / maxAmount,
        );
      },
    );
  }

  List<FlSpot> _getWeeklyExpenseData(ExpenseProvider provider) {
    // Get the start of selected week (Monday) at midnight
    final now = DateTime.now();
    final currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final startOfWeek = currentWeekStart.add(Duration(days: _selectedWeekOffset * 7));
    
    // Initialize daily totals for the week
    List<double> dailyTotals = List.filled(7, 0.0);
    
    // Calculate expenses for each day of the current week
    for (var expense in provider.expenses) {
      if (!expense.isIncome) {
        // Compare dates only (ignore time)
        final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
        final daysDiff = expenseDate.difference(startOfWeek).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          dailyTotals[daysDiff] += expense.amount;
        }
      }
    }
    
    // Convert to FlSpot list
    return List.generate(7, (index) => FlSpot(index.toDouble(), dailyTotals[index]));
  }

  List<BarChartGroupData> _getWeeklyBarData(ExpenseProvider provider) {
    // Get the start of selected week (Monday) at midnight
    final now = DateTime.now();
    final currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final startOfWeek = currentWeekStart.add(Duration(days: _selectedWeekOffset * 7));
    
    // Initialize daily totals for the week
    List<double> dailyTotals = List.filled(7, 0.0);
    
    // Calculate expenses for each day of the selected week
    for (var expense in provider.expenses) {
      if (!expense.isIncome) {
        // Compare dates only (ignore time)
        final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
        final daysDiff = expenseDate.difference(startOfWeek).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          dailyTotals[daysDiff] += expense.amount;
        }
      }
    }
    
    // Only highlight today if we're viewing the current week
    final today = DateTime.now().weekday - 1;
    final isCurrentWeek = _selectedWeekOffset == 0;
    
    return List.generate(7, (index) {
      final isToday = isCurrentWeek && index == today;
      final hasExpenses = dailyTotals[index] > 0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dailyTotals[index],
            color: isToday 
                ? AppColors.primaryBlue
                : hasExpenses 
                    ? AppColors.primaryBlue.withOpacity(0.7)
                    : AppColors.lightGrey,
            width: 24,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            gradient: isToday ? LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppColors.primaryBlue, AppColors.lightBlue],
            ) : null,
          ),
        ],
      );
    });
  }

  double _getMaxDailyExpense(ExpenseProvider provider) {
    final spots = _getWeeklyExpenseData(provider);
    final maxValue = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return maxValue > 0 ? maxValue * 1.2 : 100; // Add 20% padding or minimum of 100
  }

  double _getWeekTotal(ExpenseProvider provider) {
    final spots = _getWeeklyExpenseData(provider);
    return spots.map((spot) => spot.y).reduce((a, b) => a + b);
  }

  Widget _buildWeeklyInsights(ExpenseProvider provider) {
    final weekTotal = _getWeekTotal(provider);
    final dailyData = _getWeeklyExpenseData(provider);
    final averageDaily = weekTotal / 7;
    
    // Find highest spending day
    double maxAmount = 0;
    int maxDayIndex = 0;
    for (int i = 0; i < dailyData.length; i++) {
      if (dailyData[i].y > maxAmount) {
        maxAmount = dailyData[i].y;
        maxDayIndex = i;
      }
    }
    
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.dailyAvg ?? 'Daily Avg',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'RM ${averageDaily.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.highestDay ?? 'Highest Day',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  maxAmount > 0 ? days[maxDayIndex].substring(0, 3) : (AppLocalizations.of(context)?.none ?? 'None'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ExpenseItem extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final double percentage;

  const ExpenseItem({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: AppColors.lightGrey,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }
}