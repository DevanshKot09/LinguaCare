import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LinguaCare'**
  String get appTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Every voice, understood'**
  String get splashTagline;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Understand DLD'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Learn about Developmental Language Disorder and how it affects communication.'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Spot early signs'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Identify early signs across age bands to provide timely support.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Practise a little every day'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Engage in fun, evidence-informed daily activities designed for growth.'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Work together'**
  String get onboardingTitle4;

  /// No description provided for @onboardingSubtitle4.
  ///
  /// In en, this message translates to:
  /// **'Collaborate seamlessly between parents, teachers, and specialists.'**
  String get onboardingSubtitle4;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to LinguaCare'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your supportive companion for Developmental Language Disorder.'**
  String get welcomeSubtitle;

  /// No description provided for @nonDiagnosticNotice.
  ///
  /// In en, this message translates to:
  /// **'LinguaCare supports language development. It does not diagnose.'**
  String get nonDiagnosticNotice;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @authPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Authentication feature coming in Phase 2.'**
  String get authPlaceholder;

  /// No description provided for @roleSetupPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Role setup feature coming in Phase 2.'**
  String get roleSetupPlaceholder;

  /// No description provided for @parentRole.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parentRole;

  /// No description provided for @teacherRole.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacherRole;

  /// No description provided for @adultRole.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get adultRole;

  /// No description provided for @specialistRole.
  ///
  /// In en, this message translates to:
  /// **'Specialist'**
  String get specialistRole;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabPractise.
  ///
  /// In en, this message translates to:
  /// **'Practise'**
  String get tabPractise;

  /// No description provided for @tabLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get tabLearn;

  /// No description provided for @tabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tabProgress;

  /// No description provided for @tabFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get tabFamily;

  /// No description provided for @tabStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get tabStudents;

  /// No description provided for @tabStrategies.
  ///
  /// In en, this message translates to:
  /// **'Strategies'**
  String get tabStrategies;

  /// No description provided for @tabObservations.
  ///
  /// In en, this message translates to:
  /// **'Observations'**
  String get tabObservations;

  /// No description provided for @tabJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get tabJournal;

  /// No description provided for @tabMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get tabMe;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @tabClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get tabClients;

  /// No description provided for @tabPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get tabPlans;

  /// No description provided for @tabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get tabLibrary;

  /// No description provided for @tabMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get tabMessages;

  /// No description provided for @debugRoleSwitcher.
  ///
  /// In en, this message translates to:
  /// **'Debug Role Switcher'**
  String get debugRoleSwitcher;

  /// No description provided for @debugFirstLaunch.
  ///
  /// In en, this message translates to:
  /// **'First Launch'**
  String get debugFirstLaunch;

  /// No description provided for @debugSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed In'**
  String get debugSignedIn;

  /// No description provided for @configErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Configuration Error'**
  String get configErrorTitle;

  /// No description provided for @configErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Missing Supabase URL or Anon Key. Please ensure env/dev.json is provided via --dart-define-from-file.'**
  String get configErrorMessage;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters with letters and numbers'**
  String get passwordRequirements;

  /// No description provided for @termsAgreement.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get termsAgreement;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists with this email, instructions have been sent.'**
  String get resetEmailSent;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your email'**
  String get enterVerificationCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(Object seconds);

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @googleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get googleSignIn;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get dontHaveAccount;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @termsRequired.
  ///
  /// In en, this message translates to:
  /// **'You must agree to the Terms and Privacy Policy'**
  String get termsRequired;

  /// No description provided for @languageCheck.
  ///
  /// In en, this message translates to:
  /// **'Language Check'**
  String get languageCheck;

  /// No description provided for @languageCheckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A gentle questionnaire to check language development and identify areas to watch.'**
  String get languageCheckSubtitle;

  /// No description provided for @startCheck.
  ///
  /// In en, this message translates to:
  /// **'Start Check'**
  String get startCheck;

  /// No description provided for @resumeCheck.
  ///
  /// In en, this message translates to:
  /// **'Resume Check'**
  String get resumeCheck;

  /// No description provided for @screeningHistory.
  ///
  /// In en, this message translates to:
  /// **'Screening History'**
  String get screeningHistory;

  /// No description provided for @noScreeningsYet.
  ///
  /// In en, this message translates to:
  /// **'No screening checks completed yet.'**
  String get noScreeningsYet;

  /// No description provided for @noChildForScreening.
  ///
  /// In en, this message translates to:
  /// **'Please add a child profile first to run a language check.'**
  String get noChildForScreening;

  /// No description provided for @addChild.
  ///
  /// In en, this message translates to:
  /// **'Add Child'**
  String get addChild;

  /// No description provided for @prototypeBanner.
  ///
  /// In en, this message translates to:
  /// **'Prototype - not clinically validated'**
  String get prototypeBanner;

  /// No description provided for @screeningNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Screening is not available in this version yet.'**
  String get screeningNotAvailable;

  /// No description provided for @questionnaireIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Check Overview'**
  String get questionnaireIntroTitle;

  /// No description provided for @questionnaireIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What to expect'**
  String get questionnaireIntroSubtitle;

  /// No description provided for @questionnaireIntroDesc.
  ///
  /// In en, this message translates to:
  /// **'This check takes about 5 minutes. You will be asked observable, everyday communication questions, one at a time. You can pause or exit at any time and resume later. This is a supportive screening tool, not a medical diagnosis.'**
  String get questionnaireIntroDesc;

  /// No description provided for @privacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Your answers stay on your account and are shared with no one unless you choose to share them later.'**
  String get privacyNotice;

  /// No description provided for @questionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionProgress(Object current, Object total);

  /// No description provided for @optionRarely.
  ///
  /// In en, this message translates to:
  /// **'Rarely or never'**
  String get optionRarely;

  /// No description provided for @optionSometimes.
  ///
  /// In en, this message translates to:
  /// **'Sometimes'**
  String get optionSometimes;

  /// No description provided for @optionOften.
  ///
  /// In en, this message translates to:
  /// **'Often'**
  String get optionOften;

  /// No description provided for @optionAlmostAlways.
  ///
  /// In en, this message translates to:
  /// **'Almost always'**
  String get optionAlmostAlways;

  /// No description provided for @optionNotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get optionNotSure;

  /// No description provided for @pauseAndExit.
  ///
  /// In en, this message translates to:
  /// **'Pause & Exit'**
  String get pauseAndExit;

  /// No description provided for @pauseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause Screening?'**
  String get pauseConfirmTitle;

  /// No description provided for @pauseConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your progress has been saved locally. You can resume anytime from where you left off.'**
  String get pauseConfirmMessage;

  /// No description provided for @resumeLater.
  ///
  /// In en, this message translates to:
  /// **'Resume Later'**
  String get resumeLater;

  /// No description provided for @exitWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitWithoutSaving;

  /// No description provided for @continueCheck.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueCheck;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Check Results'**
  String get reportTitle;

  /// No description provided for @strengthsFirst.
  ///
  /// In en, this message translates to:
  /// **'Strengths & Thriving Areas'**
  String get strengthsFirst;

  /// No description provided for @areasToWatch.
  ///
  /// In en, this message translates to:
  /// **'Areas to Watch'**
  String get areasToWatch;

  /// No description provided for @alsoCheckWithProfessional.
  ///
  /// In en, this message translates to:
  /// **'Also worth checking with a professional'**
  String get alsoCheckWithProfessional;

  /// No description provided for @hearingCheckAlways.
  ///
  /// In en, this message translates to:
  /// **'A hearing check is recommended whenever language difficulties or concerns are noted.'**
  String get hearingCheckAlways;

  /// No description provided for @urgentNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Important Recommendation'**
  String get urgentNoticeTitle;

  /// No description provided for @urgentNoticeMessage.
  ///
  /// In en, this message translates to:
  /// **'Based on your answers regarding sudden changes or hearing responsiveness, we strongly recommend speaking with a speech-language professional or pediatrician soon.'**
  String get urgentNoticeMessage;

  /// No description provided for @confidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {level} ({completeness}% answered)'**
  String confidenceLabel(Object completeness, Object level);

  /// No description provided for @confidenceExplanation.
  ///
  /// In en, this message translates to:
  /// **'Confidence is based on the proportion of questions answered.'**
  String get confidenceExplanation;

  /// No description provided for @whatYouCanDoNext.
  ///
  /// In en, this message translates to:
  /// **'What you can do next'**
  String get whatYouCanDoNext;

  /// No description provided for @learnMoreLink.
  ///
  /// In en, this message translates to:
  /// **'Explore Learn articles about language development'**
  String get learnMoreLink;

  /// No description provided for @findSpecialistComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Find a specialist (Coming soon in Phase 4)'**
  String get findSpecialistComingSoon;

  /// No description provided for @shareWithTeacherComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Share with teacher (Coming soon in Phase 4)'**
  String get shareWithTeacherComingSoon;

  /// No description provided for @deleteResult.
  ///
  /// In en, this message translates to:
  /// **'Delete Result'**
  String get deleteResult;

  /// No description provided for @deleteResultConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Result?'**
  String get deleteResultConfirmTitle;

  /// No description provided for @deleteResultConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this screening result? This cannot be undone.'**
  String get deleteResultConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @trendHeading.
  ///
  /// In en, this message translates to:
  /// **'Recent Trend'**
  String get trendHeading;

  /// No description provided for @trendStable.
  ///
  /// In en, this message translates to:
  /// **'Stable profile across recent checks'**
  String get trendStable;

  /// No description provided for @trendImproving.
  ///
  /// In en, this message translates to:
  /// **'Signs improving across recent checks'**
  String get trendImproving;

  /// No description provided for @trendNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Signs persist across recent checks'**
  String get trendNeedsAttention;

  /// No description provided for @appStartErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not start the app'**
  String get appStartErrorTitle;

  /// No description provided for @appStartErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get appStartErrorSubtitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
