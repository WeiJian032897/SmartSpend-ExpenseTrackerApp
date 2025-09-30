import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'SmartSpend'**
  String get appTitle;

  /// Welcome message for login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// Subtitle for login screen
  ///
  /// In en, this message translates to:
  /// **'Ready to take control of your finances?'**
  String get readyToTakeControl;

  /// Email input placeholder
  ///
  /// In en, this message translates to:
  /// **'Your Email'**
  String get yourEmail;

  /// Password input placeholder
  ///
  /// In en, this message translates to:
  /// **'Your Password'**
  String get yourPassword;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forget Password?'**
  String get forgetPassword;

  /// Alternative sign in options text
  ///
  /// In en, this message translates to:
  /// **'Or Sign In With'**
  String get orSignInWith;

  /// Google sign in button text
  ///
  /// In en, this message translates to:
  /// **'Continue With Google'**
  String get continueWithGoogle;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Link to registration screen
  ///
  /// In en, this message translates to:
  /// **'Don\'t Have An Account Yet? Sign Up'**
  String get dontHaveAccount;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'My Settings'**
  String get mySettings;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Notification setting
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Record setting
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// Security setting
  ///
  /// In en, this message translates to:
  /// **'Security & Password'**
  String get securityPassword;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Simplified Chinese language option
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get chinese;

  /// Search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Planning tab
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get planning;

  /// Statistics tab
  ///
  /// In en, this message translates to:
  /// **'Statistic'**
  String get statistic;

  /// Total balance label
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// Expense section title
  ///
  /// In en, this message translates to:
  /// **'Expend'**
  String get expend;

  /// Top expenses section title
  ///
  /// In en, this message translates to:
  /// **'Top Expenses'**
  String get topExpenses;

  /// View all button text
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// Afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// Evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// Night greeting
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get goodNight;

  /// Financial planning title
  ///
  /// In en, this message translates to:
  /// **'Financial Planning'**
  String get financialPlanning;

  /// Add plan button
  ///
  /// In en, this message translates to:
  /// **'Add Plan'**
  String get addPlan;

  /// Empty state for expenses
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesYet;

  /// Empty state instruction
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add your first expense'**
  String get tapToAddExpense;

  /// Session expired message
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get sessionExpired;

  /// Current week label
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// Previous week label
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// Weeks ago label
  ///
  /// In en, this message translates to:
  /// **'{count} Weeks Ago'**
  String weeksAgo(int count);

  /// Week selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Week'**
  String get selectWeek;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Data loading error message
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No account setup title
  ///
  /// In en, this message translates to:
  /// **'No Account Setup'**
  String get noAccountSetup;

  /// Create first account instruction
  ///
  /// In en, this message translates to:
  /// **'Create your first account to start\ntracking your expenses'**
  String get createFirstAccount;

  /// Create account button
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Current account label
  ///
  /// In en, this message translates to:
  /// **'Current Account'**
  String get currentAccount;

  /// Available balance label
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// Tap to switch instruction
  ///
  /// In en, this message translates to:
  /// **'Tap to switch'**
  String get tapToSwitch;

  /// Daily average label
  ///
  /// In en, this message translates to:
  /// **'Daily Avg'**
  String get dailyAvg;

  /// Highest spending day label
  ///
  /// In en, this message translates to:
  /// **'Highest Day'**
  String get highestDay;

  /// None label
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Financial overview subtitle
  ///
  /// In en, this message translates to:
  /// **'Here\'s your financial overview'**
  String get hereIsYourFinancialOverview;

  /// Financial health score title
  ///
  /// In en, this message translates to:
  /// **'Your Financial Health Score'**
  String get yourFinancialHealthScore;

  /// Total expenses label
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// Total income label
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// Current balance label
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// Net savings label
  ///
  /// In en, this message translates to:
  /// **'Net Savings'**
  String get netSavings;

  /// View transaction history button
  ///
  /// In en, this message translates to:
  /// **'View Transaction History'**
  String get viewTransactionHistory;

  /// Default user name
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Excellent rating
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// Great rating
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get great;

  /// Good rating
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// Fair rating
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// Poor rating
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// Quick actions section title
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Charts screen title
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get charts;

  /// Income section title
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// Expenses section title
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No income data message
  ///
  /// In en, this message translates to:
  /// **'No Income Data'**
  String get noIncomeData;

  /// Add income instruction message
  ///
  /// In en, this message translates to:
  /// **'You need to add your income before you can see the pie chart 😊'**
  String get needToAddIncome;

  /// No expense data message
  ///
  /// In en, this message translates to:
  /// **'No Expense Data'**
  String get noExpenseData;

  /// Add expenses instruction message
  ///
  /// In en, this message translates to:
  /// **'You need to add your expenses before you can see the pie chart 😊'**
  String get needToAddExpenses;

  /// Empty state message for charts
  ///
  /// In en, this message translates to:
  /// **'Start by adding some transactions!'**
  String get startByAddingTransactions;

  /// Breakdown section title
  ///
  /// In en, this message translates to:
  /// **'Breakdown by Category'**
  String get breakdownByCategory;

  /// Other category label
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// AI screen title
  ///
  /// In en, this message translates to:
  /// **'AI Financial Assistant'**
  String get aiFinancialAssistant;

  /// AI assistant welcome message
  ///
  /// In en, this message translates to:
  /// **'Ask me anything about your finances!'**
  String get askMeAboutFinances;

  /// Financial overview section title
  ///
  /// In en, this message translates to:
  /// **'Financial Overview'**
  String get financialOverview;

  /// Balance label
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// AI insights section title
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get aiInsights;

  /// Loading insights message
  ///
  /// In en, this message translates to:
  /// **'Loading insights...'**
  String get loadingInsights;

  /// Savings tips section title
  ///
  /// In en, this message translates to:
  /// **'Savings Tips'**
  String get savingsTips;

  /// Loading tips message
  ///
  /// In en, this message translates to:
  /// **'Loading tips...'**
  String get loadingTips;

  /// Input field placeholder
  ///
  /// In en, this message translates to:
  /// **'Ask me about your finances...'**
  String get askAboutFinances;

  /// Delete planned payment dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Planned Payment'**
  String get deletePlannedPayment;

  /// Planning overview section title
  ///
  /// In en, this message translates to:
  /// **'Planning Overview'**
  String get planningOverview;

  /// Planning section subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your future payments'**
  String get manageFuturePayments;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Generate QR report dialog title
  ///
  /// In en, this message translates to:
  /// **'Generate QR Report'**
  String get generateQRReport;

  /// Weekly report button
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get weeklyReport;

  /// Monthly report button
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthlyReport;

  /// Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Danger zone section title
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// Delete account button
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Re-authentication required message
  ///
  /// In en, this message translates to:
  /// **'For security reasons, please sign out and sign in again, then try deleting your account.'**
  String get securityReasonReauth;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
