import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/sharing/sharing_providers.dart';
import '../../domain/sharing/sharing_models.dart';

class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({super.key});

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  InvitePreview? _preview;
  String? _errorMessage;

  Future<void> _previewCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _preview = null;
    });

    try {
      final repo = ref.read(sharingRepositoryProvider);
      final preview = await repo.previewInvite(code);
      setState(() {
        _preview = preview;
      });
    } on SharingFailure catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid or expired code.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(sharingRepositoryProvider);
      await repo.acceptInvite(code);
      ref.invalidate(myLinksProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite accepted successfully!')),
      );
      context.pop();
    } on SharingFailure catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to accept invite: $e';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Accept Invite Code')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
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
            const Text(
              'Enter the invite code provided by the family:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                border: OutlineInputBorder(),
                hintText: 'e.g. ABC123XYZ',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _previewCode,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Preview Code'),
            ),
            if (_preview != null) ...[
              const SizedBox(height: 32),
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Invite Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      Text('Inviter: ${_preview!.inviterFirstName}'),
                      const SizedBox(height: 8),
                      Text('Target Role: ${_preview!.targetRole.toUpperCase()}'),
                      const SizedBox(height: 8),
                      Text('Subject: ${_preview!.subjectKind == 'child' ? '${_preview!.childNickname} (${_preview!.childBand})' : 'Adult Self'}'),
                      const SizedBox(height: 8),
                      Text('Scope: ${_preview!.scope}'),
                      const SizedBox(height: 8),
                      Text('Duration: ${_preview!.accessMonths ?? 'Until revoked'} months'),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _acceptCode,
                          child: const Text('Accept & Connect'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
