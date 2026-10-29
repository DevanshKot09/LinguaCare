import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/router/app_session.dart';
import '../../app/theme/app_colors.dart';
import '../../core/responsive/responsive_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/sharing/sharing_providers.dart';
import '../../domain/goals/goal.dart';
import '../tools/tools_hub_screen.dart';
import '../sharing/sharing_management_view.dart';
import '../sharing/accept_invite_screen.dart';

class SpecialistHomeScreen extends ConsumerStatefulWidget {
  const SpecialistHomeScreen({super.key});

  @override
  ConsumerState<SpecialistHomeScreen> createState() => _SpecialistHomeScreenState();
}

class _SpecialistHomeScreenState extends ConsumerState<SpecialistHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(appSessionStateProvider);
    final profile = session.profile;
    final isVerified = session.isSpecialistVerified;

    final items = [
      ResponsiveScaffoldItem(label: l10n.tabDashboard, icon: Icons.dashboard_rounded),
      ResponsiveScaffoldItem(label: l10n.tabClients, icon: Icons.people_rounded),
      ResponsiveScaffoldItem(label: l10n.tabPlans, icon: Icons.assignment_rounded),
      ResponsiveScaffoldItem(label: l10n.tabLibrary, icon: Icons.local_library_rounded),
    ];

    final tabTitles = [l10n.tabDashboard, l10n.tabClients, l10n.tabPlans, l10n.tabLibrary];

    Widget bodyContent;
    switch (_currentIndex) {
      case 0:
        bodyContent = SpecialistDashboardTab(
          isVerified: isVerified,
          onNavigateTab: (index) => setState(() => _currentIndex = index),
        );
        break;
      case 1:
        bodyContent = SharingManagementView(
          isParentOrAdult: false,
          isSpecialistVerified: isVerified,
        );
        break;
      case 2:
        bodyContent = SpecialistPlansTab(isVerified: isVerified);
        break;
      case 3:
      default:
        bodyContent = const ToolsHubScreen();
        break;
    }

    return ResponsiveScaffold(
      title: '${profile?.fullName ?? l10n.specialistRole} - ${tabTitles[_currentIndex]}',
      currentIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: items,
      accentColor: AppColors.specialistAccent,
      actions: [
        if (_currentIndex != 3)
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
      ],
      body: Column(
        children: [
          if (!isVerified)
            Container(
              color: Colors.amber.shade100,
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Licence verification pending approval. Clinical features and goal creation are currently locked.',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: bodyContent),
        ],
      ),
    );
  }
}

class SpecialistDashboardTab extends ConsumerWidget {
  final bool isVerified;
  final ValueChanged<int> onNavigateTab;

