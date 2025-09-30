import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.idTokenChanges(),
          builder: (context, snapshot) {
            // Show loading spinner while checking authentication
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // If user is logged in, show home screen
            if (snapshot.hasData && snapshot.data != null) {
              return const HomeScreen();
            }
            
            // If user is not logged in, show login screen
            return const LoginScreen();
          },
        );
      },
    );
  }
}

// For web debugging without Firebase
class WebAuthWrapper extends StatefulWidget {
  const WebAuthWrapper({super.key});

  @override
  State<WebAuthWrapper> createState() => _WebAuthWrapperState();
}

class _WebAuthWrapperState extends State<WebAuthWrapper> {
  bool _isLoggedIn = false;

  void _login() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return HomeScreen(onLogout: _logout);
    }
    
    return LoginScreen(onLogin: _login);
  }
}