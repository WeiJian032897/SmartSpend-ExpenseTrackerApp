import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      await dotenv.load(fileName: ".env");
      _initialized = true;
    }
  }

  static String get whatsappPhoneNumberId {
    return dotenv.env['WHATSAPP_PHONE_NUMBER_ID'] ?? '';
  }

  static String get whatsappAccessToken {
    return dotenv.env['WHATSAPP_ACCESS_TOKEN'] ?? '';
  }

  static String get whatsappApiVersion {
    return dotenv.env['WHATSAPP_API_VERSION'] ?? 'v18.0';
  }

  static bool get isDevelopmentMode {
    return dotenv.env['DEVELOPMENT_MODE']?.toLowerCase() == 'true';
  }

  static bool get isWhatsappConfigured {
    return whatsappPhoneNumberId.isNotEmpty && 
           whatsappAccessToken.isNotEmpty &&
           whatsappPhoneNumberId != 'your_phone_number_id_here' &&
           whatsappAccessToken != 'your_access_token_here';
  }

  static String get whatsappApiBaseUrl {
    return 'https://graph.facebook.com/$whatsappApiVersion/$whatsappPhoneNumberId/messages';
  }
}