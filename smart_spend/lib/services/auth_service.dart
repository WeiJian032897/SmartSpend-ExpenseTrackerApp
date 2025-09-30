import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'dart:async';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();
  Timer? _tokenRefreshTimer;
  StreamSubscription<User?>? _authStateSubscription;
  
  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  AuthService() {
    _initializeAuth();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners(); // Notify listeners of auth state change
      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Error signing in: $e');
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        await _firestoreService.createUser(UserModel(
          uid: result.user!.uid,
          email: email,
          name: name,
        ));
        notifyListeners(); // Notify listeners of auth state change
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Error signing up: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      debugPrint('🔍 Starting Google sign-in process...');
      
      // Sign out from any previous Google session to ensure clean state
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('❌ Google sign-in cancelled by user');
        return {
          'success': false,
          'error': 'cancelled',
          'message': 'Sign-in was cancelled'
        };
      }

      debugPrint('✅ Google user signed in: ${googleUser.email}');
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Missing Google authentication tokens');
        return {
          'success': false,
          'error': 'missing_tokens',
          'message': 'Failed to obtain authentication tokens'
        };
      }
      
      debugPrint('✅ Google authentication tokens obtained');
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('🔄 Signing in with Firebase...');
      UserCredential result = await _auth.signInWithCredential(credential);
      
      if (result.user != null) {
        debugPrint('✅ Firebase sign-in successful: ${result.user!.email}');
        
        // Create or update user in Firestore
        await _firestoreService.createUser(UserModel(
          uid: result.user!.uid,
          email: result.user!.email ?? '',
          name: result.user!.displayName ?? result.user!.email?.split('@')[0] ?? '',
          photoUrl: result.user!.photoURL,
        ));
        
        debugPrint('✅ User data saved to Firestore');
        notifyListeners(); // Notify listeners of auth state change
        return {
          'success': true,
          'message': 'Sign-in successful'
        };
      }
      
      debugPrint('❌ Firebase sign-in failed - no user returned');
      return {
        'success': false,
        'error': 'firebase_failed',
        'message': 'Firebase authentication failed'
      };
    } catch (e) {
      debugPrint('❌ Error signing in with Google: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      
      String errorType = 'unknown';
      String errorMessage = 'An unexpected error occurred';
      
      String errorString = e.toString().toLowerCase();
      
      if (errorString.contains('network_error') || errorString.contains('network')) {
        errorType = 'network';
        errorMessage = 'Please check your internet connection and try again';
        debugPrint('❌ Network error - check internet connection');
      } else if (errorString.contains('sign_in_canceled')) {
        errorType = 'cancelled';
        errorMessage = 'Sign-in was cancelled';
        debugPrint('❌ Sign-in was cancelled by user');
      } else if (errorString.contains('sign_in_failed') || errorString.contains('oauth')) {
        errorType = 'configuration';
        errorMessage = 'Google sign-in is not properly configured. Please contact support or use email sign-in instead.';
        debugPrint('❌ Google sign-in failed - OAuth configuration missing');
      } else if (errorString.contains('10:')) {
        errorType = 'configuration';
        errorMessage = 'Google sign-in is not set up for this app. Please use email sign-in instead.';
        debugPrint('❌ Google sign-in configuration error (Developer console setup required)');
      } else if (errorString.contains('service not available')) {
        errorType = 'service';
        errorMessage = 'Google services are not available. Please try again later.';
        debugPrint('❌ Google services not available');
      }
      
      return {
        'success': false,
        'error': errorType,
        'message': errorMessage
      };
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      print('Attempting to send password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Password reset email sent successfully to: $email');
      return true;
    } catch (e) {
      print('❌ Error resetting password: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      // Log specific Firebase Auth errors for debugging
      String errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('user-not-found')) {
        print('❌ No user found for email: $email');
      } else if (errorMessage.contains('invalid-email')) {
        print('❌ Invalid email format: $email');
      } else if (errorMessage.contains('too-many-requests')) {
        print('❌ Too many reset attempts. Try again later.');
      } else if (errorMessage.contains('network')) {
        print('❌ Network error. Check internet connection.');
      } else {
        print('❌ Unknown error occurred');
      }
      return false;
    }
  }

  void _initializeAuth() {
    _currentUser = _auth.currentUser;
    
    // Listen to auth state changes
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _startTokenRefreshTimer();
      } else {
        _stopTokenRefreshTimer();
      }
      notifyListeners();
    });
    
    // Start token refresh if already logged in
    if (_currentUser != null) {
      _startTokenRefreshTimer();
    }
  }
  
  void _startTokenRefreshTimer() {
    _stopTokenRefreshTimer();
    
    // Refresh token every 55 minutes (tokens expire after 60 minutes)
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 55), (timer) async {
      await _refreshToken();
    });
  }
  
  void _stopTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }
  
  Future<void> _refreshToken() async {
    try {
      if (_currentUser != null) {
        debugPrint('🔄 Refreshing authentication token...');
        await _currentUser!.getIdToken(true); // Force refresh
        debugPrint('✅ Token refreshed successfully');
        
        // Verify the user is still valid
        await _currentUser!.reload();
        _currentUser = _auth.currentUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
      // If token refresh fails, sign out the user
      await signOut();
    }
  }
  
  // Method to manually check auth state
  Future<bool> validateAuthState() async {
    try {
      if (_currentUser != null) {
        await _currentUser!.reload();
        _currentUser = _auth.currentUser;
        
        if (_currentUser == null) {
          // User session expired
          await signOut();
          return false;
        }
        
        // Try to get a fresh token
        await _currentUser!.getIdToken(true);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Auth validation failed: $e');
      await signOut();
      return false;
    }
  }

  Future<void> signOut() async {
    _stopTokenRefreshTimer();
    _currentUser = null;
    await _auth.signOut();
    notifyListeners();
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      User? user = _currentUser;
      if (user == null) return false;

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      User? user = _currentUser;
      if (user == null) {
        throw Exception('No user currently signed in');
      }

      print('Starting account deletion for user: ${user.uid}');
      
      // Delete the Firebase Authentication account
      await user.delete();
      print('Firebase Authentication account deleted successfully');
      
      // Sign out to clear any cached authentication state
      await signOut();
      
      notifyListeners();
      print('Account deletion completed successfully');
    } catch (e) {
      print('Error deleting account: $e');
      
      // Handle specific Firebase Auth errors
      if (e is FirebaseAuthException) {
        if (e.code == 'requires-recent-login') {
          throw Exception('For security reasons, please sign in again before deleting your account');
        }
      }
      
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }
  
  @override
  void dispose() {
    _stopTokenRefreshTimer();
    _authStateSubscription?.cancel();
    super.dispose();
  }
}