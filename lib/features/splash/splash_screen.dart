import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_session.dart';
import '../../l10n/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _popAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<double> _auraAnimation;
  bool _minTimeElapsed = false;
  bool _maxTimeoutReached = false;
  Timer? _minTimer;
  Timer? _maxTimer;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('[Splash] started');
    }

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    // Bouncy pop-up scale for the logo
    _popAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    _auraAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.85, curve: Curves.easeInOut),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
    );

    _controller.forward().whenComplete(() {
      if (kDebugMode) {
        debugPrint('[Splash] animation done');
      }
    });

    final minDuration = Platform.environment.containsKey('FLUTTER_TEST')
        ? const Duration(milliseconds: 800)
        : const Duration(milliseconds: 1800);

    _minTimer = Timer(minDuration, () {
      if (!mounted) return;
      setState(() {
        _minTimeElapsed = true;
      });
      _tryNavigate();
    });

    final splashTimeout = Platform.environment.containsKey('FLUTTER_TEST')
        ? const Duration(seconds: 8)
        : const Duration(seconds: 30);
    _maxTimer = Timer(splashTimeout, () {
      if (!mounted) return;
      final session = ref.read(appSessionStateProvider);
      if (session.status == AuthSessionStatus.loading) {
        if (kDebugMode) {
          debugPrint('[Splash] max timeout reached while loading');
        }
        setState(() {
          _maxTimeoutReached = true;
        });
      }
    });
  }

  void _tryNavigate() {
    if (!_minTimeElapsed) return;
    final session = ref.read(appSessionStateProvider);
    if (session.status == AuthSessionStatus.loading) return;

    if (!mounted) return;
    if (session.status == AuthSessionStatus.error || _maxTimeoutReached) {
      setState(() {
        _maxTimeoutReached = true;
      });
      return;
    }

    if (GoRouter.maybeOf(context) == null) return;

    if (session.isFirstLaunch && !session.onboardingDone) {
      context.go('/onboarding');
    } else if (!session.isSignedIn) {
      context.go('/welcome');
    } else if (!session.hasProfile) {
      context.go('/role-setup');
    } else if (session.role != null) {
      final route = switch (session.role) {
        UserRole.parent => '/parent',
        UserRole.teacher => '/teacher',
        UserRole.adult => '/adult',
        UserRole.specialist => '/specialist',
        UserRole.admin => '/admin',
        null => '/welcome',
      };
      context.go(route);
    } else {
      context.go('/welcome');
    }
  }

  @override
  void didUpdateWidget(covariant SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tryNavigate();
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    _maxTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final session = ref.watch(appSessionStateProvider);

    ref.listen(appSessionStateProvider, (previous, next) {
      if (next.status != AuthSessionStatus.loading && next.status != AuthSessionStatus.error) {
        if (_maxTimeoutReached) {
          setState(() {
            _maxTimeoutReached = false;
          });
        }
        if (_minTimeElapsed) {
          _tryNavigate();
        }
      }
    });

    if (_maxTimeoutReached || session.status == AuthSessionStatus.error) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 24),
                Text(
                  l10n.appStartErrorTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.appStartErrorSubtitle,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _maxTimeoutReached = false;
                    });
                    ref.read(appSessionProvider).retry();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Debug Error: ${session.errorType ?? 'Session Timeout'}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (reduceMotion && kDebugMode) {
      debugPrint('[Splash] animation skipped (reduceMotion)');
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5B32E8), // Vibrant Violet
              Color(0xFF4522BA), // Deep Indigo
              Color(0xFF1E1546), // Midnight Canvas
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pop-up Logo with Glowing Aura
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final scale = reduceMotion ? 1.0 : _popAnimation.value;
                    final fade = reduceMotion ? 1.0 : _fadeAnimation.value;
                    final aura = reduceMotion ? 0.3 : _auraAnimation.value;

                    return Opacity(
                      opacity: fade.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ambient Breathing Halo
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00C4B4).withValues(alpha: 0.25 * aura),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00C4B4).withValues(alpha: 0.35 * aura),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFFC72C).withValues(alpha: 0.20 * aura),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            // Elevated Tactile Squircle Icon
                            Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                  const BoxShadow(
                                    color: Color(0xFF4321BD),
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  'assets/images/logo_mascot.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.white,
                                    child: const Center(
                                      child: Icon(
                                        Icons.record_voice_over_rounded,
                                        size: 52,
                                        color: Color(0xFF5B32E8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Animated Title Slide & Fade
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final textFade = reduceMotion ? 1.0 : _textFadeAnimation.value;
                    final slide = reduceMotion ? Offset.zero : _textSlideAnimation.value;

                    return Opacity(
                      opacity: textFade.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, slide.dy * 50),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        l10n.appTitle,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          fontFamily: 'Quicksand',
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                // Animated Tagline Pill
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final tagFade = reduceMotion ? 1.0 : _taglineFadeAnimation.value;
                    return Opacity(
                      opacity: tagFade.clamp(0.0, 1.0),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: Color(0xFFFF6B6B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.splashTagline,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.95),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
