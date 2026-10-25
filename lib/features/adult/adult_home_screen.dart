import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/router/app_session.dart';
import '../../app/theme/app_colors.dart';
import '../../core/responsive/responsive_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../learn/learn_home_screen.dart';
import '../activities/activities_home_screen.dart';
import '../tools/tools_hub_screen.dart';
import '../tools/adult_journal_screen.dart';
import '../tools/communication_card_screen.dart';
import '../settings/about_screen.dart';
import '../settings/privacy_policy_screen.dart';
import '../export/export_action_widget.dart';

class AdultHomeScreen extends ConsumerStatefulWidget {
  const AdultHomeScreen({super.key});

  @override
  ConsumerState<AdultHomeScreen> createState() => _AdultHomeScreenState();
}

class _AdultHomeScreenState extends ConsumerState<AdultHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(appSessionStateProvider);
    final profile = session.profile;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final items = [
      ResponsiveScaffoldItem(label: l10n.tabHome, icon: Icons.home_rounded),
      ResponsiveScaffoldItem(label: l10n.tabPractise, icon: Icons.sports_esports_rounded),
      ResponsiveScaffoldItem(label: l10n.tabLearn, icon: Icons.menu_book_rounded),
      ResponsiveScaffoldItem(label: l10n.tabJournal, icon: Icons.book_rounded),
      ResponsiveScaffoldItem(label: l10n.tabMe, icon: Icons.person_rounded),
    ];

    final tabTitles = [l10n.tabHome, l10n.tabPractise, l10n.tabLearn, l10n.tabJournal, l10n.tabMe];

    Widget bodyWidget;
    if (_currentIndex == 2) {
      bodyWidget = const LearnHomeScreen();
    } else if (_currentIndex == 1) {
      bodyWidget = ActivitiesHomeScreen(
        subjectUid: userId,
        ageBand: 'adult',
        audience: 'adult',
      );
    } else if (_currentIndex == 3) {
      bodyWidget = const AdultJournalScreen();
    } else if (_currentIndex == 4) {
      bodyWidget = ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Adult Profile & Tools', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Name'),
            subtitle: Text(profile?.fullName ?? 'Adult User'),
          ),
          ListTile(
            title: const Text('Email'),
            subtitle: Text(profile?.email ?? session.user?.email ?? 'N/A'),
          ),
          const Divider(height: 32),
          ListTile(
            title: const Text('Communication Cards'),
            subtitle: const Text('Quick communication needs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunicationCardScreen())),
          ),
          ListTile(
            title: const Text('LinguaCare Tools Hub'),
            subtitle: const Text('Schedules, simplifier, cards & journal'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ToolsHubScreen())),
          ),
          ListTile(
            title: const Text('About LinguaCare'),
            subtitle: const Text('What the app does and does not do'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen())),
          ),
          ListTile(
            title: const Text('Privacy and Your Data'),
            subtitle: const Text('Plain-language summary'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen())),
          ),
          ListTile(
            title: const Text('Export Summary PDF'),
            subtitle: const Text('Export personal screening & practice summary'),
            trailing: const Icon(Icons.picture_as_pdf_rounded),
            onTap: () {
              showExportSummaryDialog(
                context: context,
                role: 'adult',
                scope: 'progress_notes',
                subjectNickname: profile?.fullName ?? 'Adult User',
                subjectAgeBand: 'Adult (18+)',
                isAccessEnded: false,
                screeningSessions: const [],
                practiceItems: const [],
                goalItems: const [],
                rawObservations: const [],
              );
            },
          ),
        ],
      );
    } else if (_currentIndex == 0) {
      bodyWidget = ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Welcome, ${profile?.fullName ?? 'Adult'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.languageCheck,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.languageCheckSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/screening/intro?instrumentId=adult'),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l10n.startCheck),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/screening/history?subjectUid=$userId'),
                          icon: const Icon(Icons.history),
                          label: const Text('History'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Quick Actions & Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ToolsHubScreen())),
                  icon: const Icon(Icons.build_rounded),
                  label: const Text('Tools Hub'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunicationCardScreen())),
                  icon: const Icon(Icons.record_voice_over_rounded),
                  label: const Text('Comm Card'),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      bodyWidget = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(items[_currentIndex].icon, size: 64, color: AppColors.adultAccent),
              const SizedBox(height: 16),
              Text(
                'Adult ${tabTitles[_currentIndex]} Tab',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return ResponsiveScaffold(
      title: '${profile?.fullName ?? l10n.adultRole} - ${tabTitles[_currentIndex]}',
      currentIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: items,
      accentColor: AppColors.adultAccent,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.go('/settings'),
        ),
      ],
      body: bodyWidget,
    );
  }
}
