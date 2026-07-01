import 'package:flutter/material.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/core/widgets/nbts_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  late final AnimationController _textController;
  late final Animation<Offset> _textOffset;
  late final Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOffset = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );
    _textOpacity = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );

    _start();
  }

  Future<void> _start() async {
    _logoController.forward();
    final initFuture = Services.instance.init();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textController.forward();
    _pulseController.repeat(reverse: true);

    await Future.wait([
      initFuture,
      Future.delayed(const Duration(milliseconds: 2200)),
    ]);
    if (!mounted) return;

    var route = AppRoutes.welcome;
    if (Services.instance.tokens.isAuthenticated) {
      route = AppRoutes.dashboard;
      try {
        final user = await Services.instance.profile.fetch();
        if (!user.isDonorProfileComplete) {
          route = AppRoutes.completeProfile;
        }
      } catch (_) {
        route = AppRoutes.dashboard;
      }
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: ScaleTransition(
                    scale: _pulse,
                    child: const NbtsLogo(size: 128),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _textOpacity,
                child: SlideTransition(
                  position: _textOffset,
                  child: Column(
                    children: [
                      Text(
                        'NBTS',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Donate blood. Save lives.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _textOpacity,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _textOpacity,
                child: Text(
                  'National Blood Transfusion Service',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
