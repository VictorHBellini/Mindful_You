import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreenTela extends StatefulWidget {
  const SplashScreenTela({super.key});

  @override
  State<SplashScreenTela> createState() => _SplashScreenTelaState();
}

class _SplashScreenTelaState extends State<SplashScreenTela>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _breathingController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _breathingController,
        builder: (context, child) {
          final breathingValue = Curves.easeInOut.transform(
            _breathingController.value,
          );

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF4EFEC),
                  Color(0xFFE8DDD7),
                  Color(0xFFDCCBC2),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Transform.scale(
                      scale: 1.0 + (breathingValue * 0.18),
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFFB79A8B,
                          ).withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Transform.scale(
                      scale: 1.0 + (breathingValue * 0.12),
                      child: Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF9C8173,
                          ).withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // NOVO ÍCONE MINDFUL YOU
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(
                                0xFF8D7164,
                              ).withValues(alpha: 0.12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 18,
                                  color: Color(0xFF70574C),
                                ),
                                SizedBox(height: 2),
                                Icon(
                                  Icons.self_improvement,
                                  size: 58,
                                  color: Color(0xFF70574C),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          const Text(
                            "MINDFUL",
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 6,
                              color: Color(0xFF4F4039),
                            ),
                          ),

                          const Text(
                            "YOU",
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8,
                              color: Color(0xFF4F4039),
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "Cuide da sua mente.\nCuide de você.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1,
                              color: Color(0xFF76645C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _floatingCircle(
                  top: 120,
                  left: 45,
                  size: 12,
                ),
                _floatingCircle(
                  top: 200,
                  right: 55,
                  size: 8,
                ),
                _floatingCircle(
                  bottom: 160,
                  left: 70,
                  size: 9,
                ),
                _floatingCircle(
                  bottom: 220,
                  right: 80,
                  size: 13,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _floatingCircle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: _breathingController,
        builder: (context, child) {
          final movement = math.sin(
            _breathingController.value * math.pi * 2,
          );

          return Transform.translate(
            offset: Offset(0, movement * 8),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF8D7164,
                ).withValues(alpha: 0.25),
              ),
            ),
          );
        },
      ),
    );
  }
}
