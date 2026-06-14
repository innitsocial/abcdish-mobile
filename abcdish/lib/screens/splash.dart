import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final AudioPlayer _sizzlePlayer;

  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0, 0.75, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.85, curve: Curves.easeOutBack),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.12, 0.82, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
    _sizzlePlayer = AudioPlayer(playerId: 'splash_sizzle');
    _playSizzle();
    _bootstrap();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sizzlePlayer.dispose();
    super.dispose();
  }

  Future<void> _playSizzle() async {
    try {
      await _sizzlePlayer.setReleaseMode(ReleaseMode.stop);
      await _sizzlePlayer.setVolume(0.32);
      await _sizzlePlayer.play(AssetSource('audio/sizzle.wav'));
    } catch (error) {
      debugPrint('Splash sizzle sound error: $error');
    }
  }

  Future<void> _bootstrap() async {
    try {
      await Future.wait([
        ref
            .read(authProvider.notifier)
            .checkLoginStatus()
            .timeout(const Duration(seconds: 5)),
        Future<void>.delayed(const Duration(milliseconds: 1850)),
      ]);
    } catch (error) {
      debugPrint('Splash bootstrap error: $error');
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    if (!mounted) return;

    setState(() {
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE94335),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE94335),
                  Color(0xFFFF7A45),
                  Color(0xFF2E7D32),
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: _SplashCircle(
              size: 220,
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _SplashCircle(
              size: 260,
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 94,
                            height: 94,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                              ),
                            ),
                            child: const Icon(
                              Icons.restaurant_menu,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Any Buddy',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall!
                                .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 1.02,
                                ),
                          ),
                          Text(
                            'Can Dish',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall!
                                .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 1.02,
                                ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'ABCDish',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 36),
                          SizedBox(
                            width: 112,
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.22,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashCircle extends StatelessWidget {
  const _SplashCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
