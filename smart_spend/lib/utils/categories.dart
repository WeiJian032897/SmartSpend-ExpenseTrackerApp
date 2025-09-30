import 'package:flutter/material.dart';
import 'colors.dart';

class ExpenseCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> subCategories;

  const ExpenseCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.subCategories,
  });
}

class ExpenseCategories {
  static const List<ExpenseCategory> categories = [
    ExpenseCategory(
      name: 'Food & Dining',
      icon: Icons.restaurant,
      color: AppColors.orange,
      subCategories: ['Restaurants', 'Groceries', 'Fast Food', 'Coffee & Tea'],
    ),
    ExpenseCategory(
      name: 'Transportation',
      icon: Icons.directions_car,
      color: AppColors.primaryBlue,
      subCategories: ['Gas', 'Public Transport', 'Taxi/Ride Share', 'Parking'],
    ),
    ExpenseCategory(
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: AppColors.red,
      subCategories: ['Clothing', 'Electronics', 'Books', 'Gifts'],
    ),
    ExpenseCategory(
      name: 'Entertainment',
      icon: Icons.movie,
      color: AppColors.purple,
      subCategories: ['Movies', 'Concerts', 'Games', 'Sports'],
    ),
    ExpenseCategory(
      name: 'Bills & Utilities',
      icon: Icons.receipt_long,
      color: AppColors.green,
      subCategories: ['Electricity', 'Water', 'Internet', 'Phone', 'Rent'],
    ),
    ExpenseCategory(
      name: 'Healthcare',
      icon: Icons.local_hospital,
      color: AppColors.lightBlue,
      subCategories: ['Doctor', 'Pharmacy', 'Dental', 'Insurance'],
    ),
    ExpenseCategory(
      name: 'Education',
      icon: Icons.school,
      color: AppColors.yellow,
      subCategories: ['Tuition', 'Books', 'Supplies', 'Courses'],
    ),
    ExpenseCategory(
      name: 'Travel',
      icon: Icons.flight,
      color: AppColors.teal,
      subCategories: ['Flights', 'Hotels', 'Activities', 'Meals'],
    ),
    ExpenseCategory(
      name: 'Personal Care',
      icon: Icons.face,
      color: AppColors.pink,
      subCategories: ['Haircut', 'Cosmetics', 'Spa', 'Gym'],
    ),
    ExpenseCategory(
      name: 'Other',
      icon: Icons.category,
      color: AppColors.grey,
      subCategories: ['Miscellaneous'],
    ),
  ];

  static const List<ExpenseCategory> incomeCategories = [
    ExpenseCategory(
      name: 'Salary',
      icon: Icons.work,
      color: AppColors.green,
      subCategories: ['Main Job', 'Part-time', 'Bonus', 'Overtime'],
    ),
    ExpenseCategory(
      name: 'Business',
      icon: Icons.business,
      color: AppColors.primaryBlue,
      subCategories: ['Sales', 'Services', 'Consulting'],
    ),
    ExpenseCategory(
      name: 'Investment',
      icon: Icons.trending_up,
      color: AppColors.orange,
      subCategories: ['Stocks', 'Bonds', 'Real Estate', 'Crypto'],
    ),
    ExpenseCategory(
      name: 'Other Income',
      icon: Icons.attach_money,
      color: AppColors.teal,
      subCategories: ['Gift', 'Refund', 'Cashback', 'Miscellaneous'],
    ),
  ];

  static ExpenseCategory? getCategoryByName(String name) {
    try {
      return categories.firstWhere((category) => category.name == name);
    } catch (e) {
      try {
        return incomeCategories.firstWhere((category) => category.name == name);
      } catch (e) {
        return null;
      }
    }
  }

  static List<String> getPaymentTypes() {
    return ['Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Digital Wallet', 'Check'];
  }
}