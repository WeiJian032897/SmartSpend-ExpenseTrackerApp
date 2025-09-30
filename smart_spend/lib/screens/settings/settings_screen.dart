import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/qr_report_service.dart';
import '../../models/user_model.dart';
import '../../utils/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/expense_provider.dart';
import '../records/records_screen.dart';
import 'language_screen.dart';
import 'security_screen.dart';
import '../auth/login_screen.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  
  const SettingsScreen({super.key, this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _userModel;
  bool _isLoading = true;
  bool _isDeletingAccount = false;
  bool _accountDeletionInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload user data when dependencies change (auth state might have changed)
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      try {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        final userData = await firestoreService.getUser(authService.currentUser!.uid);
        if (mounted) {
          setState(() {
            _userModel = userData;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Handle automatic navigation after account deletion
        if (_accountDeletionInProgress && authService.currentUser == null) {
          print('Account deletion detected - navigating to login screen');
          
          // Account deletion completed and user is signed out - navigate to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Reset deletion state after build is complete
              setState(() {
                _accountDeletionInProgress = false;
                _isDeletingAccount = false;
              });
              
              print('Performing navigation to login screen');
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)?.mySettings ?? 'My Settings'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: Stack(
            children: [
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Section
                  _buildProfileSection(),
                  const SizedBox(height: 30),
                  
                  // Settings Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocalizations.of(context)?.settings ?? 'Settings',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Language Setting
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return _buildSettingTile(
                        icon: Icons.language,
                        title: AppLocalizations.of(context)?.language ?? 'Language',
                        color: AppColors.purple,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              languageProvider.currentLanguageName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LanguageScreen()),
                          );
                        },
                      );
                    },
                  ),
                  
                  // Record Setting
                  _buildSettingTile(
                    icon: Icons.receipt,
                    title: AppLocalizations.of(context)?.record ?? 'Record',
                    color: AppColors.lightBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RecordsScreen()),
                      );
                    },
                  ),
                  
                  // QR Financial Report Setting
                  _buildSettingTile(
                    icon: Icons.qr_code,
                    title: 'QR Financial Report',
                    color: AppColors.green,
                    onTap: () => _showQRReportDialog(),
                  ),
                  
                  // Security & Password
                  _buildSettingTile(
                    icon: Icons.security,
                    title: AppLocalizations.of(context)?.securityPassword ?? 'Security & Password',
                    color: AppColors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SecurityScreen()),
                      );
                    },
                  ),
                  
                  // Logout
                  _buildSettingTile(
                    icon: Icons.logout,
                    title: AppLocalizations.of(context)?.logout ?? 'Logout',
                    color: Colors.red,
                    onTap: () => _showLogoutDialog(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Danger Zone Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Danger Zone',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Delete Account
                  _buildSettingTile(
                    icon: Icons.delete_forever,
                    title: AppLocalizations.of(context)?.deleteAccount ?? 'Delete Account',
                    color: Colors.red.shade700,
                    onTap: () => _showDeleteAccountDialog(),
                  ),
                ],
              ),
            ),
          
          // Loading overlay for account deletion
          if (_isDeletingAccount)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Deleting account...\nPlease wait',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildSettingTile({
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

  void _showQRReportDialog() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to generate financial reports'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code, color: AppColors.green),
            SizedBox(width: 8),
            const Text('Generate QR Report'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select the type of financial report you want to generate:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _generateQRReport('weekly');
              },
              icon: const Icon(Icons.calendar_view_week),
              label: Text(AppLocalizations.of(context)?.weeklyReport ?? 'Weekly Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _generateQRReport('monthly');
              },
              icon: const Icon(Icons.calendar_view_month),
              label: Text(AppLocalizations.of(context)?.monthlyReport ?? 'Monthly Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _generateQRReport('yearly');
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Yearly Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  void _generateQRReport(String reportType) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    
    if (authService.currentUser == null) return;
    
    try {
      final qrData = QRReportService.generateQRData(
        expenseProvider,
        reportType,
        authService.currentUser!.uid,
      );
      
      _showQRCodeDialog(qrData, reportType);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showQRCodeDialog(String qrData, String reportType) {
    String reportTitle;
    switch (reportType) {
      case 'weekly':
        reportTitle = 'Weekly';
        break;
      case 'monthly':
        reportTitle = 'Monthly';
        break;
      case 'yearly':
        reportTitle = 'Yearly';
        break;
      default:
        reportTitle = 'Financial';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$reportTitle Report QR Code'),
        content: SizedBox(
          width: 280,
          height: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan this QR code with any device to view your financial report in a web browser.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.close ?? 'Close', style: const TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.primaryBlue)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              
              if (widget.onLogout != null) {
                // Web demo mode
                widget.onLogout!();
              } else {
                // Firebase mode
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Delete Account',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Deleting your account will permanently remove:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text('• All your transaction records'),
            Text('• All your account information'),  
            Text('• All your expense and income data'),
            Text('• Your profile and settings'),
            SizedBox(height: 12),
            Text(
              'Are you absolutely sure you want to delete your account?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.primaryBlue)),
          ),
          ElevatedButton(
            onPressed: () => _deleteAccount(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)?.deleteAccount ?? 'Delete Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    Navigator.pop(context); // Close confirmation dialog
    
    // Set loading state and mark deletion in progress
    setState(() {
      _isDeletingAccount = true;
      _accountDeletionInProgress = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      if (authService.currentUser != null) {
        final userId = authService.currentUser!.uid;
        print('Starting account deletion for user: $userId');
        
        try {
          // Try to delete the Firebase authentication account first
          await authService.deleteAccount();
          print('Deleted Firebase authentication account');
          
          // If auth account deletion is successful, delete all user data from Firestore
          await firestoreService.deleteAllUserData(userId);
          print('Deleted all user data from Firestore');
          
        } catch (authError) {
          print('Auth account deletion failed: $authError');
          
          // Check if it's a re-authentication error
          if (authError.toString().contains('requires-recent-login')) {
            // Re-authentication required - show specific error message
            if (mounted) {
              setState(() {
                _isDeletingAccount = false;
                _accountDeletionInProgress = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: const Text('For security reasons, please sign out and sign in again, then try deleting your account.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 6),
                ),
              );
            }
            return; // Exit without deleting Firestore data
          }
          
          // For other auth errors, still try to delete Firestore data
          // This handles the case where auth account might already be deleted
          try {
            await firestoreService.deleteAllUserData(userId);
            print('Deleted all user data from Firestore after auth error');
          } catch (firestoreError) {
            print('Firestore deletion also failed: $firestoreError');
            throw authError; // Throw the original auth error
          }
        }
      }
      
      // Account deleted successfully - navigation will be handled by Consumer widget
      print('Account deletion completed successfully - navigation will happen automatically');
      
    } catch (e) {
      print('Error during account deletion: $e');
      
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
          _accountDeletionInProgress = false;
        });
        
        // Show more specific error messages
        String errorMessage = 'Failed to delete account: ${e.toString()}';
        if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please try signing out and signing in again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildProfileSection() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final currentUser = authService.currentUser;
        
        if (currentUser == null) {
          return Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.lightGrey,
                child: const Icon(
                  Icons.person,
                  color: AppColors.primaryBlue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not signed in',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Please sign in to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        
        return Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.lightGrey,
              child: Text(
                _getUserInitials(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userModel?.name ?? currentUser.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currentUser.email ?? 'No email',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getUserInitials() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    String name = _userModel?.name ?? currentUser?.displayName ?? 'User';
    List<String> nameParts = name.split(' ');
    
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    } else {
      return 'U';
    }
  }
}