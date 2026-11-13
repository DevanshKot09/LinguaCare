import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/auth/auth_failure.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/app_text_field.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/inline_error.dart';
import 'widgets/primary_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  static final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _emailSent = true;
      });
    } on AuthFailure catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
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
    final l10n = AppLocalizations.of(context)!;
    return AuthScaffold(
      title: l10n.resetPassword,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InlineError(message: _errorMessage),
            if (_emailSent) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Text(
                  l10n.resetEmailSent,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: () => context.go('/login'),
                text: l10n.backToLogin,
              ),
            ] else ...[
              Text(
                'Enter your email address and we will send you instructions to reset your password.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _emailController,
                label: l10n.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                prefixIcon: Icons.email_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.emailRequired;
                  }
                  if (!_emailRegex.hasMatch(value.trim())) {
                    return l10n.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: _onReset,
                text: l10n.sendResetLink,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(l10n.backToLogin),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
