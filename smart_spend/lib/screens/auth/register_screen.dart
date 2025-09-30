import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onRegister;
  
  const RegisterScreen({super.key, this.onRegister});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String _passwordStrength = '';

  void _calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = '';
      });
      return;
    }

    bool hasLetters = RegExp(r'[a-zA-Z]').hasMatch(password);
    bool hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    bool hasSpecialChars = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    
    if (hasLetters && hasNumbers && hasSpecialChars && password.length >= 8) {
      setState(() {
        _passwordStrength = 'Strong';
      });
    } else if (hasLetters && hasNumbers && password.length > 6) {
      setState(() {
        _passwordStrength = 'Medium';
      });
    } else if ((hasLetters && !hasNumbers && !hasSpecialChars) || 
               (!hasLetters && hasNumbers && !hasSpecialChars)) {
      if (password.length >= 6) {
        setState(() {
          _passwordStrength = 'Weak';
        });
      } else {
        setState(() {
          _passwordStrength = '';
        });
      }
    } else {
      setState(() {
        _passwordStrength = '';
      });
    }
  }

  Color _getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case 'Strong':
        return AppColors.green;
      case 'Medium':
        return AppColors.orange;
      case 'Weak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.green.withValues(alpha: 0.1),
              Colors.white,
              AppColors.primaryBlue.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Back button and app icon section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryBlue),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Welcome text section
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join SmartSpend today and start your\njourney to financial freedom!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 50),
                  
                    // Name field with enhanced design
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CustomTextField(
                        hintText: 'Full Name',
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter your full name';
                          }
                          if (value!.length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Email field with enhanced design
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CustomTextField(
                        hintText: 'Email Address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                            return 'Please enter a valid email';
                          }
                          if (!value.toLowerCase().endsWith('@gmail.com')) {
                            return 'Please use a Gmail address (@gmail.com)';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Password field with enhanced design
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CustomTextField(
                        hintText: 'Password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onChanged: _calculatePasswordStrength,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.primaryBlue,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter your password';
                          }
                          if (value!.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    // Password strength indicator
                    if (_passwordStrength.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              _passwordStrength == 'Strong' 
                                  ? Icons.security 
                                  : _passwordStrength == 'Medium' 
                                      ? Icons.shield 
                                      : Icons.warning_rounded,
                              color: _getPasswordStrengthColor(),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Password strength: $_passwordStrength',
                              style: TextStyle(
                                color: _getPasswordStrengthColor(),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            // Strength bars
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: _passwordStrength.isNotEmpty ? _getPasswordStrengthColor() : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 20,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: (_passwordStrength == 'Medium' || _passwordStrength == 'Strong') 
                                        ? _getPasswordStrengthColor() 
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 20,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: _passwordStrength == 'Strong' 
                                        ? _getPasswordStrengthColor() 
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Confirm password field with enhanced design
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CustomTextField(
                        hintText: 'Confirm Password',
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.primaryBlue,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Enhanced terms and conditions checkbox
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _agreeToTerms ? AppColors.green : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              color: _agreeToTerms ? AppColors.green : Colors.transparent,
                            ),
                            child: _agreeToTerms
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _agreeToTerms = !_agreeToTerms;
                                });
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms and Conditions',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Enhanced sign up button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: _agreeToTerms && !_isLoading
                            ? LinearGradient(
                                colors: [AppColors.green, AppColors.green.withValues(alpha: 0.8)],
                              )
                            : null,
                        color: !_agreeToTerms || _isLoading ? Colors.grey.shade300 : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _agreeToTerms && !_isLoading
                            ? [
                                BoxShadow(
                                  color: AppColors.green.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_agreeToTerms) ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Create Account',
                                style: TextStyle(
                                  color: _agreeToTerms ? Colors.white : Colors.grey.shade600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Enhanced login link
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          children: [
                            const TextSpan(text: "Already have an account? "),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // For web demo, use simple validation
    if (widget.onRegister != null) {
      // Web demo mode - any registration works
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      setState(() {
        _isLoading = false;
      });
      widget.onRegister!();
      return;
    }

    // Firebase authentication for mobile
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        // Registration successful - navigate to login page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please sign in with your new account.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to login page after registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        _showErrorDialog('Registration failed. Please try again.');
      }
    }
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}