import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BugReportDialog extends StatefulWidget {
  const BugReportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const BugReportDialog(),
    );
  }

  @override
  State<BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends State<BugReportDialog> {
  final _messageController = TextEditingController();
  String _selectedCategory = 'bug';
  bool _isSubmitting = false;
  String? _errorMessage;

  static final RegExp _phoneRegex = RegExp(r'[+0-9() -]{7,}');
  static final RegExp _emailRegex = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _errorMessage = 'Please provide details about what happened.');
      return;
    }
    if (message.length > 1000) {
      setState(() => _errorMessage = 'Message must be under 1000 characters.');
      return;
    }
    if (_phoneRegex.hasMatch(message)) {
      setState(() => _errorMessage = 'Please do not include phone numbers for privacy.');
      return;
    }
    if (_emailRegex.hasMatch(message)) {
      setState(() => _errorMessage = 'Please do not include email addresses in the report.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.rpc('submit_bug_report', params: {
        'p_category': _selectedCategory,
        'p_message': message,
        'p_platform': 'Android/Mobile',
        'p_screen': 'SettingsScreen',
        'p_app_version': '1.0.0',
      });

      if (!mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Thank You! 🌟', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Quicksand')),
          content: const Text(
            'Your feedback has been received and logged for the team. We appreciate your help in refining LinguaCare!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().contains('Rate limit')
            ? 'Rate limit exceeded: maximum 5 reports per 24 hours.'
            : 'Could not send report. Please check your network and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Report a Problem / Idea',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'bug', child: Text('🐞 Bug or Visual Glitch')),
                  DropdownMenuItem(value: 'idea', child: Text('💡 New Feature Suggestion')),
                  DropdownMenuItem(value: 'account', child: Text('👤 Account & Sign In')),
                  DropdownMenuItem(value: 'other', child: Text('💬 General Feedback')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'What went wrong or how can we improve? (Do not include phone numbers or emails)',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isSubmitting ? null : _onSubmit,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B32E8), Color(0xFF7952FC)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF4321BD),
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Submit Report',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Quicksand',
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
