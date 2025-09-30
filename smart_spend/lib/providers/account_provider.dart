import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class AccountProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<AccountModel> _accounts = [];
  bool _isLoading = false;
  String? _error;

  List<AccountModel> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get current account balance (only one account allowed)
  double get currentAccountBalance {
    return _accounts.isEmpty ? 0.0 : _accounts.first.balance;
  }

  // Get current account
  AccountModel? get currentAccount {
    if (_accounts.isEmpty) return null;
    return _accounts.first;
  }

  // Legacy method for compatibility - now returns single account balance
  double get totalAccountBalance => currentAccountBalance;
  
  // Legacy method for compatibility - now returns current account
  AccountModel? get primaryAccount => currentAccount;

  Future<void> loadAccounts({AuthService? authService}) async {
    if (authService?.currentUser == null) return;

    _setLoading(true);
    _setError(null);

    try {
      _accounts = await _firestoreService.getUserAccounts(authService!.currentUser!.uid);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load accounts: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addAccount(AccountModel account, {AuthService? authService}) async {
    if (authService?.currentUser == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      // First, delete any existing accounts (since only one account allowed)
      for (var existingAccount in _accounts) {
        await _firestoreService.deleteAccount(existingAccount.id);
      }
      
      // Also delete all existing expenses and planned payments since we're replacing the account
      await _firestoreService.deleteAllUserExpenses(authService!.currentUser!.uid);
      await _firestoreService.deleteAllUserPlannedPayments(authService!.currentUser!.uid);
      
      // Then add the new account
      await _firestoreService.addAccount(account);
      await loadAccounts(authService: authService); // Reload to get updated data
      return true;
    } catch (e) {
      _setError('Failed to add account: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateAccount(AccountModel account, {AuthService? authService}) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestoreService.updateAccount(account);
      await loadAccounts(authService: authService); // Reload to get updated data
      return true;
    } catch (e) {
      _setError('Failed to update account: ${e.toString()}');
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


  Future<bool> updateAccountBalance(double amount, bool isIncome, {AuthService? authService}) async {
    if (_accounts.isEmpty) return false;
    
    final currentAccount = _accounts.first;
    final newBalance = isIncome 
        ? currentAccount.balance + amount 
        : currentAccount.balance - amount;
    
    final updatedAccount = currentAccount.copyWith(
      balance: newBalance,
      updatedAt: DateTime.now(),
    );
    
    return await updateAccount(updatedAccount, authService: authService);
  }

  Future<bool> deleteAccount(String accountId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestoreService.deleteAccount(accountId);
      _accounts.removeWhere((account) => account.id == accountId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete account: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}