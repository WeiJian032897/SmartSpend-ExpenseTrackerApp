import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/two_factor_service.dart';
import '../../services/auth_service.dart';
import 'verify_code_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TwoFactorService _twoFactorService = TwoFactorService();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _twoFactorService.sendVerificationCode(_phoneController.text.trim());
      
      if (mounted) {
        // Show success message with instructions
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code generated! Check the console for the code or implement WhatsApp Business API integration.'),
            duration: Duration(seconds: 4),
          ),
        );
        
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.currentUser?.uid;
        
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyCodeScreen(
              phoneNumber: _phoneController.text.trim(),
              userId: userId,
            ),
          ),
        );
        
        // Return the result from verification
        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Phone Verification'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Enter Your Phone Number',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We will send a 6-digit verification code to your WhatsApp',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            CustomTextField(
              controller: _phoneController,
              labelText: 'Phone Number',
              hintText: '+60123456789',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone),
            ),
            const SizedBox(height: 30),
            CustomButton(
              text: _isLoading ? 'Sending...' : 'Send Verification Code',
              onPressed: _isLoading ? null : _sendVerificationCode,
              backgroundColor: AppColors.green,
            ),
          ],
        ),
      ),
    );
  }
}