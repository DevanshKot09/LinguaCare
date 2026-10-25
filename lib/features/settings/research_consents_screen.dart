import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/research/research_consent_providers.dart';
import '../../app/router/app_session.dart';
import '../../domain/profile/profile.dart';

class ResearchConsentsScreen extends ConsumerStatefulWidget {
  const ResearchConsentsScreen({super.key});

  @override
  ConsumerState<ResearchConsentsScreen> createState() => _ResearchConsentsScreenState();
}

class _ResearchConsentsScreenState extends ConsumerState<ResearchConsentsScreen> {
  String? _selectedChildId;
  bool _questionnaireScope = false;
  bool _tasksScope = false;
  bool _clinicalLabelScope = false;
  bool _childAssent = false;
  bool _isLoading = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionStateProvider);
    final profile = session.profile;
    final children = profile?.children ?? [];
    final consentsAsync = ref.watch(researchConsentsProvider);

    final selectedChild = children.where((c) => c.id == _selectedChildId).isNotEmpty
        ? children.firstWhere((c) => c.id == _selectedChildId)
        : children.isNotEmpty ? children.first : null;

    final isBand11to18 = selectedChild?.band == AgeBand.band11_18;

    return Scaffold(
      appBar: AppBar(title: const Text('Research Consents')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Research Participation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Help improve speech and language support worldwide. Participation is voluntary, has no effect on app features, and data is fully pseudonymized.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Legal & Ethics Review Placeholder', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  SizedBox(height: 4),
                  Text('IRB Protocol #2026-LC-DEMO. Compliant with strict data privacy guidelines.', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (children.isNotEmpty) ...[
              const Text('Select Target', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedChildId ?? children.first.id,
                items: children.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.nickname} (${c.band == AgeBand.band11_18 ? '11-18 yrs' : '5-11 yrs'})'))).toList(),
                onChanged: (val) => setState(() => _selectedChildId = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
            ],
            const Text('Consent Version: v1.0', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            const Text('Scope Toggles (Default OFF)', style: TextStyle(fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: const Text('Questionnaire Responses'),
              subtitle: const Text('Anonymized questionnaire answers'),
              value: _questionnaireScope,
              onChanged: (val) => setState(() => _questionnaireScope = val),
            ),
            SwitchListTile(
              title: const Text('Task Performance Metrics'),
              subtitle: const Text('Activity scores and completion times'),
              value: _tasksScope,
              onChanged: (val) => setState(() => _tasksScope = val),
            ),
            SwitchListTile(
              title: const Text('Clinical Labels / Outcomes'),
              subtitle: const Text('Professional assessment outcomes'),
              value: _clinicalLabelScope,
              onChanged: (val) => setState(() => _clinicalLabelScope = val),
            ),
            const ListTile(
              title: Text('Audio Recordings: NONE'),
              subtitle: Text('Audio recordings are strictly excluded and never shared for research.'),
              leading: Icon(Icons.mic_off_rounded, color: Colors.grey),
            ),
            if (isBand11to18) ...[
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Teen Assent (Mandatory for Age Band 11-18)'),
                subtitle: const Text('The teen has agreed to share pseudonymized data for research.'),
                value: _childAssent,
                onChanged: (val) => setState(() => _childAssent = val ?? false),
              ),
            ],
            const SizedBox(height: 24),
            if (_message != null) ...[
              Text(_message!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (isBand11to18 && !_childAssent) {
                              setState(() => _message = 'Teen assent is mandatory for age band 11-18.');
                              return;
                            }
                            final scopes = <String>[];
                            if (_questionnaireScope) scopes.add('questionnaire');
                            if (_tasksScope) scopes.add('tasks');
                            if (_clinicalLabelScope) scopes.add('clinical_label');

                            setState(() {
                              _isLoading = true;
                              _message = null;
                            });
                            try {
                              final repo = ref.read(researchConsentRepositoryProvider);
                              await repo.grantResearchConsent(
                                childId: _selectedChildId ?? (children.isNotEmpty ? children.first.id : null),
                                subjectUid: children.isEmpty ? session.user?.uid : null,
                                consentVersion: 'v1.0',
                                scopes: scopes,
                                childAssent: isBand11to18 ? _childAssent : false,
                              );
                              ref.invalidate(researchConsentsProvider);
                              setState(() => _message = 'Research consent granted successfully.');
                            } catch (e) {
                              setState(() => _message = 'Error granting consent: $e');
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          },
                    child: const Text('Grant Consent'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true;
                              _message = null;
                            });
                            try {
                              final repo = ref.read(researchConsentRepositoryProvider);
                              await repo.withdrawResearchConsent(
                                childId: _selectedChildId ?? (children.isNotEmpty ? children.first.id : null),
                                subjectUid: children.isEmpty ? session.user?.uid : null,
                                consentVersion: 'v1.0',
                              );
                              ref.invalidate(researchConsentsProvider);
                              setState(() {
                                _questionnaireScope = false;
                                _tasksScope = false;
                                _clinicalLabelScope = false;
                                _childAssent = false;
                                _message = 'Research consent withdrawn successfully.';
                              });
                            } catch (e) {
                              setState(() => _message = 'Error withdrawing consent: $e');
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Withdraw Consent'),
                  ),
                ),
              ],
            ),
            const Divider(height: 48),
            const Text('Consents History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            consentsAsync.when(
              data: (consents) {
                if (consents.isEmpty) {
                  return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No research consent history.')));
                }
                return Column(
                  children: consents.map((c) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('Version: ${c.consentVersion} • Status: ${c.granted ? 'GRANTED' : 'WITHDRAWN'}'),
                          subtitle: Text('Scopes: ${c.scopes.join(', ')}\nDate: ${c.createdAt.toLocal().toString().split('.').first}'),
                          isThreeLine: true,
                        ),
                      )).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading history: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
