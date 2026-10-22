import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/sharing/sharing_providers.dart';
import '../../domain/sharing/sharing_models.dart';

class InviteDialog extends ConsumerStatefulWidget {
  final String? childId;
  final String? childBand; // '5_11' or '11_18'
  final String defaultRole; // 'teacher' or 'specialist'

  const InviteDialog({
    super.key,
    this.childId,
    this.childBand,
    required this.defaultRole,
  });

  @override
  ConsumerState<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<InviteDialog> {
  late String _targetRole = widget.defaultRole;
  String _scope = 'progress';
  int _accessMonths = 12;
  bool _teenAssent = false;

  bool _isLoading = false;
  InviteResult? _result;
  String? _errorMessage;

  Future<void> _generateInvite() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(sharingRepositoryProvider);
      final res = await repo.createInvite(
        childId: widget.childId,
        targetRole: _targetRole,
        scope: _scope,
        accessMonths: _accessMonths,
        teenAssent: _teenAssent,
      );
      setState(() {
        _result = res;
      });
      ref.invalidate(myLinksProvider);
    } on SharingFailure catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create invite: $e';
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
    final isTeen = widget.childBand == '11_18';

    return AlertDialog(
      title: Text('Invite a ${_targetRole == 'teacher' ? 'Teacher' : 'Specialist'}'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 16),
              ],
              if (_result == null) ...[
                const Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  value: _targetRole,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                    DropdownMenuItem(value: 'specialist', child: Text('Specialist (SLP)')),
                  ],
                  onChanged: (v) => setState(() => _targetRole = v ?? 'teacher'),
                ),
                const SizedBox(height: 16),
                const Text('Scope of Sharing', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  value: _scope,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'progress', child: Text('Progress (Screening & Activities)')),
                    DropdownMenuItem(value: 'progress_notes', child: Text('Progress & Observations')),
                  ],
                  onChanged: (v) => setState(() => _scope = v ?? 'progress'),
                ),
                const SizedBox(height: 16),
                const Text('Access Duration', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<int>(
                  value: _accessMonths,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3 Months')),
                    DropdownMenuItem(value: 12, child: Text('12 Months (Default)')),
                  ],
                  onChanged: (v) => setState(() => _accessMonths = v ?? 12),
                ),
                if (isTeen) ...[
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('I have talked with my teen about this sharing'),
                    value: _teenAssent,
                    onChanged: (v) => setState(() => _teenAssent = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ] else ...[
                const Text('Share this invite code securely with the recipient. It works only once.', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _result!.code,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _result!.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite code copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy Code'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_result == null ? 'Cancel' : 'Done'),
        ),
        if (_result == null)
          ElevatedButton(
            onPressed: _isLoading ? null : _generateInvite,
            child: _isLoading ? const CircularProgressIndicator() : const Text('Generate Code'),
          ),
      ],
    );
  }
}
