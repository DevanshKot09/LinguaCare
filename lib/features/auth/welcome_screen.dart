import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_session.dart';
import '../../domain/auth/auth_user.dart';
import '../../l10n/app_localizations.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  void _showDebugSwitcher(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Debug Role Switcher',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.family_restroom),
                title: const Text('Parent Home'),
                onTap: () {
                  ref.read(appSessionProvider).debugSetState(
                        status: AuthSessionStatus.authenticated,
                        user: const AuthUser(
                          uid: 'debug-parent',
                          email: 'parent@linguacare.app',
                          emailVerified: true,
                          profileExists: true,
                          role: UserRole.parent,
                        ),
                        onboardingDone: true,
                      );
                  Navigator.pop(context);
                  context.go('/parent');
                },
              ),
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Teacher Home'),
                onTap: () {
                  ref.read(appSessionProvider).debugSetState(
                        status: AuthSessionStatus.authenticated,
                        user: const AuthUser(
                          uid: 'debug-teacher',
                          email: 'teacher@linguacare.app',
                          emailVerified: true,
                          profileExists: true,
                          role: UserRole.teacher,
                        ),
                        onboardingDone: true,
                      );
                  Navigator.pop(context);
                  context.go('/teacher');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Adult Home'),
                onTap: () {
                  ref.read(appSessionProvider).debugSetState(
                        status: AuthSessionStatus.authenticated,
                        user: const AuthUser(
                          uid: 'debug-adult',
                          email: 'adult@linguacare.app',
                          emailVerified: true,
                          profileExists: true,
                          role: UserRole.adult,
                        ),
                        onboardingDone: true,
                      );
                  Navigator.pop(context);
                  context.go('/adult');
                },
              ),
              ListTile(
                leading: const Icon(Icons.medical_services),
                title: const Text('Specialist Home'),
                onTap: () {
                  ref.read(appSessionProvider).debugSetState(
                        status: AuthSessionStatus.authenticated,
                        user: const AuthUser(
                          uid: 'debug-specialist',
                          email: 'specialist@linguacare.app',
                          emailVerified: true,
                          profileExists: true,
                          role: UserRole.specialist,
                        ),
                        onboardingDone: true,
                      );
                  Navigator.pop(context);
                  context.go('/specialist');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.chat_bubble_rounded,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.welcomeTitle,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.welcomeSubtitle,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            l10n.nonDiagnosticNotice,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/sign-up'),
                          child: Text(l10n.signUp),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => context.go('/login'),
                          child: Text(l10n.logIn),
                        ),
                        if (kDebugMode && !(ref.watch(appSessionStateProvider).user?.profileExists ?? false)) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => _showDebugSwitcher(context, ref),
                            icon: const Icon(Icons.bug_report),
                            label: const Text('Debug Role Switcher'),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
