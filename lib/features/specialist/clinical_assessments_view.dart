import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/assessments/clinical_assessment.dart';
import '../../domain/assessments/assessment_providers.dart';

class ClinicalAssessmentsView extends ConsumerStatefulWidget {
  final String? childId;
  final String? subjectUid;
  final bool isSpecialist;
  final bool isVerified;
  final String scope;

  const ClinicalAssessmentsView({
    super.key,
    this.childId,
    this.subjectUid,
    required this.isSpecialist,
    required this.isVerified,
    required this.scope,
  });

  @override
  ConsumerState<ClinicalAssessmentsView> createState() => _ClinicalAssessmentsViewState();
}

class _ClinicalAssessmentsViewState extends ConsumerState<ClinicalAssessmentsView> {
  @override
  Widget build(BuildContext context) {
    final assessmentsAsync = ref.watch(assessmentsProvider(widget.childId));

    final isLocked = widget.isSpecialist && (!widget.isVerified || widget.scope != 'progress_notes');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        if (widget.isSpecialist && !widget.isVerified)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(child: Text('Unverified specialist sees locked assessment. Verification required to record.')),
              ],
            ),
          ),
        if (widget.isSpecialist && widget.scope == 'progress')
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, color: Colors.red),
                SizedBox(width: 12),
                Expanded(child: Text('Assessment hidden when link scope is progress (requires progress_notes).')),
              ],
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Specialist Clinical Assessments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (widget.isSpecialist && !isLocked) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _showRecordDialog(context, ref, null),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Record Assessment'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (isLocked && widget.isSpecialist)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Assessments are locked due to unverified status or limited link scope.'),
            ),
          )
        else
          assessmentsAsync.when(
            data: (assessments) {
              if (assessments.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No clinical assessments recorded yet.'),
                  ),
                );
              }
              return Column(
                children: assessments.map((a) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!widget.isSpecialist)
                            Text('Recorded by a specialist on ${a.assessedOn.toLocal().toString().split('T').first}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          if (!widget.isSpecialist) const SizedBox(height: 4),
                          Text('Outcome: ${a.outcome.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Tools: ${a.toolsUsed.join(', ')} • Languages: ${a.languagesAssessed.join(', ')}'),
                          Text('Hearing Status: ${a.hearingStatus} • Domains: ${a.domainsAffected.join(', ')}'),
                          if (a.severity != null) Text('Severity: ${a.severity}'),
                          if (a.note != null && a.note!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Note: ${a.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
                          ],
                          const SizedBox(height: 8),
                          const Text(
                            'LinguaCare supports language development. It does not diagnose.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          if (widget.isSpecialist && !isLocked) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _showRecordDialog(context, ref, a.id),
                                icon: const Icon(Icons.edit_note_rounded, size: 18),
                                label: const Text('Add Correction'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) {
              debugPrint('Error loading assessments: $e');
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Assessments could not be loaded. Please ensure you have an active network connection.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRecordDialog(BuildContext context, WidgetRef ref, String? supersedesId) {
    showDialog(
      context: context,
      builder: (context) => _AssessmentFormDialog(
        childId: widget.childId,
        subjectUid: widget.subjectUid,
        supersedesId: supersedesId,
      ),
    );
  }
}

class _AssessmentFormDialog extends ConsumerStatefulWidget {
  final String? childId;
  final String? subjectUid;
  final String? supersedesId;

  const _AssessmentFormDialog({this.childId, this.subjectUid, this.supersedesId});

  @override
  ConsumerState<_AssessmentFormDialog> createState() => _AssessmentFormDialogState();
}

class _AssessmentFormDialogState extends ConsumerState<_AssessmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final DateTime _assessedOn = DateTime.now();
  final List<String> _toolsUsed = ['CELF-5'];
  final List<String> _languagesAssessed = ['English'];
  String _hearingStatus = 'normal';
  String? _outcome;
  final List<String> _domainsAffected = ['expressive'];
  String? _severity;
  final TextEditingController _noteController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  final List<String> availableTools = ['CELF-5', 'PLS-5', 'CASL-2', 'EVT-3', 'PPVT-5', 'Clinical Observation'];
  final List<String> availableLanguages = ['English', 'Hindi', 'Spanish', 'French', 'Other'];
  final List<String> availableDomains = ['understanding', 'expressive', 'vocabulary', 'grammar', 'narrative', 'pragmatics'];
  final List<String> outcomes = ['typical', 'dld', 'language_difficulty_other_cause', 'speech_sound_disorder', 'other'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.supersedesId != null ? 'Add Assessment Correction' : 'Record Clinical Assessment'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              DropdownButtonFormField<String>(
                initialValue: _outcome,
                hint: const Text('Select Outcome *'),
                items: outcomes.map((o) => DropdownMenuItem(value: o, child: Text(o.toUpperCase()))).toList(),
                onChanged: (val) => setState(() => _outcome = val),
                validator: (val) => val == null ? 'Assessment form requires outcome' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _hearingStatus,
                items: ['normal', 'impaired', 'not_tested']
                    .map((h) => DropdownMenuItem(value: h, child: Text('Hearing: $h')))
                    .toList(),
                onChanged: (val) => setState(() => _hearingStatus = val ?? 'normal'),
              ),
              const SizedBox(height: 12),
              const Text('Tools Used:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: availableTools.map((tool) {
                  final selected = _toolsUsed.contains(tool);
                  return FilterChip(
                    label: Text(tool),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _toolsUsed.add(tool);
                        } else {
                          _toolsUsed.remove(tool);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text('Languages Assessed:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: availableLanguages.map((lang) {
                  final selected = _languagesAssessed.contains(lang);
                  return FilterChip(
                    label: Text(lang),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _languagesAssessed.add(lang);
                        } else {
                          _languagesAssessed.remove(lang);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text('Domains Affected:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: availableDomains.map((domain) {
                  final selected = _domainsAffected.contains(domain);
                  return FilterChip(
                    label: Text(domain),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _domainsAffected.add(domain);
                        } else {
                          _domainsAffected.remove(domain);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _severity,
                hint: const Text('Severity (Optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...['mild', 'moderate', 'severe'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))),
                ],
                onChanged: (val) => setState(() => _severity = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Professional Note (Max 500 chars, no phone/email)', border: OutlineInputBorder()),
                maxLines: 3,
                maxLength: 500,
                validator: (val) {
                  if (val != null && val.isNotEmpty) {
                    if (!isValidAssessmentNote(val)) {
                      return 'Assessment note rejects phone number or email / exceeds limits.';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (_outcome == null) {
                    setState(() => _errorMessage = 'Assessment form requires outcome');
                    return;
                  }

                  // Confirm dialog requirement
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Assessment Recording'),
                      content: const Text(
                        'This record is shared with the family. It is your professional record; LinguaCare does not diagnose.',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });

                  try {
                    final repo = ref.read(clinicalAssessmentRepositoryProvider);
                    await repo.recordAssessment(
                      childId: widget.childId,
                      subjectUid: widget.subjectUid,
                      assessedOn: _assessedOn,
                      toolsUsed: _toolsUsed,
                      languagesAssessed: _languagesAssessed,
                      hearingStatus: _hearingStatus,
                      outcome: _outcome!,
                      domainsAffected: _domainsAffected,
                      severity: _severity,
                      note: _noteController.text.isEmpty ? null : _noteController.text,
                      supersedesId: widget.supersedesId,
                    );
                    ref.invalidate(assessmentsProvider);
                    if (!mounted || !context.mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    setState(() => _errorMessage = e.toString());
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
          child: const Text('Save Assessment'),
        ),
      ],
    );
  }
}
