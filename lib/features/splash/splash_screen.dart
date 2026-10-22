import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_session.dart';
import '../../l10n/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
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
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward().whenComplete(() {
      if (kDebugMode) {
        debugPrint('[Splash] animation done');
      }
    });

    _minTimer = Timer(const Duration(milliseconds: 1500), () {
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
        backgroundColor: theme.colorScheme.background,
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
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: reduceMotion ? const AlwaysStoppedAnimation(1.0) : _fadeAnimation,
          child: ScaleTransition(
            scale: reduceMotion ? const AlwaysStoppedAnimation(1.0) : _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.splashTagline,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
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
