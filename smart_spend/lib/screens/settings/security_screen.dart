import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import 'change_password_screen.dart';
import '../auth/phone_verification_screen.dart';
import '../../services/two_factor_service.dart';
import '../../services/auth_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFactorEnabled = false;
  final TwoFactorService _twoFactorService = TwoFactorService();

  @override
  void initState() {
    super.initState();
    _loadTwoFactorStatus();
  }

  Future<void> _loadTwoFactorStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    
    final isVerified = await _twoFactorService.isTwoFactorVerified(userId);
    setState(() {
      _twoFactorEnabled = isVerified;
    });
  }

  Future<void> _showTwoFactorDialog() async {
    if (_twoFactorEnabled) {
      // Show options for verified users
      final result = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Two Factor Authentication'),
            content: const Text('Two Factor Authentication is already verified. What would you like to do?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('reverify'),
                child: const Text('Re-verify'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('disable'),
                child: const Text('Disable', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );

      if (result == 'reverify') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PhoneVerificationScreen(),
          ),
        );
        await _loadTwoFactorStatus();
      } else if (result == 'disable') {
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.currentUser?.uid;
        await _twoFactorService.resetTwoFactorVerification(userId);
        await _loadTwoFactorStatus();
      }
    } else {
      // Show initial verification dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Two Factor Authentication'),
            content: const Text(
              'Do you want to do the one-time Two Factor Authentication to ensure your account authenticity?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          );
        },
      );

      if (result == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PhoneVerificationScreen(),
          ),
        );
        
        // Always refresh status when returning from verification flow
        await _loadTwoFactorStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Security & Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Two-Factor Authentication
            _buildSecurityTile(
              icon: Icons.verified_user,
              title: 'Two-Factor Authentication',
              color: _twoFactorEnabled ? Colors.green : Colors.red,
              onTap: _showTwoFactorDialog,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_twoFactorEnabled) ...[
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 5),
                    const Text('Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 10),
                  ],
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            
            // Change Password
            _buildSecurityTile(
              icon: Icons.lock,
              title: 'Change Password',
              color: AppColors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTile({
    required IconData icon,
    required String title,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}