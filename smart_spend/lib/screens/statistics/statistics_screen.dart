import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../utils/colors.dart';
import '../../widgets/financial_health_gauge.dart';
import '../../providers/expense_provider.dart';
import '../../providers/account_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../transactions/transaction_history_screen.dart';
import '../../l10n/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        Provider.of<AccountProvider>(context, listen: false).loadAccounts(authService: authService);
        Provider.of<ExpenseProvider>(context, listen: false).loadExpenses(authService: authService);
        _loadUserData(authService);
      }
    });
  }

  Future<void> _loadUserData(AuthService authService) async {
    if (authService.currentUser != null) {
      try {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        final userData = await firestoreService.getUser(authService.currentUser!.uid);
        if (mounted) {
          setState(() {
            _currentUser = userData;
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        Provider.of<ExpenseProvider>(context, listen: false).loadExpenses(authService: authService);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.statistic ?? 'Statistic'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Consumer2<ExpenseProvider, AccountProvider>(
        builder: (context, expenseProvider, accountProvider, child) {
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
                    AppLocalizations.of(context)?.errorLoadingData ?? 'Error loading data',
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
                    child: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
                  ),
                ],
              ),
            );
          }

          // Use current account balance and get general statistics
          double totalBalance = accountProvider.currentAccountBalance;
          
          // Get general statistics
          double accountIncome = expenseProvider.totalIncome;
          double accountExpenses = expenseProvider.totalExpenses;
          
          // Calculate financial health score
          double financialHealthScore = _calculateFinancialHealthScore(expenseProvider, accountProvider);
          String healthMessage = _getHealthMessage(financialHealthScore);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    String username = _getUserDisplayName();
                    String timeBasedGreeting = _getTimeBasedGreeting();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$timeBasedGreeting, $username',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)?.hereIsYourFinancialOverview ?? 'Here\'s your financial overview',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                // Financial Health Score Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Financial Health Score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getScoreColor(financialHealthScore).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getScoreColor(financialHealthScore).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getScoreIcon(financialHealthScore),
                                  color: _getScoreColor(financialHealthScore),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getScoreLabel(financialHealthScore),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getScoreColor(financialHealthScore),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _formatCurrentDate(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      
                      // Financial Health Gauge
                      FinancialHealthGauge(score: financialHealthScore),
                      
                      const SizedBox(height: 20),
                      Text(
                        healthMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Actionable Insights
                      _buildActionableInsights(financialHealthScore, expenseProvider, accountProvider),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        AppLocalizations.of(context)?.totalExpenses ?? 'Total Expenses',
                        'RM ${accountExpenses.toStringAsFixed(2)}',
                        Icons.trending_down,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        AppLocalizations.of(context)?.totalIncome ?? 'Total Income',
                        'RM ${accountIncome.toStringAsFixed(2)}',
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        AppLocalizations.of(context)?.currentBalance ?? 'Current Balance',
                        'RM ${totalBalance.toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        totalBalance >= 0 ? AppColors.primaryBlue : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        AppLocalizations.of(context)?.netSavings ?? 'Net Savings',
                        'RM ${(accountIncome - accountExpenses).toStringAsFixed(2)}',
                        Icons.savings,
                        (accountIncome - accountExpenses) >= 0 ? AppColors.orange : Colors.red,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Transaction History Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
                      );
                    },
                    icon: const Icon(Icons.history, color: Colors.white),
                    label: const Text(
                      'View Transaction History',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStatCard(String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateFinancialHealthScore(ExpenseProvider expenseProvider, AccountProvider accountProvider) {
    // If no accounts exist, return 0 to prompt user to set up account
    if (accountProvider.accounts.isEmpty) {
      return 0.0;
    }

    double income = expenseProvider.totalIncome;
    double expenses = expenseProvider.totalExpenses;
    double accountBalance = accountProvider.totalAccountBalance;
    
    // Calculate total savings (income - expenses)
    double totalSavings = income - expenses;
    
    // Base score from account balance (20 points max)
    double balanceScore = 0;
    if (accountBalance >= 10000) {
      balanceScore = 20; // 10k+ RM = full balance points
    } else if (accountBalance >= 5000) {
      balanceScore = 15; // 5k-10k RM
    } else if (accountBalance >= 2000) {
      balanceScore = 10; // 2k-5k RM  
    } else if (accountBalance >= 500) {
      balanceScore = 5; // 500-2k RM
    } else if (accountBalance > 0) {
      balanceScore = 2; // Any positive balance
    } else {
      balanceScore = 0; // No/negative balance
    }
    
    // Savings milestone score (80 points max)
    // Every RM500 in savings = +2 points
    double savingsScore = 0;
    if (totalSavings > 0) {
      savingsScore = math.min(80, (totalSavings / 500) * 2);
    } else if (totalSavings < 0) {
      // Penalize negative savings (spending more than earning)
      savingsScore = math.max(-20, totalSavings / 1000); // Every -1000 RM = -1 point
    }
    
    // Combine scores: Balance (20%) + Savings (80%)
    double finalScore = balanceScore + savingsScore;
    
    // Ensure score is between 0 and 100
    return finalScore.clamp(0, 100);
  }

  String _getHealthMessage(double score) {
    if (score == 0) {
      return 'Please set up your account to get your financial health score.';
    } else if (score >= 80) {
      return 'Excellent! Your financial health is outstanding. Keep up the great work!';
    } else if (score >= 60) {
      return 'Good job! Your financial health is above average. Keep it up!';
    } else if (score >= 40) {
      return 'Fair. There\'s room for improvement in your financial habits.';
    } else if (score >= 20) {
      return 'Consider reviewing your spending habits to improve your financial health.';
    } else {
      return 'Focus on reducing expenses and increasing savings to improve your score.';
    }
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _getUserDisplayName() {
    // Use the name from Firebase user data if available
    if (_currentUser != null && _currentUser!.name.isNotEmpty) {
      return _currentUser!.name;
    }
    
    // Fallback to 'User' if no Firebase data is loaded yet
    return AppLocalizations.of(context)?.user ?? 'User';
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return AppLocalizations.of(context)?.goodMorning ?? 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return AppLocalizations.of(context)?.goodAfternoon ?? 'Good Afternoon';
    } else if (hour >= 17 && hour < 22) {
      return AppLocalizations.of(context)?.goodEvening ?? 'Good Evening';
    } else {
      return AppLocalizations.of(context)?.goodNight ?? 'Good Night';
    }
  }



  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.primaryBlue;
    if (score >= 60) return AppColors.green;
    if (score >= 40) return AppColors.yellow;
    if (score >= 20) return AppColors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return AppLocalizations.of(context)?.excellent ?? 'Excellent';
    if (score >= 60) return AppLocalizations.of(context)?.great ?? 'Great';
    if (score >= 40) return AppLocalizations.of(context)?.good ?? 'Good';
    if (score >= 20) return AppLocalizations.of(context)?.fair ?? 'Fair';
    return AppLocalizations.of(context)?.poor ?? 'Poor';
  }

  IconData _getScoreIcon(double score) {
    if (score >= 80) return Icons.trending_up;
    if (score >= 60) return Icons.thumb_up;
    if (score >= 40) return Icons.trending_flat;
    if (score >= 20) return Icons.trending_down;
    return Icons.warning;
  }

  Widget _buildActionableInsights(double score, ExpenseProvider expenseProvider, AccountProvider accountProvider) {
    List<Map<String, dynamic>> insights = [];
    
    // Generate insights based on score
    if (score >= 80) {
      insights = [
        {
          'icon': Icons.savings,
          'title': 'Keep It Up!',
          'subtitle': 'Consider investing your surplus',
          'color': AppColors.green,
        },
        {
          'icon': Icons.trending_up,
          'title': 'Excellent Habits',
          'subtitle': 'Your financial discipline is outstanding',
          'color': AppColors.primaryBlue,
        },
      ];
    } else if (score >= 60) {
      insights = [
        {
          'icon': Icons.flag,
          'title': 'Almost There!',
          'subtitle': 'Try to save 20% more this month',
          'color': AppColors.green,
        },
        {
          'icon': Icons.timeline,
          'title': 'Track Progress',
          'subtitle': 'Monitor your spending patterns',
          'color': AppColors.primaryBlue,
        },
      ];
    } else if (score >= 40) {
      insights = [
        {
          'icon': Icons.warning_amber,
          'title': 'Review Expenses',
          'subtitle': 'Look for unnecessary spending',
          'color': AppColors.orange,
        },
        {
          'icon': Icons.savings,
          'title': 'Start Saving',
          'subtitle': 'Aim to save 10% of your income',
          'color': AppColors.yellow,
        },
      ];
    } else {
      insights = [
        {
          'icon': Icons.priority_high,
          'title': 'Budget Needed',
          'subtitle': 'Create a monthly spending plan',
          'color': Colors.red,
        },
        {
          'icon': Icons.cut,
          'title': 'Reduce Expenses',
          'subtitle': 'Cut non-essential spending immediately',
          'color': AppColors.orange,
        },
      ];
    }

    return Column(
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: insights.map((insight) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (insight['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (insight['color'] as Color).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: insight['color'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        insight['icon'] as IconData,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      insight['title'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: insight['color'] as Color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}