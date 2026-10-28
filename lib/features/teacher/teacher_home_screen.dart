import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/router/app_session.dart';
import '../../app/theme/app_colors.dart';
import '../../core/responsive/responsive_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/sharing/sharing_providers.dart';
import '../../domain/observations/observation.dart';
import '../sharing/sharing_management_view.dart';
import '../sharing/accept_invite_screen.dart';
import '../tools/visual_schedule_screen.dart';
import '../tools/instruction_simplifier_screen.dart';

class _StrategyItem {
  final String slug;
  final String title;
  final String summary;
  const _StrategyItem(this.slug, this.title, this.summary);
}

final _strategies = [
  const _StrategyItem('visual_schedule', 'Visual Schedules', 'Use picture or icon schedules to support multi-step instructions and transitions.'),
  const _StrategyItem('processing_time', 'Extra Processing Time', 'Allow 5-10 seconds of silent wait time after asking a question before expecting a response.'),
  const _StrategyItem('chunking', 'Chunk Instructions', 'Break complex multi-step instructions into single, bite-sized actionable steps.'),
  const _StrategyItem('multimodal', 'Multimodal Support', 'Combine spoken language with gestures, written keywords, and visual props.'),
];

class TeacherHomeScreen extends ConsumerStatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  ConsumerState<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends ConsumerState<TeacherHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(appSessionStateProvider);
    final profile = session.profile;

    final items = [
      ResponsiveScaffoldItem(label: l10n.tabHome, icon: Icons.home_rounded),
      ResponsiveScaffoldItem(label: l10n.tabStudents, icon: Icons.school_rounded),
      ResponsiveScaffoldItem(label: l10n.tabStrategies, icon: Icons.lightbulb_rounded),
      ResponsiveScaffoldItem(label: l10n.tabObservations, icon: Icons.visibility_rounded),
    ];

    final tabTitles = [l10n.tabHome, l10n.tabStudents, l10n.tabStrategies, l10n.tabObservations];

    Widget bodyWidget;
    switch (_currentIndex) {
      case 0:
        bodyWidget = TeacherDashboardTab(
          onNavigateTab: (index) => setState(() => _currentIndex = index),
        );
        break;
      case 1:
        bodyWidget = const SharingManagementView(isParentOrAdult: false);
        break;
      case 2:
        bodyWidget = const TeacherStrategiesTab();
        break;
      case 3:
      default:
        bodyWidget = const TeacherObservationsTab();
        break;
    }

    return ResponsiveScaffold(
      title: '${profile?.fullName ?? l10n.teacherRole} - ${tabTitles[_currentIndex]}',
      currentIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: items,
      accentColor: AppColors.teacherAccent,
      actions: [
        if (_currentIndex != 4)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
      ],
      body: bodyWidget,
    );
  }
}

class TeacherDashboardTab extends ConsumerWidget {
  final ValueChanged<int> onNavigateTab;
  const TeacherDashboardTab({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(myLinksProvider(false));

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          'Welcome, Teacher',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage your linked students, classroom accommodations, and observations.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 24),
        linksAsync.when(
          data: (links) {
            final now = DateTime.now();
            final expiringSoon = links.where((l) {
              if (l.expiresAt == null) return false;
              final diff = l.expiresAt!.difference(now).inDays;
              return diff >= 0 && diff <= 14;
            }).length;

            if (links.isEmpty) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.school_outlined, size: 48, color: AppColors.teacherAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'No linked students yet.',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ask a parent for an invite code to connect with your students.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AcceptInviteScreen()),
                        ),
                        icon: const Icon(Icons.qr_code_rounded),
                        label: const Text('Add Student with Invite Code'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Linked Students',
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
                ),
                const SizedBox(height: 24),
                const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AcceptInviteScreen()),
                        ),
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('Add Student'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onNavigateTab(3), // Observations tab
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('Add Observation'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => onNavigateTab(2), // Strategies tab
                  icon: const Icon(Icons.lightbulb_rounded),
                  label: const Text('Open Classroom Strategies'),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) {
            debugPrint('TeacherDashboardTab load error: $e');
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.school_outlined, size: 48, color: AppColors.teacherAccent),
                    const SizedBox(height: 16),
                    const Text(
                      'No linked students yet.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ask a parent for an invite code to connect with your students.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AcceptInviteScreen()),
                      ),
                      icon: const Icon(Icons.qr_code_rounded),
                      label: const Text('Add Student with Invite Code'),
                    ),
                  ],
                ),
              ),
            );
          },
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

class TeacherStrategiesTab extends ConsumerStatefulWidget {
  const TeacherStrategiesTab({super.key});

  @override
  ConsumerState<TeacherStrategiesTab> createState() => _TeacherStrategiesTabState();
}

