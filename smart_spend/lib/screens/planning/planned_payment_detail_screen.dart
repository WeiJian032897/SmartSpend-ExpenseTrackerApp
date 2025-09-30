import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';
import '../../models/planned_payment_model.dart';

class PlannedPaymentDetailScreen extends StatefulWidget {
  final PlannedPaymentModel payment;

  const PlannedPaymentDetailScreen({super.key, required this.payment});

  @override
  State<PlannedPaymentDetailScreen> createState() => _PlannedPaymentDetailScreenState();
}

class _PlannedPaymentDetailScreenState extends State<PlannedPaymentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Planning'),
        actions: [
          TextButton(
            onPressed: () {
              // Edit functionality
            },
            child: const Text('Edit', style: TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Payment Header
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _getCategoryColor(widget.payment.category),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(widget.payment.category),
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              widget.payment.paymentName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            
            Text(
              '-${widget.payment.currency}${widget.payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            // Page Indicator
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // Payment Overview
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PAYMENT OVERVIEW',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Payment Items
            _buildPaymentItem(
              date: '10 Desember 2024',
              status: 'Due date in 15 days',
              statusColor: AppColors.primaryBlue,
              isPaid: false,
            ),
            const SizedBox(height: 15),
            _buildPaymentItem(
              date: '23 November 2024',
              status: 'Paid Today',
              statusColor: Colors.grey,
              isPaid: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem({
    required String date,
    required String status,
    required Color statusColor,
    required bool isPaid,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (isPaid)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '-${widget.payment.currency}${widget.payment.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 15),
          
          if (!isPaid)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Mark as paid
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Mark as paid',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Edit payment
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: AppColors.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'communication & pc':
        return AppColors.purple;
      case 'education, development':
        return AppColors.green;
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'communication & pc':
        return Icons.phone;
      case 'education, development':
        return Icons.school;
      default:
        return Icons.payment;
    }
  }
}