import 'package:flutter/material.dart';
import 'dart:math' show Random;
import 'package:markpro_plus/screens/dashboard_screen.dart';
import 'package:markpro_plus/screens/register_screen.dart';
import 'package:markpro_plus/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _logoAnimationController;

  // Logo animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;

  // Form field animations
  late Animation<double> _formSlideAnimation;
  late Animation<double> _formOpacityAnimation;

  // UI element animations
  late Animation<double> _emailFieldSlideAnimation;
  late Animation<double> _passwordFieldSlideAnimation;
  late Animation<double> _buttonSlideAnimation;

  // Background elements
  final List<_FloatingDot> _floatingDots = List.generate(
    15,
    (_) => _FloatingDot(),
  );

  @override
  void initState() {
    super.initState();

    // Initialize background animation controller
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();

    // Initialize form animation controller
    _formAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Initialize logo animation controller
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _logoRotationAnimation = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Form animations
    _formSlideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _formOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Field animations with staggered timing
    _emailFieldSlideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _passwordFieldSlideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _buttonSlideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logoAnimationController.forward();
      _formAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _backgroundAnimationController.dispose();
    _formAnimationController.dispose();
    _logoAnimationController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use Firebase Auth to sign in
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        // Use page route transition for smooth animation
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              
              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;

      // Handle different Firebase Auth error codes
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email address.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        default:
          message = 'An error occurred. Please try again later.';
      }

      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address to reset password.';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _authService.resetPassword(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;

      if (e.code == 'user-not-found') {
        message = 'No user found with this email address.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else {
        message = 'Failed to send password reset email. Please try again.';
      }

      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again later.';
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Animated background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        const Color(0xFF1E3A8A).withOpacity(0.8),
                        const Color(0xFF0F172A),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Top Logo Section
                          Container(
                            margin: const EdgeInsets.only(bottom: 40),
                            child: Column(
                              children: [
                                // Logo
                                Transform.translate(
                                  offset: Offset(
                                    0,
                                    _logoScaleAnimation.value * 10,
                                  ),
                                  child: Transform.rotate(
                                    angle: _logoRotationAnimation.value,
                                    child: Container(
                                      height: 100,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF3B82F6), Color(0xFF10B981)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            spreadRadius: 1,
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "M+",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // App Name with glow effect
                                const Text(
                                  "MarkPro+",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Color(0xFF3B82F6),
                                        offset: Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Tagline
                                Text(
                                  "Streamlining Academic Excellence",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Login Form
                          Transform.translate(
                            offset: Offset(
                              0,
                              _formSlideAnimation.value,
                            ),
                            child: Opacity(
                              opacity: _formOpacityAnimation.value,
                              child: Container(
                                width: isSmallScreen ? double.infinity : 400,
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        "Sign In",
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Welcome back, please login to your account",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 30),

                                      // Email Field
                                      Transform.translate(
                                        offset: Offset(
                                          0,
                                          _emailFieldSlideAnimation.value,
                                        ),
                                        child: _buildTextField(
                                          controller: _emailController,
                                          labelText: 'Email Address',
                                          hintText: 'professor@university.edu',
                                          prefixIcon: Icons.email_outlined,
                                          keyboardType: TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                .hasMatch(value)) {
                                              return 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Password Field
                                      Transform.translate(
                                        offset: Offset(
                                          0,
                                          _passwordFieldSlideAnimation.value,
                                        ),
                                        child: _buildTextField(
                                          controller: _passwordController,
                                          labelText: 'Password',
                                          hintText: '******',
                                          prefixIcon: Icons.lock_outline,
                                          obscureText: _obscurePassword,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            if (value.length < 6) {
                                              return 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),

                                      // Forgot Password Link
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: _isLoading ? null : _resetPassword,
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(0xFF3B82F6),
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(50, 30),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Forgot Password?',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Error Message
                                      if (_errorMessage != null) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 15,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.red.shade200,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.red.shade700,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage!,
                                                  style: TextStyle(
                                                    color: Colors.red.shade700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                      ],

                                      // Sign In Button
                                      Transform.translate(
                                        offset: Offset(
                                          0,
                                          _buttonSlideAnimation.value,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _signIn,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF10B981),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            elevation: 2,
                                            disabledBackgroundColor: Colors.grey.shade300,
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      Colors.white,
                                                    ),
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text(
                                                  'Sign In',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Create Account Link
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Don't have an account?",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _isLoading ? null : () {
                                              Navigator.of(context).pushReplacement(
                                                PageRouteBuilder(
                                                  pageBuilder: (context, animation, secondaryAnimation) => const RegisterScreen(),
                                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                    const begin = Offset(1.0, 0.0);
                                                    const end = Offset.zero;
                                                    const curve = Curves.easeInOutCubic;
                                                    
                                                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                                    var offsetAnimation = animation.drive(tween);
                                                    
                                                    return SlideTransition(
                                                      position: offsetAnimation,
                                                      child: FadeTransition(
                                                        opacity: animation,
                                                        child: child,
                                                      ),
                                                    );
                                                  },
                                                  transitionDuration: const Duration(milliseconds: 600),
                                                ),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(0xFF3B82F6),
                                              padding: const EdgeInsets.only(left: 8),
                                              minimumSize: const Size(50, 30),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Create Account',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Animated floating dots
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _backgroundAnimationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _FloatingDotsPainter(
                          _floatingDots,
                          _backgroundAnimationController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 16,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: Colors.grey.shade600,
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF3B82F6),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.red.shade300,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.red.shade500,
            width: 1.5,
          ),
        ),
      ),
      validator: validator,
    );
  }
}

class _FloatingDot {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double opacity;
  final Random _random = Random();

  _FloatingDot() {
    reset();
  }

  void reset() {
    // Position anywhere on screen
    x = _random.nextDouble() * 400;
    y = _random.nextDouble() * 800;

    // Random properties
    size = 2 + _random.nextDouble() * 3;
    speed = 0.2 + _random.nextDouble() * 0.7;
    opacity = 0.05 + _random.nextDouble() * 0.1;
  }

  void update(Size size) {
    y -= speed; // Move up

    // If dot moves off screen, reset it at bottom
    if (y < -10) {
      y = size.height + 10;
      x = _random.nextDouble() * size.width;
    }
  }
}

class _FloatingDotsPainter extends CustomPainter {
  final List<_FloatingDot> _dots;
  final double _animationValue;

  _FloatingDotsPainter(this._dots, this._animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1 + (_animationValue * 0.05)) // Use animation value to slightly pulse the dots
      ..style = PaintingStyle.fill;

    for (final dot in _dots) {
      dot.update(size);

      canvas.drawCircle(
        Offset(dot.x, dot.y),
        dot.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
