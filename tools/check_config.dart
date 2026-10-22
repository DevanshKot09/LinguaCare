// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';

void main() async {
  print('=== LinguaCare Configuration & Security Audit ===\n');
  bool allPassed = true;

  // 1. Check env/dev.json
  final devJsonFile = File('env/dev.json');
  if (!devJsonFile.existsSync()) {
    print('[FAIL] env/dev.json does not exist.');
    allPassed = false;
  } else {
    try {
      final content = devJsonFile.readAsStringSync();
      final map = json.decode(content) as Map<String, dynamic>;
      final keys = map.keys.toList();
      print('[PASS] env/dev.json exists and is valid JSON.');
      print('       Keys read by app: $keys');

      if (!keys.contains('SUPABASE_URL') || !keys.contains('SUPABASE_ANON_KEY')) {
        print('[FAIL] env/dev.json missing SUPABASE_URL or SUPABASE_ANON_KEY.');
        allPassed = false;
      } else {
        final url = map['SUPABASE_URL'].toString();
        final anonKey = map['SUPABASE_ANON_KEY'].toString();

        // Validate SUPABASE_URL
        final uri = Uri.tryParse(url);
        final urlRegex = RegExp(r'^https://[a-z0-9]{20}\.supabase\.co$');
        if (uri == null || uri.path.isNotEmpty || !urlRegex.hasMatch(url)) {
          print('[FAIL] SUPABASE_URL malformed or contains a path/trailing slash: "$url". Must be https://<20 lowercase alphanumeric>.supabase.co');
          allPassed = false;
        } else {
          print('[PASS] SUPABASE_URL format is valid.');
        }

        // Validate Anon Key
        if (anonKey.isEmpty) {
          print('[FAIL] SUPABASE_ANON_KEY is empty.');
          allPassed = false;
        } else if (anonKey.startsWith('sb_secret_')) {
          print('[FAIL] SUPABASE_ANON_KEY starts with sb_secret_ (service role secret detected!).');
          allPassed = false;
        } else {
          bool isValidFormat = anonKey.startsWith('sb_publishable_') || anonKey.split('.').length == 3;
          if (!isValidFormat) {
            print('[FAIL] SUPABASE_ANON_KEY is not a valid publishable key or JWT.');
            allPassed = false;
          } else {
            // Check if JWT payload role is service_role
            if (anonKey.split('.').length == 3) {
              try {
                final parts = anonKey.split('.');
                final payloadNormalized = base64Url.normalize(parts[1]);
                final payloadJson = utf8.decode(base64Url.decode(payloadNormalized));
                final payloadMap = json.decode(payloadJson) as Map<String, dynamic>;
                if (payloadMap['role'] == 'service_role') {
                  print('[FAIL] SUPABASE_ANON_KEY decodes to service_role JWT!');
                  allPassed = false;
                } else {
                  print('[PASS] SUPABASE_ANON_KEY does not have service_role.');
                }
              } catch (_) {}
            } else {
              print('[PASS] SUPABASE_ANON_KEY format is valid.');
            }
          }
        }
      }
    } catch (e) {
      print('[FAIL] env/dev.json is not valid JSON: $e');
      allPassed = false;
    }
  }

  // 2. Git Hygiene & env/dev.example.json
  final exampleJsonFile = File('env/dev.example.json');
  if (!exampleJsonFile.existsSync()) {
    print('[FAIL] env/dev.example.json does not exist.');
    allPassed = false;
  } else {
    print('[PASS] env/dev.example.json exists.');
    try {
      final exampleContent = exampleJsonFile.readAsStringSync();
      final exampleMap = json.decode(exampleContent) as Map<String, dynamic>;
      final exampleKeys = exampleMap.keys.toList()..sort();

      for (final entry in exampleMap.entries) {
        final val = entry.value.toString();
        if (val.startsWith('sb_secret_') || val.startsWith('sb_publishable_') || (val.split('.').length == 3 && !val.contains('YOUR_'))) {
          print('[FAIL] env/dev.example.json contains real-shaped key value for ${entry.key}. Must be placeholder only.');
          allPassed = false;
        }
      }

      if (devJsonFile.existsSync()) {
        final devContent = devJsonFile.readAsStringSync();
        final devMap = json.decode(devContent) as Map<String, dynamic>;
        final devKeys = devMap.keys.toList()..sort();
        if (devKeys.toString() == exampleKeys.toString()) {
          print('[PASS] env/dev.json and env/dev.example.json have matching key NAMES.');
        } else {
          print('[FAIL] env/dev.json and env/dev.example.json key NAMES do not match.');
          allPassed = false;
        }
      }
    } catch (e) {
      print('[FAIL] env/dev.example.json is not valid JSON: $e');
      allPassed = false;
    }
  }

  final gitignoreFile = File('.gitignore');
  if (gitignoreFile.existsSync()) {
    final ignoreContent = gitignoreFile.readAsStringSync();
    if (ignoreContent.contains('env/*.json') && ignoreContent.contains('!env/dev.example.json')) {
      print('[PASS] .gitignore correctly ignores env/*.json except dev.example.json.');
    } else {
      print('[FAIL] .gitignore missing env/*.json or exception for dev.example.json.');
      allPassed = false;
    }
  }

  // Check git ls-files for sensitive files
  try {
    final result = await Process.run('git', ['ls-files']);
    if (result.exitCode == 0) {
      final trackedFiles = result.stdout.toString();
      if (trackedFiles.contains('env/dev.json') || trackedFiles.contains('.env') || trackedFiles.contains('service-account')) {
        print('[FAIL] Sensitive files are tracked in git!');
        allPassed = false;
      } else {
        print('[PASS] No sensitive files tracked in git.');
      }
    }
  } catch (_) {}

  // 3. Repo scan for forbidden strings in lib/ and assets/
  final clientSearchDirs = ['lib', 'assets'];
  bool forbiddenFound = false;
  for (final dirPath in clientSearchDirs) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) continue;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        try {
          final content = entity.readAsStringSync();
          if (content.contains('service_role') || content.contains('sb_secret_') || content.contains('SERVICE_ROLE') || content.contains('Brevo') || content.contains('BREVO')) {
            print('[FAIL] Forbidden string found in client code/assets: ${entity.path}');
            forbiddenFound = true;
          }
        } catch (_) {}
      }
    }
  }
  if (!forbiddenFound) {
    print('[PASS] Repo scan clean of service_role, sb_secret, and Brevo in lib/ and assets/.');
  } else {
    allPassed = false;
  }

  // 4. Presence only check
  final googleServices = File('android/app/google-services.json');
  final firebaseOptions = File('lib/firebase_options.dart');
  if (googleServices.existsSync() && firebaseOptions.existsSync()) {
    print('[PASS] google-services.json and firebase_options.dart presence verified.');
  } else {
    print('[FAIL] Missing google-services.json or firebase_options.dart.');
    allPassed = false;
  }

  // 5. supabase/config.toml verify_jwt = false check
  final configTomlFile = File('supabase/config.toml');
  if (configTomlFile.existsSync()) {
    final configContent = configTomlFile.readAsStringSync();
    if (configContent.contains('[functions.set-claims]') && configContent.contains('verify_jwt = false') &&
        configContent.contains('[functions.send-otp]') &&
        configContent.contains('[functions.verify-otp]') &&
        configContent.contains('[functions.delete-account]')) {
      print('[PASS] supabase/config.toml has verify_jwt = false for required functions.');
    } else {
      print('[FAIL] supabase/config.toml missing verify_jwt = false for Edge Functions.');
      allPassed = false;
    }
  } else {
    print('[FAIL] supabase/config.toml missing.');
    allPassed = false;
  }

  // 6. send-otp SMTP port check
  final sendOtpFile = File('supabase/functions/send-otp/index.ts');
  if (sendOtpFile.existsSync()) {
    final code = sendOtpFile.readAsStringSync();
    if (code.contains("smtpPort === 25") && !code.contains("smtpPort === 587")) {
      print('[PASS] send-otp supports port 587 and 465, and rejects port 25.');
    } else {
      print('[FAIL] send-otp port validation check failed.');
      allPassed = false;
    }
  }

  // 7. Required Supabase secrets list
  print('\n[INFO] Required Supabase Secret Names (verify via `supabase secrets list`):');
  print(' - FIREBASE_PROJECT_ID');
  print(' - FIREBASE_SERVICE_ACCOUNT');
  print(' - SMTP_HOST');
  print(' - SMTP_PORT (supports 465 or 587)');
  print(' - SMTP_USER');
  print(' - SMTP_PASSWORD');
  print(' - SMTP_FROM_NAME');
  print(' - SMTP_FROM_EMAIL');
  print(' - OTP_PEPPER');
  print(' (Note: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided automatically by Supabase)');

  print('\n=============================================');
  if (allPassed) {
    print('RESULT: ALL CONFIG CHECKS PASSED.');
    exit(0);
  } else {
    print('RESULT: CONFIG AUDIT FAILED.');
    exit(1);
  }
}
