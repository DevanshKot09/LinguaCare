import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_session.dart';
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 16),
            ],
            const Text('Profile Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Full Name'),
              subtitle: Text(profile?.fullName ?? session.user?.email ?? 'N/A'),
            ),
            ListTile(
              title: const Text('Role'),
              subtitle: Text(profile?.role.name.toUpperCase() ?? 'N/A'),
            ),
            ListTile(
              title: const Text('Country'),
              subtitle: Text(profile?.country ?? 'N/A'),
            ),
            ListTile(
              title: const Text('Email'),
              subtitle: Text(profile?.email ?? session.user?.email ?? 'N/A'),
            ),
            const Divider(height: 32),
            const Text('Practice Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Gentle Reward Animations'),
              subtitle: const Text('Show celebratory animations on activity completion'),
              value: settings.rewardAnimationsEnabled,
              onChanged: (val) => settingsNotifier.toggleRewardAnimations(val),
            ),
            SwitchListTile(
              title: const Text('Sound Effects & Cues'),
              subtitle: const Text('Play gentle audio feedback during practice'),
              value: settings.soundEnabled,
              onChanged: (val) => settingsNotifier.toggleSound(val),
            ),
            const Divider(height: 32),
            const Text('Legal, Trust & Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('About LinguaCare'),
              subtitle: const Text('What the app does and does not do'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen())),
            ),
            ListTile(
              title: const Text('Privacy and Your Data'),
              subtitle: const Text('DPDP Act 2023 summary and privacy policies'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen())),
            ),
            ListTile(
              title: const Text('Terms of Service'),
              subtitle: const Text('User agreement and non-clinical disclaimer'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsOfServiceScreen())),
            ),
            ListTile(
              title: const Text('Help and FAQ'),
              subtitle: const Text('Common questions and support guidance'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqScreen())),
            ),
            const Divider(height: 32),
            const Text('Device Data Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Clear data on this device'),
              subtitle: const Text('Remove journal, schedules, cards, checklists'),
              trailing: const Icon(Icons.delete_outline, color: Colors.orange),
              onTap: _onClearLocalData,
            ),
            const Divider(height: 32),
            PrimaryButton(
              onPressed: _onSignOut,
              text: 'Sign Out',
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _isLoading ? null : _onDeleteAccount,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }
}
