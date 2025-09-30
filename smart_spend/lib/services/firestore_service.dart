import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../models/planned_payment_model.dart';
import '../models/account_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print('Error creating user: $e');
      throw e;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      print('Error updating user: $e');
      throw e;
    }
  }

  // Expense operations
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      // Save to different collections based on type
      String collectionName = expense.isIncome ? 'income' : 'expenses';
      await _firestore.collection(collectionName).add(expense.toMap());
    } catch (e) {
      print('Error adding expense: $e');
      throw e;
    }
  }

  Future<List<ExpenseModel>> getUserExpenses(String userId) async {
    try {
      List<ExpenseModel> allTransactions = [];
      
      // Get expenses
      QuerySnapshot expenseQuery = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();
      
      List<ExpenseModel> expenses = expenseQuery.docs
          .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      allTransactions.addAll(expenses);
      
      // Get income
      QuerySnapshot incomeQuery = await _firestore
          .collection('income')
          .where('userId', isEqualTo: userId)
          .get();
      
      List<ExpenseModel> income = incomeQuery.docs
          .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      allTransactions.addAll(income);
      
      // Sort by date in memory (descending - newest first)
      allTransactions.sort((a, b) => b.date.compareTo(a.date));
      
      return allTransactions;
    } catch (e) {
      print('Error getting expenses: $e');
      return [];
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      // Update in the correct collection based on type
      String collectionName = expense.isIncome ? 'income' : 'expenses';
      await _firestore.collection(collectionName).doc(expense.id).update(expense.toMap());
    } catch (e) {
      print('Error updating expense: $e');
      throw e;
    }
  }

  Future<void> deleteExpense(String expenseId, {bool? isIncome}) async {
    try {
      if (isIncome != null) {
        // If we know the type, delete from the correct collection
        String collectionName = isIncome ? 'income' : 'expenses';
        await _firestore.collection(collectionName).doc(expenseId).delete();
      } else {
        // If we don't know the type, try both collections
        try {
          await _firestore.collection('expenses').doc(expenseId).delete();
        } catch (e) {
          // If not found in expenses, try income
          await _firestore.collection('income').doc(expenseId).delete();
        }
      }
    } catch (e) {
      print('Error deleting expense: $e');
      throw e;
    }
  }

  // Planned Payment operations
  Future<void> addPlannedPayment(PlannedPaymentModel payment) async {
    try {
      await _firestore.collection('planned_payments').add(payment.toMap());
    } catch (e) {
      print('Error adding planned payment: $e');
      throw e;
    }
  }

  Future<List<PlannedPaymentModel>> getUserPlannedPayments(String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('planned_payments')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      List<PlannedPaymentModel> payments = query.docs
          .map((doc) => PlannedPaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
          
      // Sort by start date in memory (ascending - earliest first)
      payments.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      return payments;
    } catch (e) {
      print('Error getting planned payments: $e');
      print('Error details: ${e.toString()}');
      return [];
    }
  }

  Future<void> updatePlannedPayment(PlannedPaymentModel payment) async {
    try {
      await _firestore.collection('planned_payments').doc(payment.id).update(payment.toMap());
    } catch (e) {
      print('Error updating planned payment: $e');
      throw e;
    }
  }

  Future<void> deletePlannedPayment(String paymentId) async {
    try {
      await _firestore.collection('planned_payments').doc(paymentId).update({'isActive': false});
    } catch (e) {
      print('Error deleting planned payment: $e');
      throw e;
    }
  }

  // Account operations
  Future<void> addAccount(AccountModel account) async {
    try {
      await _firestore.collection('accounts').add(account.toMap());
    } catch (e) {
      print('Error adding account: $e');
      throw e;
    }
  }

  Future<List<AccountModel>> getUserAccounts(String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('accounts')
          .where('userId', isEqualTo: userId)
          .get();

      return query.docs
          .map((doc) => AccountModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting accounts: $e');
      return [];
    }
  }

  Future<void> updateAccount(AccountModel account) async {
    try {
      await _firestore.collection('accounts').doc(account.id).update(account.toMap());
    } catch (e) {
      print('Error updating account: $e');
      throw e;
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      await _firestore.collection('accounts').doc(accountId).delete();
    } catch (e) {
      print('Error deleting account: $e');
      throw e;
    }
  }

  Future<void> deleteAllUserExpenses(String userId) async {
    try {
      // Delete all expenses for the user
      QuerySnapshot expenseQuery = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in expenseQuery.docs) {
        await doc.reference.delete();
      }

      // Delete all income for the user
      QuerySnapshot incomeQuery = await _firestore
          .collection('income')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in incomeQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting user expenses: $e');
      throw e;
    }
  }

  Future<void> deleteAllUserPlannedPayments(String userId) async {
    try {
      // Delete all planned payments for the user
      QuerySnapshot plannedPaymentsQuery = await _firestore
          .collection('planned_payments')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in plannedPaymentsQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting user planned payments: $e');
      throw e;
    }
  }

  Future<void> deleteAllUserAccounts(String userId) async {
    try {
      // Delete all accounts for the user
      QuerySnapshot accountsQuery = await _firestore
          .collection('accounts')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in accountsQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting user accounts: $e');
      throw e;
    }
  }

  Future<void> deleteAllUserData(String userId) async {
    try {
      print('Starting deletion of all data for user: $userId');
      
      // Delete all user expenses and income
      await deleteAllUserExpenses(userId);
      print('Deleted all expenses and income');
      
      // Delete all user planned payments
      await deleteAllUserPlannedPayments(userId);
      print('Deleted all planned payments');
      
      // Delete all user accounts
      await deleteAllUserAccounts(userId);
      print('Deleted all accounts');
      
      // Finally, delete the user profile
      await _firestore.collection('users').doc(userId).delete();
      print('Deleted user profile');
      
      print('Successfully deleted all data for user: $userId');
    } catch (e) {
      print('Error deleting all user data: $e');
      throw e;
    }
  }
}