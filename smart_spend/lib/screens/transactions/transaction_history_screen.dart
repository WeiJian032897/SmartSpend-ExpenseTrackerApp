import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';
import '../../providers/expense_provider.dart';
import '../../providers/account_provider.dart';
import '../../models/expense_model.dart';
import '../../models/account_model.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
      Provider.of<AccountProvider>(context, listen: false).loadAccounts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
      Provider.of<AccountProvider>(context, listen: false).loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Transaction History'),
        centerTitle: true,
      ),
      body: Consumer2<ExpenseProvider, AccountProvider>(
        builder: (context, expenseProvider, accountProvider, child) {
          if (expenseProvider.isLoading || accountProvider.isLoading) {
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

          final account = accountProvider.currentAccount;
          final expenses = expenseProvider.expenses;

          if (account == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No account found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please add an account first',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Create transaction history with running balance
          List<TransactionItem> transactions = _buildTransactionHistory(account, expenses);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Current Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'RM ${account.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Transaction History Title
                const Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Transaction List
                if (transactions.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add income or expenses to see transaction history',
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _buildTransactionTile(transaction);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<TransactionItem> _buildTransactionHistory(AccountModel account, List<ExpenseModel> expenses) {
    List<TransactionItem> transactions = [];
    
    // Sort expenses by date (oldest first) to calculate running balance correctly
    final sortedExpenses = List<ExpenseModel>.from(expenses)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Start with initial account balance and work backwards through transactions
    double currentBalance = account.balance;
    
    // Calculate what the initial balance was before all transactions
    double initialBalance = currentBalance;
    for (var expense in sortedExpenses) {
      if (expense.isIncome) {
        initialBalance -= expense.amount; // Subtract income to get original balance
      } else {
        initialBalance += expense.amount; // Add back expenses to get original balance
      }
    }
    
    // Add account creation as first transaction
    transactions.add(TransactionItem(
      title: 'Account Created',
      subtitle: 'Initial balance',
      amount: initialBalance,
      runningBalance: initialBalance,
      date: account.createdAt,
      isIncome: true,
      isAccountCreation: true,
    ));

    // Add each expense/income transaction with correct running balance
    double runningBalance = initialBalance;
    for (var expense in sortedExpenses) {
      if (expense.isIncome) {
        runningBalance += expense.amount;
      } else {
        runningBalance -= expense.amount;
      }
      
      transactions.add(TransactionItem(
        title: expense.category,
        subtitle: expense.payee.isNotEmpty ? expense.payee : expense.subCategory,
        amount: expense.amount,
        runningBalance: runningBalance,
        date: expense.date,
        isIncome: expense.isIncome,
        note: expense.note,
      ));
    }

    // Sort transactions by date (newest first) for display
    transactions.sort((a, b) => b.date.compareTo(a.date));
    
    return transactions;
  }

  Widget _buildTransactionTile(TransactionItem transaction) {
    final isIncome = transaction.isIncome;
    final color = transaction.isAccountCreation 
        ? AppColors.primaryBlue 
        : (isIncome ? AppColors.green : AppColors.red);
    final icon = transaction.isAccountCreation
        ? Icons.account_balance_wallet
        : (isIncome ? Icons.add_circle : Icons.remove_circle);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (transaction.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.note,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • h:mm a').format(transaction.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}RM ${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Balance: RM ${transaction.runningBalance.toStringAsFixed(2)}',
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
  }
}

class TransactionItem {
  final String title;
  final String subtitle;
  final double amount;
  final double runningBalance;
  final DateTime date;
  final bool isIncome;
  final String note;
  final bool isAccountCreation;

  TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.runningBalance,
    required this.date,
    required this.isIncome,
    this.note = '',
    this.isAccountCreation = false,
  });
}