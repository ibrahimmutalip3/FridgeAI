import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_routes.dart';
import '../../providers/preferences_providers.dart';
import 'widgets/morph_logo_painter.dart';

/// The very first thing the user sees inside Flutter, immediately after the
/// native launch screen (see android launch_background.xml / iOS
/// LaunchScreen.storyboard) hands off on first frame.
///
/// Both native screens render the same warm-orange gradient + logo mark at
/// rest, so this widget starts from an identical-looking frame and then
/// takes over with a full morph sequence:
///
///   1. Background gradient settles into a subtle animated drift.
///   2. The logo mark draws itself on, stroke by stroke (a "morph" from
///      nothing into the full glyph), scaling in with a soft overshoot.
///   3. The sparkle twinkles gently while the wordmark fades up beneath it.
///   4. The whole scene cross-fades + scales into the next screen (onboarding
///      or home), so there's no hard cut — one continuous motion.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  // Master timeline driving the logo draw-on, scale and settle.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  // Continuous idle loop for the sparkle twinkle + background drift, runs
  // alongside/after the entrance so the splash never feels static while
  // storage/preferences finish warming up.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  // Drives the final morph-out into the next route.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  late final Animation<double> _logoScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.72, end: 1.06).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 70),
    TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
  ]).animate(_entrance);

  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
  );

  late final Animation<double> _drawProgress = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.05, 0.85, curve: Curves.easeInOutCubic),
  );

  late final Animation<double> _morphSettle = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
  );

  late final Animation<double> _wordmarkFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
  );

  late final Animation<double> _wordmarkSlide = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _exitFade = CurvedAnimation(
    parent: _exit,
    curve: Curves.easeIn,
  );

  late final Animation<double> _exitScale = Tween<double>(begin: 1.0, end: 1.12).animate(
    CurvedAnimation(parent: _exit, curve: Curves.easeIn),
  );

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _entrance.forward();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    // Give the entrance morph time to read as a deliberate brand moment
    // (not just a loading blip) even on fast devices/warm caches, while
    // preferences/storage (already awaited in main()) are guaranteed ready.
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted || _navigated) return;
    _navigated = true;

    await _exit.forward();
    if (!mounted) return;

    final onboardingComplete = ref.read(preferencesProvider).onboardingComplete;
    context.go(onboardingComplete ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _idle.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_entrance, _idle, _exit]),
        builder: (context, _) {
          return Transform.scale(
            scale: _exitScale.value,
            child: Opacity(
              opacity: 1.0 - _exitFade.value,
              child: _SplashBackground(
                driftT: _idle.value,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoFade.value,
                          child: SizedBox(
                            width: 128,
                            height: 128,
                            child: CustomPaint(
                              painter: MorphLogoPainter(
                                drawProgress: _drawProgress.value,
                                morphProgress: _morphSettle.value,
                                sparkleProgress: _idle.value,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Opacity(
                        opacity: _wordmarkFade.value,
                        child: Transform.translate(
                          offset: Offset(0, 14 * (1 - _wordmarkSlide.value)),
                          child: const _Wordmark(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Full-bleed background that mirrors the native launch screen's gradient
/// exactly at rest, then very slowly drifts its stops for a subtle
/// "liquid" morph so the brand moment doesn't feel like a frozen image.
class _SplashBackground extends StatelessWidget {
  const _SplashBackground({required this.driftT, required this.child});

  final double driftT;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Same sampled gradient stops as the native launch screens, with a
    // gentle oscillation so the angle/position breathes over ~2.6s loops.
    final wobble = 0.06 * (driftT < 0.5 ? driftT * 2 : (1 - driftT) * 2);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.2 + wobble, -1.0),
          end: Alignment(0.2 - wobble, 1.0),
          colors: const [
            Color(0xFFFB9229),
            Color(0xFFF36C12),
            Color(0xFFF55211),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Text(
      'FridgeAI',
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}
