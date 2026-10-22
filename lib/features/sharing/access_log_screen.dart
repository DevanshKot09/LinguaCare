import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/sharing/sharing_providers.dart';

class AccessLogScreen extends ConsumerWidget {
  final String? childId;
  final String title;

  const AccessLogScreen({
    super.key,
    this.childId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(accessLogProvider(childId));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: logAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return const Center(child: Text('No access log entries yet.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.history_rounded, color: Colors.blue),
                    title: Text('${log.memberName} (${log.memberRole.toUpperCase()})'),
                    subtitle: Text('Action: ${log.action}\nTime: ${log.timestamp.toLocal().toString().split('.').first}'),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading access log: $e')),
        ),
      ),
    );
  }
}
