import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/sharing/sharing_providers.dart';
import '../observations/observations_view.dart';
import '../goals/goals_view.dart';
import 'accept_invite_screen.dart';
import 'invite_dialog.dart';
import 'access_log_screen.dart';
import 'shared_summary_detail_screen.dart';

class SharingManagementView extends ConsumerWidget {
  final bool isParentOrAdult;
  final String? childId;
  final String? childBand;
  final bool isSpecialistVerified;

  const SharingManagementView({
    super.key,
    required this.isParentOrAdult,
    this.childId,
    this.childBand,
    this.isSpecialistVerified = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(myLinksProvider(false));

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        if (isParentOrAdult) ...[
          const Text(
            'Family Sharing & Privacy Control',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Only people you invite can see this. You can stop sharing at any time.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => InviteDialog(
                      childId: childId,
                      childBand: childBand,
                      defaultRole: 'teacher',
                    ),
                  ),
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Invite Teacher'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => InviteDialog(
                      childId: childId,
                      childBand: childBand,
                      defaultRole: 'specialist',
                    ),
                  ),
                  icon: const Icon(Icons.medical_services_rounded),
                  label: const Text('Invite Specialist'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AccessLogScreen(childId: childId, title: 'Access Audit Log'),
              ),
            ),
            icon: const Icon(Icons.history_rounded),
            label: const Text('View Access Log'),
          ),
          const Divider(height: 32),

          if (childId != null) ...[
            ObservationsView(childId: childId!),
            const Divider(height: 32),
            GoalsView(childId: childId!),
            const Divider(height: 32),
          ],
        ] else ...[
          if (!isSpecialistVerified) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Licence verification pending approval. Accepting invite codes is currently locked until verified.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AcceptInviteScreen()),
              ),
              icon: const Icon(Icons.qr_code_rounded),
              label: const Text('Add Student / Client with Invite Code'),
            ),
            const Divider(height: 32),
          ],
        ],

        const Text(
          'Active Connections',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        linksAsync.when(
          data: (links) {
            final filtered = childId != null ? links.where((l) => l.childId == childId).toList() : links;
            if (filtered.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No active sharing connections found.', textAlign: TextAlign.center),
                ),
              );
            }
            return Column(
              children: filtered.map((link) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(isParentOrAdult ? '${link.memberName} (${link.memberRole.toUpperCase()})' : link.childNickname),
                    subtitle: Text('Scope: ${link.scope}\nExpires: ${link.expiresAt?.toLocal().toString().split('.').first ?? 'Never'}'),
                    isThreeLine: true,
                    trailing: isParentOrAdult
                        ? IconButton(
                            icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                            onPressed: () async {
                              final repo = ref.read(sharingRepositoryProvider);
                              await repo.revokeLink(link.linkId);
                              ref.invalidate(myLinksProvider);
                            },
                          )
                        : ElevatedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SharedSummaryDetailScreen(
                                  linkId: link.linkId,
                                  childName: link.childNickname,
                                  childId: link.childId,
                                  subjectUid: link.subjectUid,
                                ),
                              ),
                            ),
                            child: const Text('View Summary'),
                          ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) {
            debugPrint('Error loading links: $e');
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No active sharing connections found. Ensure your account is connected or try again later.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
