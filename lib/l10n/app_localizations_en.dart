// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LinguaCare';

  @override
  String get splashTagline => 'Every voice, understood';

  @override
  String get onboardingTitle1 => 'Understand DLD';

  @override
  String get onboardingSubtitle1 =>
      'Learn about Developmental Language Disorder and how it affects communication.';

  @override
  String get onboardingTitle2 => 'Spot early signs';

  @override
  String get onboardingSubtitle2 =>
      'Identify early signs across age bands to provide timely support.';

  @override
  String get onboardingTitle3 => 'Practise a little every day';

  @override
  String get onboardingSubtitle3 =>
      'Engage in fun, evidence-informed daily activities designed for growth.';

  @override
  String get onboardingTitle4 => 'Work together';

  @override
  String get onboardingSubtitle4 =>
      'Collaborate seamlessly between parents, teachers, and specialists.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get welcomeTitle => 'Welcome to LinguaCare';

  @override
  String get welcomeSubtitle =>
      'Your supportive companion for Developmental Language Disorder.';

  @override
  String get nonDiagnosticNotice =>
      'LinguaCare supports language development. It does not diagnose.';

  @override
  String get signUp => 'Sign Up';

  @override
  String get logIn => 'Log In';

  @override
  String get authPlaceholder => 'Authentication feature coming in Phase 2.';

  @override
  String get roleSetupPlaceholder => 'Role setup feature coming in Phase 2.';

  @override
  String get parentRole => 'Parent';

  @override
  String get teacherRole => 'Teacher';

  @override
  String get adultRole => 'Adult';

  @override
  String get specialistRole => 'Specialist';

  @override
  String get tabHome => 'Home';

  @override
  String get tabPractise => 'Practise';

  @override
  String get tabLearn => 'Learn';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabFamily => 'Family';

  @override
  String get tabStudents => 'Students';

  @override
  String get tabStrategies => 'Strategies';

  @override
  String get tabObservations => 'Observations';

  @override
  String get tabJournal => 'Journal';

  @override
  String get tabMe => 'Me';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabClients => 'Clients';

  @override
  String get tabPlans => 'Plans';

  @override
  String get tabLibrary => 'Library';

  @override
  String get tabMessages => 'Messages';

  @override
  String get debugRoleSwitcher => 'Debug Role Switcher';

  @override
  String get debugFirstLaunch => 'First Launch';

  @override
  String get debugSignedIn => 'Signed In';

  @override
  String get configErrorTitle => 'Configuration Error';

  @override
  String get configErrorMessage =>
      'Missing Supabase URL or Anon Key. Please ensure env/dev.json is provided via --dart-define-from-file.';

  @override
  String get email => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordRequirements =>
      'At least 8 characters with letters and numbers';

  @override
  String get termsAgreement =>
      'I agree to the Terms of Service and Privacy Policy';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetEmailSent =>
      'If an account exists with this email, instructions have been sent.';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get enterVerificationCode =>
      'Enter the 6-digit code sent to your email';

  @override
  String get resendCode => 'Resend Code';

  @override
  String resendIn(Object seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String get googleSignIn => 'Continue with Google';

  @override
  String get orDivider => 'or';

  @override
  String get alreadyHaveAccount => 'Already have an account? Log in';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign up';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get termsRequired => 'You must agree to the Terms and Privacy Policy';

  @override
  String get languageCheck => 'Language Check';

  @override
  String get languageCheckSubtitle =>
      'A gentle questionnaire to check language development and identify areas to watch.';

  @override
  String get startCheck => 'Start Check';

  @override
  String get resumeCheck => 'Resume Check';

  @override
  String get screeningHistory => 'Screening History';

  @override
  String get noScreeningsYet => 'No screening checks completed yet.';

  @override
  String get noChildForScreening =>
      'Please add a child profile first to run a language check.';

  @override
  String get addChild => 'Add Child';

  @override
  String get prototypeBanner => 'Prototype - not clinically validated';

  @override
  String get screeningNotAvailable =>
      'Screening is not available in this version yet.';

  @override
  String get questionnaireIntroTitle => 'Language Check Overview';

  @override
  String get questionnaireIntroSubtitle => 'What to expect';

  @override
  String get questionnaireIntroDesc =>
      'This check takes about 5 minutes. You will be asked observable, everyday communication questions, one at a time. You can pause or exit at any time and resume later. This is a supportive screening tool, not a medical diagnosis.';

  @override
  String get privacyNotice =>
      'Your answers stay on your account and are shared with no one unless you choose to share them later.';

  @override
  String questionProgress(Object current, Object total) {
    return 'Question $current of $total';
  }

  @override
  String get optionRarely => 'Rarely or never';

  @override
  String get optionSometimes => 'Sometimes';

  @override
  String get optionOften => 'Often';

  @override
  String get optionAlmostAlways => 'Almost always';

  @override
  String get optionNotSure => 'Not sure';

  @override
  String get pauseAndExit => 'Pause & Exit';

  @override
  String get pauseConfirmTitle => 'Pause Screening?';

  @override
  String get pauseConfirmMessage =>
      'Your progress has been saved locally. You can resume anytime from where you left off.';

  @override
  String get resumeLater => 'Resume Later';

  @override
  String get exitWithoutSaving => 'Exit';

  @override
  String get continueCheck => 'Continue';

  @override
  String get reportTitle => 'Language Check Results';

  @override
  String get strengthsFirst => 'Strengths & Thriving Areas';

  @override
  String get areasToWatch => 'Areas to Watch';

  @override
  String get alsoCheckWithProfessional =>
      'Also worth checking with a professional';

  @override
  String get hearingCheckAlways =>
      'A hearing check is recommended whenever language difficulties or concerns are noted.';

  @override
  String get urgentNoticeTitle => 'Important Recommendation';

  @override
  String get urgentNoticeMessage =>
      'Based on your answers regarding sudden changes or hearing responsiveness, we strongly recommend speaking with a speech-language professional or pediatrician soon.';

  @override
  String confidenceLabel(Object completeness, Object level) {
    return 'Confidence: $level ($completeness% answered)';
  }

  @override
  String get confidenceExplanation =>
      'Confidence is based on the proportion of questions answered.';

  @override
  String get whatYouCanDoNext => 'What you can do next';

  @override
  String get learnMoreLink =>
      'Explore Learn articles about language development';

  @override
  String get findSpecialistComingSoon =>
      'Find a specialist (Coming soon in Phase 4)';

  @override
  String get shareWithTeacherComingSoon =>
      'Share with teacher (Coming soon in Phase 4)';

  @override
  String get deleteResult => 'Delete Result';

  @override
  String get deleteResultConfirmTitle => 'Delete Result?';

  @override
  String get deleteResultConfirmMessage =>
      'Are you sure you want to delete this screening result? This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get trendHeading => 'Recent Trend';

  @override
  String get trendStable => 'Stable profile across recent checks';

  @override
  String get trendImproving => 'Signs improving across recent checks';

  @override
  String get trendNeedsAttention => 'Signs persist across recent checks';

  @override
  String get appStartErrorTitle => 'We could not start the app';

  @override
  String get appStartErrorSubtitle =>
      'Please check your connection and try again.';

  @override
  String get retry => 'Retry';
}
