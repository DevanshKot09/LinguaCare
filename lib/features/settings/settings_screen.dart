import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_session.dart';
import '../../app/theme/app_colors.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../../domain/auth/auth_failure.dart';
import '../../domain/settings/app_settings.dart';
import '../auth/widgets/primary_button.dart';
import '../../core/local_store/local_store.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'faq_screen.dart';
import 'research_consents_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _onSignOut() async {
    final authRepo = ref.read(authRepositoryProvider);
    if (kDebugMode) {
      ref.read(appSessionProvider).debugSetState(
        status: AuthSessionStatus.unauthenticated,
        user: null,
        onboardingDone: true,
      );
    }
    await authRepo.signOut();
    if (!mounted) return;
    context.go('/welcome');
  }

  Future<void> _onClearLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Data on This Device'),
        content: const Text(
          'This will remove all locally stored schedules, communication cards, journal entries, checklists, and bookmarks from this device. Are you sure?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final userId = ref.read(appSessionStateProvider).user?.uid ?? 'guest';
      await LocalStore(userId).clearAllForUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All local data cleared from this device.')),
      );
    }
  }

  Future<void> _onDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action is permanent and will remove all your data from LinguaCare.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      await profileRepo.deleteAccount();
      final userId = ref.read(appSessionStateProvider).user?.uid;
      if (userId != null) {
        await LocalStore(userId).clearAllForUser();
      }
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();
      if (!mounted) return;
      context.go('/welcome');
    } on AuthFailure catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete account: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionStateProvider);
    final profile = session.profile;
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.errorLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.errorLight.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.errorLight),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(_errorMessage!, style: const TextStyle(color: AppColors.errorLight)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            // Profile Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                          child: const Icon(Icons.person_rounded, color: AppColors.primaryLight),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.fullName ?? session.user?.email ?? 'Account',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                profile?.email ?? session.user?.email ?? '',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            profile?.role.name.toUpperCase() ?? 'GUEST',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (profile?.country != null) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Country', style: TextStyle(color: Colors.grey)),
                          Text(profile!.country!, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Practice Preferences Card
            const Text('Practice Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Gentle Reward Animations'),
                    subtitle: const Text('Show celebratory animations on activity completion'),
                    value: settings.rewardAnimationsEnabled,
                    onChanged: (val) => settingsNotifier.toggleRewardAnimations(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Sound Effects & Cues'),
                    subtitle: const Text('Play gentle audio feedback during practice'),
                    value: settings.soundEnabled,
                    onChanged: (val) => settingsNotifier.toggleSound(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Clinical, Legal & Support Card
            const Text('Legal, Trust & Research', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.primaryLight),
                    title: const Text('About LinguaCare'),
                    subtitle: const Text('What the app does and does not do'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.secondaryLight),
                    title: const Text('Privacy and Your Data'),
                    subtitle: const Text('DPDP Act 2023 summary and privacy policies'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: Colors.blueGrey),
                    title: const Text('Terms of Service'),
                    subtitle: const Text('User agreement and non-clinical disclaimer'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsOfServiceScreen())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded, color: AppColors.teacherAccent),
                    title: const Text('Help and FAQ'),
                    subtitle: const Text('Common questions and support guidance'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqScreen())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.biotech_outlined, color: Color(0xFF6366F1)),
                    title: const Text('Your Consents (Research)'),
                    subtitle: const Text('Manage research participation and data donation'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResearchConsentsScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Device Data Card
            const Text('Device Data & Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: ListTile(
                leading: const Icon(Icons.cleaning_services_outlined, color: Colors.orange),
                title: const Text('Clear data on this device'),
                subtitle: const Text('Remove journal, schedules, cards, checklists'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _onClearLocalData,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              onPressed: _onSignOut,
              text: 'Sign Out',
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: _isLoading ? null : _onDeleteAccount,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorLight,
                side: const BorderSide(color: AppColors.errorLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }
}
