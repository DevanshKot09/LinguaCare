import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_session.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../../domain/auth/auth_failure.dart';
import '../auth/widgets/app_text_field.dart';
import '../auth/widgets/auth_scaffold.dart';
import '../auth/widgets/inline_error.dart';
import '../auth/widgets/primary_button.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  final String roleStr;

  const ProfileFormScreen({super.key, required this.roleStr});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countryController = TextEditingController(text: 'United States');

  final _professionController = TextEditingController();
  final _licenceNoController = TextEditingController();
  final _licenceBodyController = TextEditingController();
  final _workplaceController = TextEditingController();

  final _schoolController = TextEditingController();
  final _gradeSubjectController = TextEditingController();

  DateTime? _adultDob;

  bool _addChild = false;
  final _childNicknameController = TextEditingController();
  DateTime? _childDob;
  final _homeLangsController = TextEditingController(text: 'English');
  final _concernsController = TextEditingController();

  bool _agreeTerms = false;
  bool _agreeData = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserRole get _role {
    return switch (widget.roleStr) {
      'teacher' => UserRole.teacher,
      'adult' => UserRole.adult,
      'specialist' => UserRole.specialist,
      _ => UserRole.parent,
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _professionController.dispose();
    _licenceNoController.dispose();
    _licenceBodyController.dispose();
    _workplaceController.dispose();
    _schoolController.dispose();
    _gradeSubjectController.dispose();
    _childNicknameController.dispose();
    _homeLangsController.dispose();
    _concernsController.dispose();
    super.dispose();
  }

  Future<void> _selectChildDob(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _childDob = picked;
      });
    }
  }

  Future<void> _selectAdultDob(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null) {
      setState(() {
        _adultDob = picked;
      });
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms || (!_agreeData && _role == UserRole.parent && _addChild)) {
      setState(() {
        _errorMessage = 'Please accept the required terms and data processing consents.';
      });
      return;
    }

    if (_role == UserRole.adult && _adultDob == null) {
      setState(() {
        _errorMessage = 'Date of birth is required for adult profile.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileRepo = ref.read(profileRepositoryProvider);

      Map<String, dynamic> roleDetails = {};
      if (_role == UserRole.specialist) {
        roleDetails = {
          'profession': _professionController.text.trim(),
          'licence_no': _licenceNoController.text.trim(),
          'licence_body': _licenceBodyController.text.trim(),
          'workplace': _workplaceController.text.trim(),
        };
      } else if (_role == UserRole.teacher) {
        roleDetails = {
          'school': _schoolController.text.trim(),
          'grade_subject': _gradeSubjectController.text.trim(),
        };
      } else if (_role == UserRole.adult) {
        roleDetails = {
          'dob': _adultDob!.toIso8601String().split('T')[0],
        };
      }

      Map<String, dynamic>? initialChild;
      if (_role == UserRole.parent && _addChild && _childDob != null) {
        initialChild = {
          'nickname': _childNicknameController.text.trim(),
          'dob': _childDob!.toIso8601String().split('T')[0],
          'home_languages': _homeLangsController.text.split(',').map((e) => e.trim()).toList(),
          'interests': [],
          'concerns': _concernsController.text.isNotEmpty ? [_concernsController.text.trim()] : [],
        };
      }

      List<Map<String, dynamic>> consents = [
        {'type': 'terms_of_use', 'version': 'v1.0', 'granted': _agreeTerms},
        {'type': 'privacy_policy', 'version': 'v1.0', 'granted': _agreeTerms},
      ];

      if (_role == UserRole.parent && _addChild) {
        consents.add({'type': 'parental_data_processing', 'version': 'v1.0', 'granted': _agreeData});
      }

      await profileRepo.completeProfile(
        role: _role,
        fullName: _nameController.text.trim(),
        country: _countryController.text.trim(),
        language: 'en',
        roleDetails: roleDetails,
        initialChild: initialChild,
        consents: consents,
      );

      await ref.read(appSessionProvider).refreshProfile();
      if (!mounted) return;

      final homeRoute = switch (_role) {
        UserRole.parent => '/parent',
        UserRole.teacher => '/teacher',
        UserRole.adult => '/adult',
        UserRole.specialist => '/specialist',
      };
      context.go(homeRoute);
    } on AuthFailure catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to complete profile: $e';
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
    return AuthScaffold(
      title: '${widget.roleStr[0].toUpperCase()}${widget.roleStr.substring(1)} Setup',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InlineError(message: _errorMessage),
            AppTextField(
              controller: _nameController,
              label: 'Full Name',
              prefixIcon: Icons.person_rounded,
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _countryController,
              label: 'Country',
              prefixIcon: Icons.public_rounded,
              validator: (v) => v == null || v.trim().isEmpty ? 'Country is required' : null,
            ),
            const SizedBox(height: 24),
            if (_role == UserRole.specialist) ...[
              const Text('Specialist Credentials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AppTextField(
                controller: _professionController,
                label: 'Profession (e.g. Speech-Language Pathologist)',
                validator: (v) => v == null || v.trim().isEmpty ? 'Profession is required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _licenceNoController,
                label: 'Licence Number',
                validator: (v) => v == null || v.trim().isEmpty ? 'Licence number is required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _licenceBodyController,
                label: 'Licensing Body / Board',
                validator: (v) => v == null || v.trim().isEmpty ? 'Licensing body is required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _workplaceController,
                label: 'Workplace / Clinic',
              ),
            ] else if (_role == UserRole.teacher) ...[
              const Text('Educator Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AppTextField(
                controller: _schoolController,
                label: 'School Name',
                validator: (v) => v == null || v.trim().isEmpty ? 'School name is required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _gradeSubjectController,
                label: 'Grade / Subject Taught',
              ),
            ] else if (_role == UserRole.adult) ...[
              const Text('Adult Profile (18+)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_adultDob == null ? 'Select Date of Birth (18+)' : 'DOB: ${_adultDob.toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                ),
                onTap: () => _selectAdultDob(context),
              ),
            ] else if (_role == UserRole.parent) ...[
              SwitchListTile(
                title: const Text('Add a child profile now?'),
                subtitle: const Text('You can also add children later from your Family tab.'),
                value: _addChild,
                onChanged: (val) => setState(() => _addChild = val),
              ),
              if (_addChild) ...[
                const SizedBox(height: 12),
                AppTextField(
                  controller: _childNicknameController,
                  label: "Child's Nickname (or first name)",
                  validator: _addChild ? (v) => v == null || v.trim().isEmpty ? 'Nickname is required' : null : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(_childDob == null ? 'Select Child Date of Birth (Ages 5-17)' : 'DOB: ${_childDob.toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                  ),
                  onTap: () => _selectChildDob(context),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _homeLangsController,
                  label: 'Home Languages (comma separated)',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _concernsController,
                  label: 'Anything you would like us to keep in mind? (Optional)',
                ),
              ],
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Legal & Privacy Consents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Placeholder notice (needs legal review): LinguaCare is supportive and non-diagnostic.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _agreeTerms,
              onChanged: (val) => setState(() => _agreeTerms = val ?? false),
              title: const Text('I agree to the Terms of Use and Privacy Policy (v1.0)', style: TextStyle(fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_role == UserRole.parent && _addChild)
              CheckboxListTile(
                value: _agreeData,
                onChanged: (val) => setState(() => _agreeData = val ?? false),
                title: const Text('I consent to parental data processing for my child (v1.0)', style: TextStyle(fontSize: 13)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: _onSubmit,
              text: 'Complete Setup',
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
