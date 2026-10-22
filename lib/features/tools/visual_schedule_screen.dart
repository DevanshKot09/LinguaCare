import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tools_models.dart';
import '../../core/local_store/local_store.dart';
import '../../app/router/app_session.dart';
import 'uuid_helper.dart';

class VisualScheduleScreen extends ConsumerStatefulWidget {
  const VisualScheduleScreen({super.key});

  @override
  ConsumerState<VisualScheduleScreen> createState() => _VisualScheduleScreenState();
}

class _VisualScheduleScreenState extends ConsumerState<VisualScheduleScreen> {
  List<VisualSchedule> _schedules = [];
  bool _isLoading = true;
  bool _isTodayView = false;
  VisualSchedule? _activeTodaySchedule;
  final Set<String> _completedStepIds = {};

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final session = ref.read(appSessionStateProvider);
    final userId = session.user?.uid ?? 'guest';
    final store = LocalStore(userId);
    final list = await store.readList('visual_schedules', []);
    setState(() {
      _schedules = list.map((e) => VisualSchedule.fromJson(e as Map<String, dynamic>)).toList();
      if (_schedules.isEmpty) {
        // Add default sample schedule
        _schedules.add(VisualSchedule(
          id: generateUuid(),
          title: 'Morning Routine',
          childNickname: 'Sam',
          steps: [
            ScheduleStep(id: generateUuid(), iconName: 'shirt', label: 'Get dressed', timeText: '7:30 AM'),
            ScheduleStep(id: generateUuid(), iconName: 'shower', label: 'Brush teeth', timeText: '7:45 AM'),
            ScheduleStep(id: generateUuid(), iconName: 'apple', label: 'Eat breakfast', timeText: '8:00 AM'),
          ],
        ));
      }
      _isLoading = false;
    });
  }

  Future<void> _saveSchedules() async {
    final session = ref.read(appSessionStateProvider);
    final userId = session.user?.uid ?? 'guest';
    final store = LocalStore(userId);
    await store.writeList('visual_schedules', _schedules.map((s) => s.toJson()).toList());
  }

  void _addSchedule() {
    if (_schedules.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 schedules allowed.')),
      );
      return;
    }

    final newSchedule = VisualSchedule(
      id: generateUuid(),
      title: 'New Schedule ${_schedules.length + 1}',
      steps: [
        ScheduleStep(id: generateUuid(), iconName: 'star', label: 'First step', timeText: 'Morning'),
      ],
    );

    setState(() {
      _schedules.add(newSchedule);
    });
    _saveSchedules();
  }

  void _duplicateSchedule(VisualSchedule schedule) {
    if (_schedules.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 schedules allowed.')),
      );
      return;
    }

    final duplicated = VisualSchedule(
      id: generateUuid(),
      title: '${schedule.title} (Copy)',
      childNickname: schedule.childNickname,
      steps: schedule.steps
          .map((s) => ScheduleStep(
                id: generateUuid(),
                iconName: s.iconName,
                label: s.label,
                timeText: s.timeText,
              ))
          .toList(),
    );

    setState(() {
      _schedules.add(duplicated);
    });
    _saveSchedules();
  }

  void _deleteSchedule(String id) {
    setState(() {
      _schedules.removeWhere((s) => s.id == id);
      if (_activeTodaySchedule?.id == id) {
        _activeTodaySchedule = null;
        _isTodayView = false;
      }
    });
    _saveSchedules();
  }

  void _openEditor(VisualSchedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ScheduleEditorScreen(
          schedule: schedule,
          onSave: (updated) {
            setState(() {
              final index = _schedules.indexWhere((s) => s.id == updated.id);
              if (index != -1) {
                _schedules[index] = updated;
              }
            });
            _saveSchedules();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visual Schedules')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isTodayView && _activeTodaySchedule != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Today: ${_activeTodaySchedule!.title}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _isTodayView = false),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset for a new day',
              onPressed: () => setState(() => _completedStepIds.clear()),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_activeTodaySchedule!.childNickname != null && _activeTodaySchedule!.childNickname!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Schedule for: ${_activeTodaySchedule!.childNickname}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Tap steps to mark them done. No timers or scores.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _activeTodaySchedule!.steps.length,
                  itemBuilder: (context, index) {
                    final step = _activeTodaySchedule!.steps[index];
                    final isDone = _completedStepIds.contains(step.id);
                    return Card(
                      color: isDone ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: isDone ? 0 : 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(_getIconData(step.iconName), size: 32),
                        ),
                        title: Text(
                          step.label,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: step.timeText != null && step.timeText!.isNotEmpty
                            ? Text(step.timeText!, style: const TextStyle(fontSize: 16))
                            : null,
                        trailing: Checkbox(
                          value: isDone,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _completedStepIds.add(step.id);
                              } else {
                                _completedStepIds.remove(step.id);
                              }
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            if (isDone) {
                              _completedStepIds.remove(step.id);
                            } else {
                              _completedStepIds.add(step.id);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _completedStepIds.clear()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset for a new day'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Schedules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Schedule',
            onPressed: _addSchedule,
          ),
        ],
      ),
      body: SafeArea(
        child: _schedules.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No visual schedules yet.'),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _addSchedule, child: const Text('Create Schedule')),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _schedules.length,
                itemBuilder: (context, index) {
                  final schedule = _schedules[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  schedule.title,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                tooltip: 'Edit Schedule',
                                onPressed: () => _openEditor(schedule),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                tooltip: 'Duplicate',
                                onPressed: () => _duplicateSchedule(schedule),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () => _deleteSchedule(schedule.id),
                              ),
                            ],
                          ),
                          if (schedule.childNickname != null && schedule.childNickname!.isNotEmpty)
                            Text('Child: ${schedule.childNickname}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text('${schedule.steps.length} steps configured', style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            onPressed: () {
                              setState(() {
                                _activeTodaySchedule = schedule;
                                _completedStepIds.clear();
                                _isTodayView = true;
                              });
                            },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Open Today View'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'home':
        return Icons.home_rounded;
      case 'apple':
        return Icons.apple_rounded;
      case 'book':
        return Icons.book_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'bed':
        return Icons.bed_rounded;
      case 'pencil':
        return Icons.edit_rounded;
      case 'play':
        return Icons.sports_esports_rounded;
      case 'shirt':
        return Icons.checkroom_rounded;
      case 'shower':
        return Icons.shower_rounded;
      case 'walk':
        return Icons.directions_walk_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}

class _ScheduleEditorScreen extends StatefulWidget {
  final VisualSchedule schedule;
  final ValueChanged<VisualSchedule> onSave;

  const _ScheduleEditorScreen({required this.schedule, required this.onSave});

  @override
  State<_ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends State<_ScheduleEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _nicknameController;
  late List<ScheduleStep> _steps;

  final List<String> _availableIcons = [
    'star',
    'home',
    'apple',
    'book',
    'car',
    'bed',
    'pencil',
    'play',
    'shirt',
    'shower',
    'walk',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.schedule.title);
    _nicknameController = TextEditingController(text: widget.schedule.childNickname ?? '');
    _steps = List.from(widget.schedule.steps);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _addStep() {
    if (_steps.length >= 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 12 steps allowed per schedule.')),
      );
      return;
    }
    setState(() {
      _steps.add(ScheduleStep(
        id: generateUuid(),
        iconName: 'star',
        label: 'New Step',
        timeText: '',
      ));
    });
  }

  void _moveStep(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _steps.length) return;
    setState(() {
      final item = _steps.removeAt(index);
      _steps.insert(newIndex, item);
    });
  }

  void _save() {
    final updated = widget.schedule.copyWith(
      title: _titleController.text.trim().isEmpty ? 'Untitled Schedule' : _titleController.text.trim(),
      childNickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
      steps: _steps,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Visual Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Schedule Title', border: OutlineInputBorder()),
              maxLength: 50,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'Child Nickname (optional)',
                hintText: 'Please avoid full names, addresses or phone numbers',
                border: OutlineInputBorder(),
              ),
              maxLength: 30,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Steps (up to 12)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Step'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _steps.removeAt(oldIndex);
                  _steps.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Card(
                  key: ValueKey(step.id),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            DropdownButton<String>(
                              value: _availableIcons.contains(step.iconName) ? step.iconName : 'star',
                              items: _availableIcons
                                  .map((icon) => DropdownMenuItem(value: icon, child: Text(icon)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _steps[index] = step.copyWith(iconName: val);
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(text: step.label)
                                  ..selection = TextSelection.fromPosition(TextPosition(offset: step.label.length)),
                                decoration: const InputDecoration(labelText: 'Step Label (max 40 chars)')
                                ,
                                maxLength: 40,
                                onChanged: (val) {
                                  _steps[index] = step.copyWith(label: val);
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _steps.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(text: step.timeText ?? '')
                                  ..selection = TextSelection.fromPosition(TextPosition(offset: (step.timeText ?? '').length)),
                                decoration: const InputDecoration(labelText: 'Time text (e.g. 8:00 AM)'),
                                onChanged: (val) {
                                  _steps[index] = step.copyWith(timeText: val);
                                },
                              ),
                            ),
                            // Accessible Move Up / Move Down buttons
                            IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              tooltip: 'Move up',
                              onPressed: index > 0 ? () => _moveStep(index, -1) : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward),
                              tooltip: 'Move down',
                              onPressed: index < _steps.length - 1 ? () => _moveStep(index, 1) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
