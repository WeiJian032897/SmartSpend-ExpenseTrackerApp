import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../models/planned_payment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'category_selection_screen.dart';

class AddPlannedPaymentScreen extends StatefulWidget {
  const AddPlannedPaymentScreen({super.key});

  @override
  State<AddPlannedPaymentScreen> createState() => _AddPlannedPaymentScreenState();
}

class _AddPlannedPaymentScreenState extends State<AddPlannedPaymentScreen> {
  final TextEditingController _amountController = TextEditingController(text: '0');
  String _selectedCurrency = 'RM';
  String _paymentName = '';
  String _selectedAccount = 'Select Account';
  String _selectedCategory = '';
  String _confirmationType = 'Manual';
  String _repeatType = 'Monthly';
  String _selectedPaymentType = 'Cash';
  String _payeeName = '';
  String _note = '';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Add Planned Payment'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _savePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Add', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showCurrencyDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.darkBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCurrency,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // General Section
            const Text(
              'GENERAL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 15),
            
            _buildOptionTile(
              icon: Icons.text_fields,
              title: 'Payment name',
              value: _paymentName.isEmpty ? 'Required' : _paymentName,
              color: Colors.grey,
              isRequired: true,
              onTap: () => _showTextInputDialog('Payment name', _paymentName, (value) {
                setState(() {
                  _paymentName = value;
                });
              }),
            ),
            _buildOptionTile(
              icon: Icons.account_balance_wallet,
              title: 'Account',
              value: _selectedAccount,
              color: AppColors.yellow,
              isRequired: true,
              onTap: () => _showAccountDialog(),
            ),
            _buildOptionTile(
              icon: Icons.category,
              title: 'Category',
              value: _selectedCategory.isEmpty ? 'Required' : _selectedCategory,
              color: AppColors.purple,
              isRequired: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategorySelectionScreen(
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.check_circle,
              title: 'Confirmation',
              value: _confirmationType,
              color: Colors.grey,
              onTap: () => _showConfirmationDialog(),
            ),
            
            const SizedBox(height: 30),
            const Text(
              'DATE AND REPEAT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 15),
            
            _buildOptionTile(
              icon: Icons.calendar_today,
              title: 'Date',
              value: DateFormat('dd MMMM yyyy').format(_selectedDate),
              color: Colors.grey,
              isRequired: true,
              onTap: () => _selectDate(),
            ),
            _buildOptionTile(
              icon: Icons.repeat,
              title: 'Repeat',
              value: _repeatType,
              color: Colors.grey,
              onTap: () => _showRepeatDialog(),
            ),
            
            const SizedBox(height: 30),
            const Text(
              'MORE DETAIL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 15),
            
            _buildOptionTile(
              icon: Icons.payment,
              title: 'Payment Type',
              value: _selectedPaymentType,
              color: Colors.grey,
              onTap: () => _showPaymentTypeDialog(),
            ),
            _buildOptionTile(
              icon: Icons.person,
              title: 'Payee',
              value: _payeeName.isEmpty ? '' : _payeeName,
              color: Colors.grey,
              onTap: () => _showTextInputDialog('Payee name', _payeeName, (value) {
                setState(() {
                  _payeeName = value;
                });
              }),
            ),
            _buildOptionTile(
              icon: Icons.note,
              title: 'Note',
              value: _note.isEmpty ? '' : _note,
              color: Colors.grey,
              onTap: () => _showTextInputDialog('Add note', _note, (value) {
                setState(() {
                  _note = value;
                });
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isRequired = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (value.isNotEmpty && value != 'Required')
                    const SizedBox(height: 2),
                  if (value.isNotEmpty && value != 'Required')
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (isRequired && (value.isEmpty || value == 'Required'))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else if (value.isEmpty || value == 'Required')
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              )
            else
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showTextInputDialog(String title, String initialValue, Function(String) onSaved) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onSaved(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Manual'),
              subtitle: const Text('Upcoming payment will wait for you approving'),
              leading: Radio<String>(
                value: 'Manual',
                groupValue: _confirmationType,
                onChanged: (value) {
                  setState(() {
                    _confirmationType = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Automatically'),
              subtitle: const Text('The payment will be created without your approving'),
              leading: Radio<String>(
                value: 'Automatically',
                groupValue: _confirmationType,
                onChanged: (value) {
                  setState(() {
                    _confirmationType = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRepeatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repeat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['One-Time', 'Daily', 'Weekly', 'Monthly'].map((type) {
            return ListTile(
              title: Text(type),
              leading: Radio<String>(
                value: type,
                groupValue: _repeatType,
                onChanged: (value) {
                  setState(() {
                    _repeatType = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPaymentTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Cash', 'Debit Card', 'E-wallet', 'Mobile payment', 'Web payment'].map((type) {
            return ListTile(
              title: Text(type),
              leading: Radio<String>(
                value: type,
                groupValue: _selectedPaymentType,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentType = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAccountDialog() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      if (authService.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to continue')),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final accounts = await firestoreService.getUserAccounts(authService.currentUser!.uid);
      
      // Dismiss loading indicator
      Navigator.pop(context);
      
      if (accounts.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Accounts Found'),
            content: const Text('You need to create an account first before setting up planned payments.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Show account selection dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Account'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return ListTile(
                  title: Text(account.name),
                  subtitle: Text('Balance: RM ${account.balance.toStringAsFixed(2)}'),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedAccount == account.name 
                          ? AppColors.yellow 
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: _selectedAccount == account.name 
                          ? Colors.white 
                          : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  trailing: _selectedAccount == account.name
                      ? const Icon(Icons.check, color: AppColors.yellow)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedAccount = account.name;
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
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Dismiss loading indicator if still showing
      Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading accounts: ${e.toString()}')),
      );
    }
  }

  void _showCurrencyDialog() {
    final currencies = [
      {'code': 'RM', 'name': 'Malaysian Ringgit'},
      {'code': 'USD', 'name': 'US Dollar'},
      {'code': 'EUR', 'name': 'Euro'},
      {'code': 'GBP', 'name': 'British Pound'},
      {'code': 'SGD', 'name': 'Singapore Dollar'},
      {'code': 'IDR', 'name': 'Indonesian Rupiah'},
      {'code': 'THB', 'name': 'Thai Baht'},
      {'code': 'JPY', 'name': 'Japanese Yen'},
      {'code': 'CNY', 'name': 'Chinese Yuan'},
      {'code': 'KRW', 'name': 'South Korean Won'},
      {'code': 'INR', 'name': 'Indian Rupee'},
      {'code': 'AUD', 'name': 'Australian Dollar'},
      {'code': 'CAD', 'name': 'Canadian Dollar'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final currency = currencies[index];
              return ListTile(
                title: Text(currency['code']!),
                subtitle: Text(currency['name']!),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedCurrency == currency['code'] 
                        ? AppColors.primaryBlue 
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.monetization_on,
                    color: _selectedCurrency == currency['code'] 
                        ? Colors.white 
                        : Colors.grey.shade600,
                    size: 20,
                  ),
                ),
                trailing: _selectedCurrency == currency['code']
                    ? const Icon(Icons.check, color: AppColors.primaryBlue)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedCurrency = currency['code']!;
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
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePayment() async {
    if (_paymentName.isEmpty || _selectedCategory.isEmpty || _selectedAccount == 'Select Account') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      if (authService.currentUser == null) {
        throw Exception('User not logged in');
      }

      final amount = double.tryParse(_amountController.text) ?? 0.0;
      if (amount <= 0) {
        throw Exception('Please enter a valid amount');
      }

      final plannedPayment = PlannedPaymentModel(
        id: '', // Will be set by Firestore
        userId: authService.currentUser!.uid,
        paymentName: _paymentName,
        amount: amount,
        category: _selectedCategory,
        account: _selectedAccount,
        paymentType: _selectedPaymentType,
        repeatType: _repeatType,
        payee: _payeeName,
        note: _note,
        startDate: _selectedDate,
        selectedDays: [], // Default empty list for now
        isManualConfirmation: _confirmationType == 'Manual',
        currency: _selectedCurrency,
        isActive: true,
      );

      await firestoreService.addPlannedPayment(plannedPayment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Planned payment added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding planned payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}