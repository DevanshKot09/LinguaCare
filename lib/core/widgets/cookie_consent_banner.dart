import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/app_colors.dart';

class CookieConsentBanner extends StatefulWidget {
  final Widget child;

  const CookieConsentBanner({
    super.key,
    required this.child,
  });

  @override
  State<CookieConsentBanner> createState() => _CookieConsentBannerState();
}

class _CookieConsentBannerState extends State<CookieConsentBanner> {
  bool _dismissed = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkConsent();
    }
  }

  Future<void> _checkConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentGiven = prefs.getBool('web_storage_consent_given') ?? false;
      if (mounted && !consentGiven) {
        setState(() {
          _dismissed = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _acceptConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('web_storage_consent_given', true);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _dismissed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _dismissed) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.security_rounded,
                    color: AppColors.primaryLight,
                    size: 26,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'LinguaCare uses strictly essential browser local storage to preserve your sign-in session and offline assistive tools. We do not use advertising or tracking cookies.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton(
                    onPressed: _acceptConsent,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: const Text('Got It'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
