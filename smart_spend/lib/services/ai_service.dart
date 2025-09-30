import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  late GenerativeModel _model;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in environment variables');
      }
      
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
      
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize AI service: $e');
    }
  }

  Future<String> getFinancialAdvice(String question, Map<String, dynamic> userFinancialData) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final prompt = _buildFinancialPrompt(question, userFinancialData);
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? 'Sorry, I could not generate a response. Please try again.';
    } catch (e) {
      return 'I encountered an error while processing your request. Please check your internet connection and try again.';
    }
  }

  String _buildFinancialPrompt(String question, Map<String, dynamic> financialData) {
    final totalIncome = financialData['totalIncome'] ?? 0.0;
    final totalExpenses = financialData['totalExpenses'] ?? 0.0;
    final balance = financialData['balance'] ?? 0.0;
    final topExpenseCategories = financialData['topExpenseCategories'] ?? [];
    final incomeCategories = financialData['incomeCategories'] ?? [];

    return '''
You are a professional financial advisor helping users with their personal finance management. 
Please provide helpful, practical, and actionable financial advice based on the user's question and financial situation.

User's Current Financial Situation:
- Total Monthly Income: RM ${totalIncome.toStringAsFixed(2)}
- Total Monthly Expenses: RM ${totalExpenses.toStringAsFixed(2)}
- Current Balance: RM ${balance.toStringAsFixed(2)}
- Top Expense Categories: ${topExpenseCategories.join(', ')}
- Income Sources: ${incomeCategories.join(', ')}

User's Question: $question

Please provide:
1. A clear and concise answer to their question
2. Specific actionable advice based on their financial data
3. Practical tips they can implement immediately
4. Any warnings or considerations they should be aware of

Keep your response conversational, empathetic, and easy to understand. Focus on practical advice that's relevant to their current financial situation.
''';
  }

  Future<List<String>> getFinancialInsights(Map<String, dynamic> financialData) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final prompt = _buildInsightsPrompt(financialData);
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final responseText = response.text ?? '';
      
      // Parse the response into a list of insights
      return responseText
          .split('\n')
          .where((line) => line.trim().isNotEmpty && line.trim().startsWith('•'))
          .map((line) => line.trim().substring(1).trim())
          .toList();
    } catch (e) {
      return [
        'Unable to generate insights at the moment. Please try again later.',
      ];
    }
  }

  String _buildInsightsPrompt(Map<String, dynamic> financialData) {
    final totalIncome = financialData['totalIncome'] ?? 0.0;
    final totalExpenses = financialData['totalExpenses'] ?? 0.0;
    final balance = financialData['balance'] ?? 0.0;
    final topExpenseCategories = financialData['topExpenseCategories'] ?? [];

    return '''
Analyze the following financial data and provide 3-5 key insights about the user's financial health and spending patterns.

Financial Data:
- Total Monthly Income: RM ${totalIncome.toStringAsFixed(2)}
- Total Monthly Expenses: RM ${totalExpenses.toStringAsFixed(2)}
- Current Balance: RM ${balance.toStringAsFixed(2)}
- Top Expense Categories: ${topExpenseCategories.join(', ')}

Please provide insights in the following format:
• [Insight about spending patterns]
• [Insight about savings potential]
• [Insight about financial health]
• [Actionable recommendation]
• [Warning or area of concern if any]

Each insight should be concise, specific, and actionable. Focus on the most important observations about their financial situation.
''';
  }

  Future<List<String>> getSavingsTips(Map<String, dynamic> financialData) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final prompt = _buildSavingsTipsPrompt(financialData);
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final responseText = response.text ?? '';
      
      return responseText
          .split('\n')
          .where((line) => line.trim().isNotEmpty && line.trim().startsWith('•'))
          .map((line) => line.trim().substring(1).trim())
          .toList();
    } catch (e) {
      return [
        'Unable to generate savings tips at the moment. Please try again later.',
      ];
    }
  }

  String _buildSavingsTipsPrompt(Map<String, dynamic> financialData) {
    final totalIncome = financialData['totalIncome'] ?? 0.0;
    final totalExpenses = financialData['totalExpenses'] ?? 0.0;
    final topExpenseCategories = financialData['topExpenseCategories'] ?? [];

    return '''
Based on the financial data below, provide 5 specific and actionable savings tips tailored to this user's situation.

Financial Data:
- Total Monthly Income: RM ${totalIncome.toStringAsFixed(2)}
- Total Monthly Expenses: RM ${totalExpenses.toStringAsFixed(2)}
- Top Expense Categories: ${topExpenseCategories.join(', ')}

Provide savings tips in the following format:
• [Specific savings tip related to their expense categories]
• [Practical way to reduce expenses]
• [Investment or savings strategy]
• [Lifestyle adjustment suggestion]
• [Emergency fund or future planning tip]

Each tip should be:
- Specific and actionable
- Relevant to their current expense patterns
- Realistic and achievable
- Include approximate savings amounts when possible
''';
  }
}