  const SpecialistDashboardTab({super.key, required this.isVerified, required this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(myLinksProvider(false));
    final logAsync = ref.watch(accessLogProvider(null));

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text('Specialist Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Caseload overview, access links, and recent activity.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        linksAsync.when(
          data: (links) {
            final now = DateTime.now();
            final expiringSoon = links.where((l) {
              if (l.expiresAt == null) return false;
              final diff = l.expiresAt!.difference(now).inDays;
              return diff >= 0 && diff <= 14;
            }).length;

            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Linked Clients',
                    count: '${links.length}',
                    icon: Icons.people_rounded,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Expiring in 14 Days',
                    count: '$expiringSoon',
                    icon: Icons.timer_rounded,
                    color: Colors.orange,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          error: (e, _) => const Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Linked Clients',
                  count: '0',
                  icon: Icons.people_rounded,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Expiring in 14 Days',
                  count: '0',
                  icon: Icons.timer_rounded,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isVerified
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AcceptInviteScreen()),
                        )
                    : null,
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('Add Client'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onNavigateTab(2), // Plans tab
                icon: const Icon(Icons.assignment_rounded),
                label: const Text('Manage Plans'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/specialist/assessments'),
          icon: const Icon(Icons.assessment_rounded),
          label: const Text('Clinical Assessments'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Recent Access Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        logAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No recent activity logged.')));
            }
            return Column(
              children: logs.take(5).map((log) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(log.action),
                      subtitle: Text('${log.memberName} (${log.memberRole}) • ${log.timestamp.toLocal().toString().split('.').first}'),
                    ),
                  )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No recent activity logged.'))),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}

class SpecialistPlansTab extends ConsumerStatefulWidget {
  final bool isVerified;
  const SpecialistPlansTab({super.key, required this.isVerified});

  @override
  ConsumerState<SpecialistPlansTab> createState() => _SpecialistPlansTabState();
}

class _SpecialistPlansTabState extends ConsumerState<SpecialistPlansTab> {
  String? _selectedChildId;
  final _descController = TextEditingController();
  String _domain = 'vocabulary';
  int _progress = 0;
  String? _formError;

  Future<void> _addGoal(String childId) async {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      setState(() => _formError = 'Goal description cannot be empty.');
      return;
    }
    if (desc.length > 300) {
      setState(() => _formError = 'Goal description exceeds 300 characters.');
      return;
    }

    setState(() => _formError = null);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final goal = Goal(
      childId: childId,
      authorUid: userId,
      domain: _domain,
      description: desc,
      status: 'active',
      progress: _progress,
      createdAt: DateTime.now(),
    );

    try {
      final repo = ref.read(goalRepositoryProvider);
      await repo.addGoal(goal);
      _descController.clear();
      setState(() => _progress = 0);
      ref.invalidate(goalsProvider(childId));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _formError = 'Failed to save goal: $e');
    }
  }

  void _showAddDialog(BuildContext context, String childId) {
    setState(() => _formError = null);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Create Communication Goal'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_formError != null) ...[
                    Text(_formError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    const SizedBox(height: 8),
                  ],
                  const Text('Domain', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    initialValue: _domain,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'vocabulary', child: Text('Vocabulary')),
                      DropdownMenuItem(value: 'understanding', child: Text('Understanding')),
                      DropdownMenuItem(value: 'grammar', child: Text('Grammar')),
                      DropdownMenuItem(value: 'narrative', child: Text('Narrative')),
                      DropdownMenuItem(value: 'conversation', child: Text('Conversation')),
                    ],
                    onChanged: (v) => setStateDialog(() => _domain = v ?? 'vocabulary'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Quick Goal Templates:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('2-step prepositions', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setStateDialog(() {
                            _domain = 'understanding';
                            _descController.text = 'Follow two-step verbal directions containing prepositions (in, on, under) with 80% accuracy.';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Past-tense recasting', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setStateDialog(() {
                            _domain = 'grammar';
                            _descController.text = 'Produce regular and irregular past-tense verbs in conversational sentences with verbal recasting.';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Core vocabulary naming', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setStateDialog(() {
                            _domain = 'vocabulary';
                            _descController.text = 'Name 10 tier-2 academic and school vocabulary items without prompts across 3 consecutive sessions.';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('3-part narrative recall', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setStateDialog(() {
                            _domain = 'narrative';
                            _descController.text = 'Retell a simple 3-part story sequence with beginning, middle, and end using visual prompt cards.';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Goal Description (max 300 chars)', border: OutlineInputBorder()),
                    maxLines: 2,
                    maxLength: 300,
                  ),
                  const SizedBox(height: 16),
                  Text('Progress: $_progress%'),
                  Slider(
                    value: _progress.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '$_progress%',
                    onChanged: (v) => setStateDialog(() => _progress = v.toInt()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => _addGoal(childId), child: const Text('Save Goal')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(myLinksProvider(false));

    return linksAsync.when(
      data: (links) {
        if (links.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No linked clients found. Add a client first to manage plans.'),
            ),
          );
        }

        if (_selectedChildId == null && links.isNotEmpty) {
          _selectedChildId = links.first.childId;
        }

        final selectedLink = links.firstWhere((l) => l.childId == _selectedChildId, orElse: () => links.first);
        final hasNotesScope = selectedLink.scope == 'progress_notes';

        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text('Client Intervention Plans & Goals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedChildId,
              decoration: const InputDecoration(labelText: 'Select Client', border: OutlineInputBorder()),
              items: links.map((l) => DropdownMenuItem(value: l.childId, child: Text(l.childNickname))).toList(),
              onChanged: (v) => setState(() => _selectedChildId = v),
            ),
            const SizedBox(height: 24),
            if (!widget.isVerified)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  'Licence verification pending. Goal creation is locked until verified.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              )
            else if (!hasNotesScope)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  'This family shared progress only. Ask them to share notes if you want to create and manage goals.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Goals for ${selectedLink.childNickname}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context, selectedLink.childId ?? ''),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Goal'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, _) {
                  final goalsAsync = ref.watch(goalsProvider(selectedLink.childId ?? ''));
                  return goalsAsync.when(
                    data: (goals) {
                      if (goals.isEmpty) {
                        return const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No goals set for this client yet.')));
                      }
                      return Column(
                        children: goals.map((g) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Chip(label: Text(g.domain.toUpperCase())),
                                        Text('${g.progress}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(g.description, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(value: g.progress / 100.0),
                                  ],
                                ),
                              ),
                            )).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) {
                      debugPrint('Error loading goals: $e');
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Unable to load goals at this time. Please check your connection and try again.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        debugPrint('Error loading client links: $e');
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                const Text(
                  'No client links available yet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect with clients to view their support plans and track intervention progress.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
