import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_session.dart';
import '../../l10n/app_localizations.dart';

class AuthPlaceholderScreen extends ConsumerWidget {
  const AuthPlaceholderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signUp)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                l10n.authPlaceholder,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(appSessionProvider).debugSetState(
                        isSignedIn: true,
                        hasProfile: false,
                      );
                  context.go('/role-setup');
                },
                child: const Text('Simulate Sign In'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/welcome'),
                child: const Text('Back to Welcome'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
