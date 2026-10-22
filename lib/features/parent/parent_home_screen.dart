import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_session.dart';
import '../../app/theme/app_colors.dart';
import '../../core/responsive/responsive_scaffold.dart';
import '../../domain/profile/profile.dart';
import '../../l10n/app_localizations.dart';
import '../learn/learn_home_screen.dart';
import '../activities/activities_home_screen.dart';
import '../activities/progress_dashboard_screen.dart';
import '../sharing/sharing_management_view.dart';
import '../tools/tools_hub_screen.dart';
import '../tools/communication_card_screen.dart';
import '../tools/visual_schedule_screen.dart';
import '../export/export_action_widget.dart';

class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
  int _currentIndex = 0;
  String? _selectedChildId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(appSessionStateProvider);
    final profile = session.profile;
    final children = profile?.children ?? [];

    if (_selectedChildId == null && children.isNotEmpty) {
      _selectedChildId = children.first.id;
    }

    final selectedChild = children.where((c) => c.id == _selectedChildId).isNotEmpty
        ? children.firstWhere((c) => c.id == _selectedChildId)
        : children.isNotEmpty ? children.first : null;

    final is11to18 = selectedChild?.band == AgeBand.band11_18;

    final items = [
      ResponsiveScaffoldItem(label: l10n.tabHome, icon: Icons.home_rounded),
      ResponsiveScaffoldItem(label: l10n.tabPractise, icon: Icons.sports_esports_rounded),
      ResponsiveScaffoldItem(label: l10n.tabLearn, icon: Icons.menu_book_rounded),
      ResponsiveScaffoldItem(label: l10n.tabProgress, icon: Icons.insights_rounded),
      ResponsiveScaffoldItem(label: l10n.tabFamily, icon: Icons.family_restroom_rounded),
    ];

    final tabTitles = [l10n.tabHome, l10n.tabPractise, l10n.tabLearn, l10n.tabProgress, l10n.tabFamily];

    Widget bodyWidget;
    if (_currentIndex == 2) {
      bodyWidget = const LearnHomeScreen();
    } else if (_currentIndex == 1) {
      if (_selectedChildId == null) {
        bodyWidget = Center(child: Text(l10n.noChildForScreening));
      } else {
        bodyWidget = ActivitiesHomeScreen(
          childId: _selectedChildId,
          ageBand: is11to18 ? '11_18' : '5_11',
          audience: 'parent',
        );
      }
    } else if (_currentIndex == 3) {
      if (_selectedChildId == null) {
        bodyWidget = Center(child: Text(l10n.noChildForScreening));
      } else {
        bodyWidget = ProgressDashboardScreen(
          childId: _selectedChildId,
          title: '${selectedChild?.nickname ?? 'Child'} Progress',
        );
      }
    } else if (_currentIndex == 4) {
      bodyWidget = ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (selectedChild != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Child Tools: ${selectedChild.nickname}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunicationCardScreen())),
                      icon: const Icon(Icons.record_voice_over_rounded),
                      label: Text('Communication card for ${selectedChild.nickname}'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VisualScheduleScreen())),
                      icon: const Icon(Icons.calendar_today_rounded),
                      label: const Text('Visual schedule'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        showExportSummaryDialog(
                          context: context,
                          role: 'parent',
                          scope: 'progress_notes',
                          subjectNickname: selectedChild.nickname,
                          subjectAgeBand: is11to18 ? '11-18 yrs' : '5-11 yrs',
                          isAccessEnded: false,
                          screeningSessions: const [],
                          practiceItems: const [],
                          goalItems: const [],
                          rawObservations: const [],
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text('Export summary for ${selectedChild.nickname}'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SharingManagementView(
            isParentOrAdult: true,
            childId: _selectedChildId,
            childBand: is11to18 ? '11_18' : '5_11',
          ),
        ],
      );
    } else if (_currentIndex == 0) {
      bodyWidget = ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Welcome back, ${profile?.fullName ?? 'Parent'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (children.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.family_restroom, size: 48, color: AppColors.parentAccent),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noChildForScreening,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.push('/role-setup/form?role=parent'),
                      child: Text(l10n.addChild),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (children.length > 1) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedChildId,
                decoration: const InputDecoration(labelText: 'Active Child Profile', border: OutlineInputBorder()),
                items: children.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.nickname} (${c.band == AgeBand.band11_18 ? '11-18 yrs' : '5-11 yrs'})'))).toList(),
                onChanged: (v) => setState(() => _selectedChildId = v),
              ),
              const SizedBox(height: 16),
            ],
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
            if (selectedChild != null) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedChild.nickname,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Chip(
                            label: Text('Band: ${is11to18 ? '11-18 yrs' : '5-11 yrs'}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/screening/intro?instrumentId=${is11to18 ? 'parent_11_18' : 'parent_5_11'}&childId=${selectedChild.id}'),
                              icon: const Icon(Icons.play_arrow),
                              label: Text(l10n.startCheck),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/screening/history?childId=${selectedChild.id}'),
                            icon: const Icon(Icons.history),
                            label: const Text('History'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ToolsHubScreen())),
              icon: const Icon(Icons.build_rounded),
              label: const Text('LinguaCare Tools Hub'),
            ),
          ],
        ],
      );
    } else {
      bodyWidget = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(items[_currentIndex].icon, size: 64, color: AppColors.parentAccent),
              const SizedBox(height: 16),
              Text(
                'Parent ${tabTitles[_currentIndex]} Tab',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return ResponsiveScaffold(
      title: '${profile?.fullName ?? l10n.parentRole} - ${tabTitles[_currentIndex]}',
      currentIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: items,
      accentColor: AppColors.parentAccent,
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
