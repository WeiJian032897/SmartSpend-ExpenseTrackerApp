import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'account_provider.dart';

class ExpenseProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _error;

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalBalance {
    double total = 0;
    for (var expense in _expenses) {
      if (expense.isIncome) {
        total += expense.amount;
      } else {
        total -= expense.amount;
      }
    }
    return total;
  }

  double get totalIncome {
    return _expenses
        .where((expense) => expense.isIncome)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double get totalExpenses {
    return _expenses
        .where((expense) => !expense.isIncome)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> get expensesByCategory {
    Map<String, double> categoryTotals = {};
    for (var expense in _expenses.where((e) => !e.isIncome)) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }


  List<ExpenseModel> getExpensesForDateRange(DateTime start, DateTime end) {
    return _expenses.where((expense) {
      return expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
             expense.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> loadExpenses({AuthService? authService}) async {
    if (authService?.currentUser == null) return;

    _setLoading(true);
    _setError(null);

    try {
      _expenses = await _firestoreService.getUserExpenses(authService!.currentUser!.uid);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load expenses: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }


  Future<bool> addExpense(ExpenseModel expense, {AuthService? authService, AccountProvider? accountProvider}) async {
    if (authService?.currentUser == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      // Check if expense would result in negative balance
      if (accountProvider != null && !expense.isIncome) {
        final currentBalance = accountProvider.currentAccountBalance;
        if (expense.amount > currentBalance) {
          _setError('Insufficient balance. Your current balance is RM ${currentBalance.toStringAsFixed(2)}, but you\'re trying to spend RM ${expense.amount.toStringAsFixed(2)}.');
          return false;
        }
      }

      await _firestoreService.addExpense(expense);
      
      // Update account balance if account provider is available
      if (accountProvider != null) {
        await accountProvider.updateAccountBalance(
          expense.amount, 
          expense.isIncome, 
          authService: authService,
        );
      }
      
      await loadExpenses(authService: authService); // Reload to get updated data
      return true;
    } catch (e) {
      _setError('Failed to add expense: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateExpense(ExpenseModel expense) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestoreService.updateExpense(expense);
      await loadExpenses(); // Reload to get updated data
      return true;
    } catch (e) {
      _setError('Failed to update expense: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    _setLoading(true);
    _setError(null);

    try {
      // Find the expense to get its isIncome value
      final expense = _expenses.firstWhere((e) => e.id == expenseId);
      await _firestoreService.deleteExpense(expenseId, isIncome: expense.isIncome);
      _expenses.removeWhere((expense) => expense.id == expenseId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete expense: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}