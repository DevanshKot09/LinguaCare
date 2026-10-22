import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/errors/config_error_screen.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

bool isValidSupabaseUrl(String url) {
  if (url.isEmpty) return false;
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return false;
  if (uri.path.isNotEmpty) return false;
  final host = uri.host;
  final regex = RegExp(r'^[a-z0-9]{20}\.supabase\.co$');
  return regex.hasMatch(host);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    runApp(const ConfigErrorScreen(errorMessage: 'Missing Supabase URL or Anon Key. Please ensure env/dev.json is provided via --dart-define-from-file.'));
    return;
  }

  if (!isValidSupabaseUrl(_supabaseUrl)) {
    runApp(const ConfigErrorScreen(errorMessage: 'Invalid Supabase URL format or contains a path/trailing slash. Must be https://<20 lowercase alphanumeric>.supabase.co'));
    return;
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization warning (run "flutterfire configure" if needed): $e');
  }

  try {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabaseAnonKey,
      accessToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    );
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  runApp(const ProviderScope(child: LinguaCareApp()));
}

class LinguaCareApp extends ConsumerWidget {
  const LinguaCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'LinguaCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],
    );
  }
}
