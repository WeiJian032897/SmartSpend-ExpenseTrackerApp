import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../../providers/expense_provider.dart';
import '../../services/ai_service.dart';
import '../../utils/colors.dart';
import '../../utils/text_formatter.dart';
import '../../l10n/app_localizations.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  List<String> _insights = [];
  List<String> _savingsTips = [];
  bool _showInsights = true;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    try {
      await _aiService.initialize();
      setState(() => _isInitialized = true);
      _loadInsightsAndTips();
    } catch (e) {
      setState(() => _isInitialized = false);
      _showErrorSnackBar('Failed to initialize AI service. Please check your API key.');
    }
  }

  Future<void> _loadInsightsAndTips() async {
    final financialData = _getFinancialData();
    
    try {
      final insights = await _aiService.getFinancialInsights(financialData);
      final tips = await _aiService.getSavingsTips(financialData);
      
      setState(() {
        _insights = insights;
        _savingsTips = tips;
      });
    } catch (e) {
      // Silently fail - insights are optional
    }
  }

  Map<String, dynamic> _getFinancialData() {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final expenses = expenseProvider.expenses;
    
    final incomeList = expenses.where((e) => e.isIncome).toList();
    final expenseList = expenses.where((e) => !e.isIncome).toList();
    
    final totalIncome = incomeList.fold(0.0, (sum, expense) => sum + expense.amount);
    final totalExpenses = expenseList.fold(0.0, (sum, expense) => sum + expense.amount);
    
    final expensesByCategory = <String, double>{};
    for (final expense in expenseList) {
      final category = expense.category.isEmpty ? (AppLocalizations.of(context)?.other ?? 'Other') : expense.category;
      expensesByCategory[category] = (expensesByCategory[category] ?? 0) + expense.amount;
    }
    
    final topExpenseCategories = expensesByCategory.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(3)
        .map((e) => e.key)
        .toList();

    final incomeByCategory = <String, double>{};
    for (final income in incomeList) {
      final category = income.category.isEmpty ? (AppLocalizations.of(context)?.other ?? 'Other') : income.category;
      incomeByCategory[category] = (incomeByCategory[category] ?? 0) + income.amount;
    }
    
    final incomeCategories = incomeByCategory.keys.toList();

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'balance': totalIncome - totalExpenses,
      'topExpenseCategories': topExpenseCategories,
      'incomeCategories': incomeCategories,
    };
  }

  Future<void> _sendMessage() async {
    if (_questionController.text.trim().isEmpty || _isLoading || !_isInitialized) return;

    final question = _questionController.text.trim();
    _questionController.clear();

    setState(() {
      _showInsights = false; // Switch to chat view
      _messages.add(ChatMessage(text: question, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final financialData = _getFinancialData();
      final response = await _aiService.getFinancialAdvice(question, financialData);
      
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: 'Sorry, I encountered an error. Please try again.', isUser: false));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.aiFinancialAssistant ?? 'AI Financial Assistant'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showInsights ? Icons.chat : Icons.insights),
            onPressed: () => setState(() => _showInsights = !_showInsights),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showInsights) _buildInsightsSection() else _buildChatSection(),
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFinancialOverview(),
            const SizedBox(height: 20),
            _buildInsightsCard(),
            const SizedBox(height: 20),
            _buildSavingsTipsCard(),
            const SizedBox(height: 20),
            _buildQuickQuestions(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatSection() {
    return Expanded(
      child: Column(
        children: [
          if (_messages.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.psychology,
                        size: 40,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'AI Financial Assistant',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context)?.askMeAboutFinances ?? 'Ask me anything about your finances!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    return _buildMessageBubble(_messages[index]);
                  } else {
                    return _buildTypingIndicator();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview() {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        final financialData = _getFinancialData();
        final totalIncome = financialData['totalIncome'] as double;
        final totalExpenses = financialData['totalExpenses'] as double;
        final balance = financialData['balance'] as double;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryBlue.withValues(alpha: 0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Financial Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildOverviewItem(AppLocalizations.of(context)?.income ?? 'Income', totalIncome, AppColors.green, Icons.trending_up),
                  _buildOverviewItem(AppLocalizations.of(context)?.expenses ?? 'Expenses', totalExpenses, Colors.red, Icons.trending_down),
                  _buildOverviewItem(AppLocalizations.of(context)?.balance ?? 'Balance', balance, balance >= 0 ? AppColors.green : Colors.red, Icons.account_balance),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewItem(String label, double amount, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          'RM ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_insights.isEmpty)
            Text(AppLocalizations.of(context)?.loadingInsights ?? 'Loading insights...')
          else
            ..._insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: _buildFormattedText(insight, const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black87,
                    )),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildSavingsTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings_outlined, color: AppColors.green),
              const SizedBox(width: 8),
              const Text(
                'Savings Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_savingsTips.isEmpty)
            Text(AppLocalizations.of(context)?.loadingTips ?? 'Loading tips...')
          else
            ..._savingsTips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: _buildFormattedText(tip, const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black87,
                    )),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    final questions = [
      'How can I reduce my monthly expenses?',
      'What\'s a good savings goal for me?',
      'Should I invest with my current income?',
      'How can I improve my financial health?',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Questions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: questions.map((question) => GestureDetector(
            onTap: () {
              setState(() {
                _showInsights = false;
                _questionController.text = question;
              });
              _sendMessage();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Text(
                question,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: message.isUser ? AppColors.primaryBlue : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: message.isUser 
                ? Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  )
                : _buildFormattedText(message.text, const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  )),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Thinking...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    if (!_isInitialized) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI service is not available. Please check your API configuration.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  hintText: 'Ask me about your finances...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey : AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, TextStyle style) {
    try {
      return MarkdownWidget(
        data: text,
        shrinkWrap: true,
      );
    } catch (e) {
      // Fallback to simple formatting if MarkdownWidget fails
      return TextFormatter.formatSimpleMarkdown(text, style: style);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  
  ChatMessage({required this.text, required this.isUser});
}