import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'environment_service.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';

class WhatsAppApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic> errorData;

  WhatsAppApiException(this.message, this.statusCode, this.errorData);

  @override
  String toString() => 'WhatsAppApiException: $message (Status: $statusCode)';
}

class TwoFactorService {
  static const String _verificationCodeKey = 'verification_code';
  static const String _phoneNumberKey = 'verification_phone';
  static const String _timestampKey = 'verification_timestamp';
  static const String _twoFactorVerifiedKey = 'two_factor_verified';
  static const int _codeExpirationMinutes = 5;
  
  final FirestoreService _firestoreService = FirestoreService();

  String _generateVerificationCode() {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    return code;
  }

  Future<void> sendVerificationCode(String phoneNumber) async {
    try {
      await EnvironmentService.initialize();
      
      print('=== 2FA SERVICE DEBUG ===');
      print('WhatsApp Configured: ${EnvironmentService.isWhatsappConfigured}');
      print('Development Mode: ${EnvironmentService.isDevelopmentMode}');
      print('Phone Number: $phoneNumber');
      print('========================');
      
      final code = _generateVerificationCode();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_verificationCodeKey, code);
      await prefs.setString(_phoneNumberKey, phoneNumber);
      await prefs.setInt(_timestampKey, timestamp);

      await _sendWhatsAppMessage(phoneNumber, code);
    } catch (e) {
      print('❌ Error in sendVerificationCode: $e');
      throw Exception('Failed to send verification code: $e');
    }
  }

  Future<void> _sendWhatsAppMessage(String phoneNumber, String code) async {
    final message = 'SmartSpend verification code: $code (expires in $_codeExpirationMinutes min)';
    
    try {
      await EnvironmentService.initialize();
      
      String cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Ensure phone number starts with + and has country code
      if (!cleanPhoneNumber.startsWith('+')) {
        if (cleanPhoneNumber.startsWith('0')) {
          // Remove leading 0 and add Malaysia country code as default
          cleanPhoneNumber = '+6${cleanPhoneNumber.substring(1)}';
        } else if (!cleanPhoneNumber.startsWith('6')) {
          // Add Malaysia country code if no country code present
          cleanPhoneNumber = '+6$cleanPhoneNumber';
        } else {
          cleanPhoneNumber = '+$cleanPhoneNumber';
        }
      }
      
      // Remove + for API call (WhatsApp API expects numbers without +)
      final apiPhoneNumber = cleanPhoneNumber.substring(1);
      
      print('📞 Phone number processing:');
      print('   Original: $phoneNumber');
      print('   Formatted: $cleanPhoneNumber');
      print('   For API: $apiPhoneNumber');
      
      // Check if we're in development mode or WhatsApp is not configured
      if (EnvironmentService.isDevelopmentMode || !EnvironmentService.isWhatsappConfigured) {
        print('=== DEVELOPMENT MODE ===');
        print('Verification code generated: $code');
        print('Phone number: $cleanPhoneNumber');
        print('Message: $message');
        print('========================');
        
        // Simulate API delay
        await Future.delayed(const Duration(milliseconds: 500));
        return;
      }

      // Production WhatsApp Business API integration using templates
      // Note: WhatsApp Business API requires approved templates for business-initiated messages
      
      // Your approved template: "*{{1}}* is your verification code. For your security, please do not share this code."
      // Language: English, with Copy Code button
      // Template format for your WhatsApp OTP template with *{{1}}* parameter and Copy Code button
      final templates = [
        // Your verification_code template with body parameter and button
        {
          'name': 'verification_code',
          'language': {'code': 'en'},
          'components': [
            {
              'type': 'body',
              'parameters': [
                {'type': 'text', 'text': code}
              ]
            },
            {
              'type': 'button',
              'sub_type': 'url',
              'index': 0,
              'parameters': [
                {'type': 'text', 'text': code}
              ]
            }
          ]
        }
      ];

      final requestBody = {
        'messaging_product': 'whatsapp',
        'to': apiPhoneNumber,
        'type': 'template',
        'template': templates[0]
      };

      print('=== WHATSAPP API REQUEST ===');
      print('Template: verification_code');
      print('Language: en');
      print('URL: ${EnvironmentService.whatsappApiBaseUrl}');
      print('Phone: $apiPhoneNumber');
      print('Code: $code');
      print('Full Request Body: ${jsonEncode(requestBody)}');
      print('============================');

      final response = await http.post(
        Uri.parse(EnvironmentService.whatsappApiBaseUrl),
        headers: {
          'Authorization': 'Bearer ${EnvironmentService.whatsappAccessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('=== WHATSAPP API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=============================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ SUCCESS: Verification code sent!');
        print('Message ID: ${responseData['messages']?[0]?['id']}');
        print('📱 You should receive: "*$code* is your verification code. For your security, do not share this code."');
        print('🔘 Message includes "Copy Code" button and expires in 10 minutes');
        print('💡 Message should arrive within 30 seconds!');
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ WhatsApp API Error:');
        print('Status: ${response.statusCode}');
        print('Error: ${errorData['error']?['message'] ?? 'Unknown error'}');
        print('Full Error Data: $errorData');
        
        throw WhatsAppApiException(
          'Failed to send WhatsApp message: ${errorData['error']?['message'] ?? 'Unknown error'}',
          response.statusCode,
          errorData,
        );
      }
      
    } catch (e) {
      if (e is WhatsAppApiException) {
        rethrow;
      }
      print('Error sending WhatsApp message: $e');
      throw Exception('Failed to send verification code via WhatsApp: $e');
    }
  }

  Future<bool> verifyCode(String inputCode, String phoneNumber, [String? userId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedCode = prefs.getString(_verificationCodeKey);
      final storedPhone = prefs.getString(_phoneNumberKey);
      final timestamp = prefs.getInt(_timestampKey);

      if (storedCode == null || storedPhone == null || timestamp == null) {
        throw Exception('No verification code found. Please request a new code.');
      }

      if (storedPhone != phoneNumber) {
        throw Exception('Phone number mismatch.');
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final elapsedMinutes = (currentTime - timestamp) / (1000 * 60);

      if (elapsedMinutes > _codeExpirationMinutes) {
        await _clearVerificationData();
        throw Exception('Verification code has expired. Please request a new code.');
      }

      if (storedCode == inputCode) {
        await _clearVerificationData();
        await _setTwoFactorVerified(true, phoneNumber, userId);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Verification failed: $e');
    }
  }

  Future<void> _clearVerificationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_verificationCodeKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_timestampKey);
  }

  Future<void> _setTwoFactorVerified(bool isVerified, String phoneNumber, [String? userId]) async {
    // Save to SharedPreferences for immediate local access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_twoFactorVerifiedKey, isVerified);
    
    // Save to Firebase for persistence across sessions
    if (isVerified && userId != null) {
      await _saveToFirebase(phoneNumber, userId);
    }
  }
  
  Future<void> _saveToFirebase(String phoneNumber, [String? userId]) async {
    try {
      if (userId == null) {
        print('❌ UserId is required to save to Firebase');
        return;
      }
      
      // Get current user data from Firebase
      final currentUser = await _firestoreService.getUser(userId);
      if (currentUser != null) {
        // Create updated user model with two-factor enabled
        final updatedUser = UserModel(
          uid: currentUser.uid,
          email: currentUser.email,
          name: currentUser.name,
          photoUrl: currentUser.photoUrl,
          notificationsEnabled: currentUser.notificationsEnabled,
          language: currentUser.language,
          twoFactorEnabled: true,
        );
        
        // Update in Firebase
        await _firestoreService.updateUser(updatedUser);
        print('✅ Two-factor authentication status saved to Firebase');
      }
    } catch (e) {
      print('❌ Error saving two-factor status to Firebase: $e');
      // Don't throw error - local verification still works
    }
  }

  Future<bool> isTwoFactorVerified([String? userId]) async {
    try {
      // First check Firebase if userId is provided
      if (userId != null) {
        final userData = await _firestoreService.getUser(userId);
        if (userData != null) {
          // Update local SharedPreferences with Firebase data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_twoFactorVerifiedKey, userData.twoFactorEnabled);
          return userData.twoFactorEnabled;
        }
      }
      
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_twoFactorVerifiedKey) ?? false;
    } catch (e) {
      print('❌ Error checking two-factor status: $e');
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_twoFactorVerifiedKey) ?? false;
    }
  }

  Future<void> resetTwoFactorVerification([String? userId]) async {
    try {
      // Update local SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_twoFactorVerifiedKey, false);
      
      // Update Firebase if userId provided
      if (userId != null) {
        final currentUser = await _firestoreService.getUser(userId);
        if (currentUser != null) {
          final updatedUser = UserModel(
            uid: currentUser.uid,
            email: currentUser.email,
            name: currentUser.name,
            photoUrl: currentUser.photoUrl,
            notificationsEnabled: currentUser.notificationsEnabled,
            language: currentUser.language,
            twoFactorEnabled: false,
          );
          
          await _firestoreService.updateUser(updatedUser);
          print('✅ Two-factor authentication disabled in Firebase');
        }
      }
    } catch (e) {
      print('❌ Error resetting two-factor status: $e');
    }
  }

  String hashString(String code) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}