class _TeacherStrategiesTabState extends ConsumerState<TeacherStrategiesTab> {
  String _searchQuery = '';
  List<String> _checklistSlugs = [];

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _checklistSlugs = prefs.getStringList('teacher_classroom_checklist') ?? [];
    });
  }

  Future<void> _toggleChecklist(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_checklistSlugs.contains(slug)) {
        _checklistSlugs.remove(slug);
      } else {
        _checklistSlugs.add(slug);
      }
    });
    await prefs.setStringList('teacher_classroom_checklist', _checklistSlugs);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _strategies.where((s) => s.title.toLowerCase().contains(_searchQuery.toLowerCase()) || s.summary.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text('Classroom Accommodations & Strategies', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Evidence-informed strategies for supporting students with DLD in the classroom.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search strategies...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Classroom Tools', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VisualScheduleScreen())),
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Visual Schedule'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructionSimplifierScreen())),
                        icon: const Icon(Icons.format_list_numbered),
                        label: const Text('Simplifier'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('My Classroom Checklist (Marked as Used)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Strategies marked: ${_checklistSlugs.length}', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        filtered.isEmpty
            ? const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No classroom strategies found.')))
            : Column(
                children: filtered.map((item) {
                  final isChecked = _checklistSlugs.contains(item.slug);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: CheckboxListTile(
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      value: isChecked,
                      onChanged: (val) => _toggleChecklist(item.slug),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
}

class TeacherObservationsTab extends ConsumerStatefulWidget {
  const TeacherObservationsTab({super.key});

  @override
  ConsumerState<TeacherObservationsTab> createState() => _TeacherObservationsTabState();
}

class _TeacherObservationsTabState extends ConsumerState<TeacherObservationsTab> {
  String? _selectedChildId;
  final _noteController = TextEditingController();
  String _setting = 'Classroom';
  String _selectedTag = 'participation';
  bool _private = false;
  String? _formError;

  final List<String> _tagsList = ['participation', 'attention', 'listening', 'vocabulary', 'social', 'general'];
  final List<String> _settingsList = ['Classroom', 'Playground', 'Group work', 'Individual', 'Other'];

  bool _containsPhoneOrEmail(String text) {
    final phoneRegExp = RegExp(r'\d{3}[-.\s]?\d{3}[-.\s]?\d{4}');
    final emailRegExp = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
    return phoneRegExp.hasMatch(text) || emailRegExp.hasMatch(text);
  }

  Future<void> _addObservation(String childId) async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      setState(() => _formError = 'Observation note cannot be empty.');
      return;
    }
    if (note.length > 500) {
      setState(() => _formError = 'Observation note exceeds 500 characters.');
      return;
    }
    if (_containsPhoneOrEmail(note)) {
      setState(() => _formError = 'Please avoid full names, addresses, phone numbers, or emails.');
      return;
    }

    setState(() => _formError = null);

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final obs = Observation(
      childId: childId,
      authorUid: userId,
      tags: [_selectedTag],
      note: note,
      setting: _setting,
      private: _private,
      createdAt: DateTime.now(),
    );

    try {
      final repo = ref.read(observationRepositoryProvider);
      await repo.addObservation(obs);
      _noteController.clear();
      setState(() => _private = false);
      ref.invalidate(observationsProvider(childId));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _formError = 'Failed to save observation: $e');
    }
  }

  void _showAddDialog(BuildContext context, String childId) {
    setState(() => _formError = null);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add Classroom Observation'),
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
                  const Text('Please avoid full names, addresses or phone numbers', style: TextStyle(fontSize: 12, color: Colors.blue, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('Chunked instructions needed', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setStateDialog(() {
                            _noteController.text = 'Student needed directions broken into one step at a time.';
                            _selectedTag = 'listening';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Visual cue helped', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setStateDialog(() {
                            _noteController.text = 'Student responded accurately after visual card was shown.';
                            _selectedTag = 'attention';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Word-finding hesitation', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setStateDialog(() {
                            _noteController.text = 'Student hesitated on specific vocabulary term during class.';
                            _selectedTag = 'vocabulary';
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Good peer interaction', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setStateDialog(() {
                            _noteController.text = 'Student participated comfortably in small group discussion.';
                            _selectedTag = 'social';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Observation Note (max 500 chars)',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 16),
                  const Text('Tag', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTag,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _tagsList.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                    onChanged: (v) => setStateDialog(() => _selectedTag = v ?? 'participation'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Setting', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    initialValue: _setting,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _settingsList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setStateDialog(() => _setting = v ?? 'Classroom'),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Private Note'),
                    subtitle: const Text('Visible only to you'),
                    value: _private,
                    onChanged: (v) => setStateDialog(() => _private = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => _addObservation(childId), child: const Text('Save')),
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
              child: Text('No linked students found. Add a student first to record observations.'),
            ),
          );
        }

        // Default selected child
        if (_selectedChildId == null && links.isNotEmpty) {
          _selectedChildId = links.first.childId;
        }

        final selectedLink = links.firstWhere((l) => l.childId == _selectedChildId, orElse: () => links.first);
        final hasNotesScope = selectedLink.scope == 'progress_notes';

        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text('Classroom Observations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedChildId,
              decoration: const InputDecoration(labelText: 'Select Student', border: OutlineInputBorder()),
              items: links.map((l) => DropdownMenuItem(value: l.childId, child: Text(l.childNickname))).toList(),
              onChanged: (v) => setState(() => _selectedChildId = v),
            ),
            const SizedBox(height: 24),
            if (!hasNotesScope)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'This family shared progress only. Ask them to share notes if you want to add observations.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Observations for ${selectedLink.childNickname}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context, selectedLink.childId ?? ''),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, _) {
                  final obsAsync = ref.watch(observationsProvider(selectedLink.childId ?? ''));
                  return obsAsync.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No observations recorded for this student yet.')));
                      }
                      return Column(
                        children: list.map((o) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(o.note),
                                subtitle: Text('Setting: ${o.setting ?? 'Classroom'} • Tags: ${o.tags.join(', ')} • ${o.private ? '🔒 Private' : '🌐 Shared'}'),
                                isThreeLine: true,
                              ),
                            )).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) {
                      debugPrint('Error loading observations: $e');
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Unable to load observations. Please check your connection and try again.'),
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
        debugPrint('Error loading student links: $e');
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('Unable to load student links. Please check your connection and try again.'),
          ),
        );
      },
    );
  }
}
