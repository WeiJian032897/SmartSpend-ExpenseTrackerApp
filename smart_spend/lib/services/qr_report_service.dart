import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class QRReportService {
  static const String baseUrl = 'https://weijian032897.github.io/smartspend-report'; // Replace 'yourusername' with your GitHub username
  
  static Map<String, dynamic> generateWeeklyReport(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    final weeklyExpenses = expenses.where((expense) {
      return expense.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
             expense.date.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
    
    final totalIncome = weeklyExpenses
        .where((e) => e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);
    
    final totalExpenses = weeklyExpenses
        .where((e) => !e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);
    
    final categoryBreakdown = <String, double>{};
    for (var expense in weeklyExpenses.where((e) => !e.isIncome)) {
      categoryBreakdown[expense.category] = 
          (categoryBreakdown[expense.category] ?? 0) + expense.amount;
    }
    
    return {
      'type': 'weekly',
      'period': '${DateFormat('MMM dd').format(weekStart)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}',
      'startDate': weekStart.toIso8601String(),
      'endDate': weekEnd.toIso8601String(),
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netBalance': totalIncome - totalExpenses,
      'transactionCount': weeklyExpenses.length,
      'categoryBreakdown': categoryBreakdown,
      'currency': weeklyExpenses.isNotEmpty ? weeklyExpenses.first.currency : 'RM',
    };
  }
  
  static Map<String, dynamic> generateMonthlyReport(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    
    final monthlyExpenses = expenses.where((expense) {
      return expense.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
             expense.date.isBefore(monthEnd.add(const Duration(days: 1)));
    }).toList();
    
    final totalIncome = monthlyExpenses
        .where((e) => e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);
    
    final totalExpenses = monthlyExpenses
        .where((e) => !e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);
    
    final categoryBreakdown = <String, double>{};
    final dailyBreakdown = <String, double>{};
    
    for (var expense in monthlyExpenses.where((e) => !e.isIncome)) {
      categoryBreakdown[expense.category] = 
          (categoryBreakdown[expense.category] ?? 0) + expense.amount;
      
      final dateKey = DateFormat('yyyy-MM-dd').format(expense.date);
      dailyBreakdown[dateKey] = 
          (dailyBreakdown[dateKey] ?? 0) + expense.amount;
    }
    
    return {
      'type': 'monthly',
      'period': DateFormat('MMMM yyyy').format(monthStart),
      'startDate': monthStart.toIso8601String(),
      'endDate': monthEnd.toIso8601String(),
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netBalance': totalIncome - totalExpenses,
      'transactionCount': monthlyExpenses.length,
      'categoryBreakdown': categoryBreakdown,
      'dailyBreakdown': dailyBreakdown,
      'currency': monthlyExpenses.isNotEmpty ? monthlyExpenses.first.currency : 'RM',
    };
  }
  
  static Map<String, dynamic> generateYearlyReport(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31);
    
    final yearlyExpenses = expenses.where((expense) {
      return expense.date.isAfter(yearStart.subtract(const Duration(days: 1))) &&
             expense.date.isBefore(yearEnd.add(const Duration(days: 1)));
    }).toList();
    
    final totalIncome = yearlyExpenses
        .where((e) => e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);
    
    final totalExpenses = yearlyExpenses
        .where((e) => !e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);
    
    final categoryBreakdown = <String, double>{};
    final monthlyBreakdown = <String, double>{};
    
    for (var expense in yearlyExpenses.where((e) => !e.isIncome)) {
      categoryBreakdown[expense.category] = 
          (categoryBreakdown[expense.category] ?? 0) + expense.amount;
      
      final monthKey = DateFormat('yyyy-MM').format(expense.date);
      monthlyBreakdown[monthKey] = 
          (monthlyBreakdown[monthKey] ?? 0) + expense.amount;
    }
    
    return {
      'type': 'yearly',
      'period': now.year.toString(),
      'startDate': yearStart.toIso8601String(),
      'endDate': yearEnd.toIso8601String(),
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netBalance': totalIncome - totalExpenses,
      'transactionCount': yearlyExpenses.length,
      'categoryBreakdown': categoryBreakdown,
      'monthlyBreakdown': monthlyBreakdown,
      'currency': yearlyExpenses.isNotEmpty ? yearlyExpenses.first.currency : 'RM',
    };
  }
  
  static String generateReportUrl(Map<String, dynamic> reportData, String userId) {
    // Encode the report data and user ID for the web URL
    final encodedData = base64Url.encode(utf8.encode(jsonEncode(reportData)));
    return '$baseUrl/report.html?data=$encodedData&user=$userId';
  }
  
  static String generateQRData(ExpenseProvider expenseProvider, String reportType, String userId) {
    final expenses = expenseProvider.expenses;
    
    Map<String, dynamic> reportData;
    if (reportType == 'weekly') {
      reportData = generateWeeklyReport(expenses);
    } else if (reportType == 'monthly') {
      reportData = generateMonthlyReport(expenses);
    } else if (reportType == 'yearly') {
      reportData = generateYearlyReport(expenses);
    } else {
      reportData = generateMonthlyReport(expenses); // Default to monthly
    }
    
    return generateReportUrl(reportData, userId);
  }
}