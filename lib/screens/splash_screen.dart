import 'package:flutter/material.dart';
import 'package:markpro_plus/screens/login_screen.dart';
import 'package:markpro_plus/screens/dashboard_screen.dart';
import 'package:markpro_plus/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' show Random, pi, sin, cos;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _hasError = false;
  String? _errorMessage;
  
  // Primary animation controllers
  late AnimationController _mainAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _gearAnimationController;
  
  // Logo animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _logoElevationAnimation;
  late Animation<double> _logoPulseAnimation;
  
  // Text animations
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;
  
  // Gear animations for mechanical feel
  late Animation<double> _gear1RotationAnimation;
  late Animation<double> _gear2RotationAnimation;
  late Animation<double> _gear3RotationAnimation;
  
  // Background elements
  final List<_FloatingDot> _floatingDots = List.generate(
    20, 
    (_) => _FloatingDot()
  );
  
  // Wave effect parameters
  final List<_Wave> _waves = [
    _Wave(height: 30, speed: 1.0, offset: 0.0, color: Colors.blue.withOpacity(0.1)),
    _Wave(height: 25, speed: 0.8, offset: 0.5, color: Colors.blue.withOpacity(0.12)),
    _Wave(height: 20, speed: 1.2, offset: 0.7, color: Colors.blue.withOpacity(0.15)),
  ];

  @override
  void initState() {
    super.initState();
    
    // Main animation controller for logo and text
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    // Continuous pulse animation
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Background animation controller
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20000),
    );
    
    // Gear rotation animation controller
    _gearAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );
    
    // Logo scale animation - starts small and grows
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    
    // Logo rotation animation - subtle rotation
    _logoRotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    // Logo elevation animation
    _logoElevationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Logo pulse animation
    _logoPulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Fade in animation for text
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );
    
    // Slide up animation for text
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Gear rotation animations
    _gear1RotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _gearAnimationController,
        curve: Curves.linear,
      ),
    );
    
    _gear2RotationAnimation = Tween<double>(begin: 0, end: -2 * pi).animate(
      CurvedAnimation(
        parent: _gearAnimationController,
        curve: Curves.linear,
      ),
    );
    
    _gear3RotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _gearAnimationController,
        curve: Curves.linear,
      ),
    );
    
    // Start animations
    _mainAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);
    _backgroundAnimationController.repeat();
    _gearAnimationController.repeat();
    
    // Initialize app and navigate after delay
    _initializeAppAndNavigate();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _pulseAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _gearAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeAppAndNavigate() async {
    try {
      // Firebase already initialized in main()
      
      // Simulating a delay for splash screen to allow animations to complete
      await Future.delayed(const Duration(seconds: 3));
      
      // Check if user is logged in
      final User? currentUser = _authService.currentUser;
      
      if (mounted) {
        if (currentUser != null) {
          // User is logged in, navigate to dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
          // User is not logged in, navigate to login screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
      // Auto-retry after 3 seconds
      Future.delayed(const Duration(seconds: 3), _initializeAppAndNavigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A), // Dark blue
      body: Stack(
        children: [
          // Animated wave background
          _buildWaveBackground(size),
          
          // Animated background dots
          ..._buildAnimatedBackground(),
          
          // Animated gears
          _buildGears(size),
          
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo with shadow and effects
                _buildAnimatedLogo(),
                
                const SizedBox(height: 30),
                
                // Animated App Name
                AnimatedBuilder(
                  animation: _mainAnimationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeInAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: const Text(
                          "MarkPro+",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Animated Tagline
                AnimatedBuilder(
                  animation: _mainAnimationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeInAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: const Text(
                          "Simplify Academic Marks Management",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 50),
                
                // Loading Indicator with typing dots
                _buildLoadingIndicator(),
                
                if (_hasError && _errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Animated logo with shadow and pulse effects
  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimationController, _pulseAnimationController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value * _logoPulseAnimation.value,
          child: Transform.rotate(
            angle: _logoRotationAnimation.value,
            child: Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF10B981)], // Blue to Green gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.2 + 0.4 * _logoElevationAnimation.value),
                    blurRadius: 10 + 15 * _logoElevationAnimation.value,
                    spreadRadius: 2 + 5 * _logoElevationAnimation.value,
                    offset: Offset(0, 5 * _logoElevationAnimation.value),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background grid pattern
                  _buildGridPattern(),
                  
                  // Logo text
                  const Text(
                    "M+",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  
                  // Shine effect
                  Positioned(
                    top: 15,
                    left: 15,
                    child: Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Grid pattern for logo background
  Widget _buildGridPattern() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: CustomPaint(
        size: const Size(140, 140),
        painter: GridPatternPainter(),
      ),
    );
  }
  
  // Build animated floating dots in the background
  List<Widget> _buildAnimatedBackground() {
    return _floatingDots.map((dot) {
      return AnimatedBuilder(
        animation: _backgroundAnimationController,
        builder: (context, _) {
          // Update dot position
          dot.update();
          
          return Positioned(
            left: dot.x,
            top: dot.y,
            child: Container(
              width: dot.size,
              height: dot.size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(dot.opacity),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      );
    }).toList();
  }
  
  // Build animated wave background
  Widget _buildWaveBackground(Size size) {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, _) {
        return ClipRect(
          child: CustomPaint(
            size: size,
            painter: WavePainter(
              waves: _waves,
              time: _backgroundAnimationController.value * 20,
              size: size,
            ),
          ),
        );
      },
    );
  }
  
  // Animated decorative gears
  Widget _buildGears(Size size) {
    return AnimatedBuilder(
      animation: _gearAnimationController,
      builder: (context, _) {
        return Stack(
          children: [
            // Main gear top right
            Positioned(
              top: size.height * 0.1,
              right: size.width * 0.1,
              child: Transform.rotate(
                angle: _gear1RotationAnimation.value,
                child: CustomPaint(
                  size: const Size(60, 60),
                  painter: GearPainter(
                    color: Colors.white.withOpacity(0.1),
                    teeth: 10,
                  ),
                ),
              ),
            ),
            
            // Small gear bottom left
            Positioned(
              bottom: size.height * 0.15,
              left: size.width * 0.15,
              child: Transform.rotate(
                angle: _gear2RotationAnimation.value,
                child: CustomPaint(
                  size: const Size(40, 40),
                  painter: GearPainter(
                    color: Colors.white.withOpacity(0.1),
                    teeth: 8,
                  ),
                ),
              ),
            ),
            
            // Smaller gear near center
            Positioned(
              top: size.height * 0.15,
              left: size.width * 0.25,
              child: Transform.rotate(
                angle: _gear3RotationAnimation.value,
                child: CustomPaint(
                  size: const Size(30, 30),
                  painter: GearPainter(
                    color: Colors.white.withOpacity(0.1),
                    teeth: 6,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Custom loading indicator with animated typing dots
  Widget _buildLoadingIndicator() {
    return _hasError
        ? const Icon(Icons.error_outline, color: Colors.red, size: 40)
        : AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Loading",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  _buildAnimatedDot(0.0),
                  _buildAnimatedDot(0.3),
                  _buildAnimatedDot(0.6),
                ],
              );
            },
          );
  }
  
  // Single animated dot for loading indicator
  Widget _buildAnimatedDot(double delay) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Interval(delay, delay + 0.4, curve: Curves.easeInOut),
      ),
    );
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Text(
            ".",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 20 + (animation.value * 4),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

// Class for animated floating dots in background
class _FloatingDot {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double opacity;
  late double direction;
  final Random _random = Random();
  
  _FloatingDot() {
    reset(true);
  }
  
  void reset(bool initializing) {
    // If initializing, position anywhere on screen
    // If not initializing, position just off-screen at top or bottom
    x = initializing 
        ? _random.nextDouble() * 400
        : _random.nextDouble() * 400;
    
    y = initializing 
        ? _random.nextDouble() * 800
        : _random.nextBool() ? -20 : 820;
        
    size = 3 + _random.nextDouble() * 8;
    speed = 0.5 + _random.nextDouble() * 1.5;
    opacity = 0.1 + _random.nextDouble() * 0.2;
    
    // Direction: -1 for up, 1 for down
    direction = y < 0 ? 1 : -1;
  }
  
  void update() {
    y += speed * direction;
    
    // If dot moves off screen, reset it
    if ((direction < 0 && y < -20) || (direction > 0 && y > 820)) {
      reset(false);
    }
  }
}

// Class for wave background
class _Wave {
  final double height;
  final double speed;
  final double offset;
  final Color color;
  
  _Wave({
    required this.height, 
    required this.speed, 
    required this.offset,
    required this.color,
  });
}

// Wave painter
class WavePainter extends CustomPainter {
  final List<_Wave> waves;
  final double time;
  final Size size;
  
  WavePainter({
    required this.waves,
    required this.time,
    required this.size,
  });
  
  @override
  void paint(Canvas canvas, Size canvasSize) {
    final height = canvasSize.height;
    final width = canvasSize.width;
    
    for (final wave in waves) {
      final path = Path();
      final paint = Paint()
        ..color = wave.color
        ..style = PaintingStyle.fill;
      
      path.moveTo(0, height);
      
      // Draw a wave using quadratic bezier curves
      for (double x = 0; x <= width; x += width / 10) {
        final y = height - height * 0.3 + 
                  sin((x / width * 2 * pi) + (time * wave.speed) + wave.offset * pi) * 
                  wave.height;
        path.lineTo(x, y);
      }
      
      path.lineTo(width, height);
      path.close();
      
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Grid pattern painter
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw vertical lines
    for (double x = 0; x <= size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Gear painter for decorative gears
class GearPainter extends CustomPainter {
  final Color color;
  final int teeth;
  
  GearPainter({required this.color, required this.teeth});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.7;
    final toothLength = outerRadius * 0.15;
    
    final path = Path();
    
    // Draw teeth
    for (int i = 0; i < teeth; i++) {
      final angle = 2 * pi * i / teeth;
      final toothAngle = pi / teeth;
      
      // Move to inner point
      final innerX = center.dx + innerRadius * cos(angle - toothAngle / 2);
      final innerY = center.dy + innerRadius * sin(angle - toothAngle / 2);
      path.moveTo(innerX, innerY);
      
      // Line to outer point
      final outerX = center.dx + (outerRadius + toothLength) * cos(angle);
      final outerY = center.dy + (outerRadius + toothLength) * sin(angle);
      path.lineTo(outerX, outerY);
      
      // Line to inner point
      final innerEndX = center.dx + innerRadius * cos(angle + toothAngle / 2);
      final innerEndY = center.dy + innerRadius * sin(angle + toothAngle / 2);
      path.lineTo(innerEndX, innerEndY);
      
      // Arc to next position
      path.arcToPoint(
        Offset(
          center.dx + innerRadius * cos(angle + 2 * pi / teeth - toothAngle / 2),
          center.dy + innerRadius * sin(angle + 2 * pi / teeth - toothAngle / 2)
        ),
        radius: Radius.circular(innerRadius),
        clockwise: false,
      );
    }
    
    path.close();
    
    // Draw center circle
    canvas.drawPath(path, paint);
    canvas.drawCircle(center, innerRadius * 0.3, paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
