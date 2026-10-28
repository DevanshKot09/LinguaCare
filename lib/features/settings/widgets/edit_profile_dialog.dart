import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/router/app_session.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  final String currentName;
  final String currentCountry;

  const EditProfileDialog({
    super.key,
    required this.currentName,
    required this.currentCountry,
  });

  static Future<void> show(BuildContext context, {required String currentName, required String currentCountry}) {
    return showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        currentName: currentName,
        currentCountry: currentCountry,
      ),
    );
  }

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late final TextEditingController _nameController;
  late String _selectedCountry;
  String _selectedEmoji = '🧑';
  bool _isSaving = false;
  String? _errorMessage;

  static const List<String> _countries = [
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'United Arab Emirates',
    'Singapore',
    'New Zealand',
    'Germany',
    'France',
    'Ireland',
    'South Africa',
    'Other',
  ];

  static const List<String> _avatarChoices = ['🧑', '👩', '🦁', '🐧', '🩺', '🎓', '⭐', '🦊'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _selectedCountry = _countries.contains(widget.currentCountry) ? widget.currentCountry : 'India';
    _loadSavedEmoji();
  }

  Future<void> _loadSavedEmoji() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_avatar_emoji');
    if (saved != null && mounted) {
      setState(() => _selectedEmoji = saved);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(appSessionStateProvider).user;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({
              'full_name': newName,
              'country': _selectedCountry,
            })
            .eq('uid', user.uid);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_avatar_emoji', _selectedEmoji);

      try {
        await ref.read(appSessionProvider).refreshSession();
      } catch (_) {}

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Could not update profile: $e';
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
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 18,
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
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),

              // Avatar Selector
              const Text('Choose Your Avatar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _avatarChoices.map((emoji) {
                  final isSel = _selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = emoji),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF5B32E8).withValues(alpha: 0.15) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? const Color(0xFF5B32E8) : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Full Name
              const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Country Dropdown
              const Text('Country', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCountry,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCountry = val);
                },
              ),
              const SizedBox(height: 22),

              GestureDetector(
                onTap: _isSaving ? null : _onSave,
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
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Save Changes',
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
