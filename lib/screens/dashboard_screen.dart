import 'package:flutter/material.dart';
import 'dart:math' show Random;
import 'package:markpro_plus/services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const List<Map<String, dynamic>> _quickActions = [
    {
      'title': 'Student Management',
      'icon': Icons.school,
      'color': Color(0xFF3B82F6), // Blue
      'description': 'Manage students',
      'route': '/student-management',
    },
    {
      'title': 'Subject Management',
      'icon': Icons.book,
      'color': Color(0xFF8B5CF6), // Purple
      'description': 'Manage subjects',
      'route': '/subject-management',
    },
    {
      'title': 'Lab Management',
      'icon': Icons.science,
      'color': Color(0xFF10B981), // Green
      'description': 'Manage lab sessions',
      'route': '/lab-sessions',
    },
    {
      'title': 'Mid Sessions',
      'icon': Icons.assignment,
      'color': Color(0xFFF59E0B), // Amber
      'description': 'Manage mid exams',
      'route': '/mid-sessions',
    },
    {
      'title': 'Assignment Sessions',
      'icon': Icons.description,
      'color': Color(0xFFEF4444), // Red
      'description': 'Manage assignments',
      'route': '/assignment-sessions',
    },
    {
      'title': 'Seminar Sessions',
      'icon': Icons.people,
      'color': Color(0xFF6366F1), // Indigo
      'description': 'Manage seminars',
      'route': '/seminar-sessions',
    },
    {
      'title': 'Attendance Entry',
      'icon': Icons.checklist,
      'color': Color(0xFF14B8A6), // Teal
      'description': 'Mark attendance',
      'route': '/attendance-entry',
    },
    {
      'title': 'View Analytics',
      'icon': Icons.bar_chart,
      'color': Color(0xFFEC4899), // Pink
      'description': 'View reports',
      'route': '/analytics',
    },
    {
      'title': 'Lab Feedback',
      'icon': Icons.feedback,
      'color': Color(0xFF0EA5E9), // Sky
      'description': 'Student feedback',
      'route': '/lab-feedback',
    },
    {
      'title': 'View Calendar',
      'icon': Icons.calendar_today,
      'color': Color(0xFFF97316), // Orange
      'description': 'Schedule view',
      'route': '/view-calendar',
    },
  ];

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late List<Animation<double>> _cardAnimations;
  late ScrollController _scrollController;
  final List<_AnimatedBackground> _backgroundElements = List.generate(
    20, 
    (_) => _AnimatedBackground(
      posX: Random().nextDouble(),
      posY: Random().nextDouble(),
      size: Random().nextDouble() * 10 + 5,
      opacity: Random().nextDouble() * 0.2 + 0.05,
      speed: Random().nextDouble() * 0.01 + 0.005,
    )
  );
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuint),
    );
    
    _cardAnimations = List.generate(
      DashboardScreen._quickActions.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.2 + (index * 0.03),
            0.5 + (index * 0.02),
            curve: Curves.easeOutQuint,
          ),
        ),
      ),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // Logout function
  Future<void> _logout(BuildContext context) async {
    try {
      // Show a confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        ),
      ) ?? false;
      
      // If user confirms, log them out
      if (shouldLogout) {
        await _authService.signOut();
        
        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated background elements
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BackgroundPainter(
                    _backgroundElements,
                    _animationController.value,
                  ),
                );
              },
            ),
          ),
          
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar 
              SliverAppBar(
                expandedHeight: 150.0,
                floating: false,
                pinned: true,
                stretch: true,
                elevation: 0,
                backgroundColor: const Color(0xFF1E3A8A),
                centerTitle: true,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        "M+",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'MarkPro+',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E3A8A),
                          const Color(0xFF1E3A8A).withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -40,
                          bottom: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 60.0, left: 16.0, right: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome back, Professor',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Manage your academic activities efficiently',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No new notifications'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.sync_outlined, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Syncing data...'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Logout',
                    onPressed: () => _logout(context),
                  ),
                ],
              ),
              
              // Statistics Section 
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Statistics',
                              style: TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Detailed statistics coming soon!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.analytics_outlined, size: 16),
                              label: const Text('View All'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF3B82F6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatCard(
                              title: 'Total Students',
                              value: '150',
                              icon: Icons.school,
                              color: const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              title: 'Total Subjects',
                              value: '8',
                              icon: Icons.book,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatCard(
                              title: 'Lab Sessions',
                              value: '24',
                              icon: Icons.science,
                              color: const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              title: 'Avg. Attendance',
                              value: '87%',
                              icon: Icons.checklist,
                              color: const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Quick Actions Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'All systems active',
                              style: TextStyle(
                                color: const Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Cards grid
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth > 600 ? 4 : 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final action = DashboardScreen._quickActions[index];
                      return FadeTransition(
                        opacity: _cardAnimations[index],
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(_cardAnimations[index]),
                          child: _buildActionCard(
                            title: action['title'],
                            icon: action['icon'],
                            color: action['color'],
                            description: action['description'],
                            onTap: () {
                              Navigator.of(context).pushNamed(action['route']);
                            },
                          ),
                        ),
                      );
                    },
                    childCount: DashboardScreen._quickActions.length,
                  ),
                ),
              ),
              
              // Empty space at bottom for FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create new session feature coming soon!'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: const Color(0xFF10B981),
        label: const Text('New Session'),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedBackground {
  double posX;
  double posY;
  final double size;
  final double opacity;
  final double speed;
  
  _AnimatedBackground({
    required this.posX,
    required this.posY,
    required this.size,
    required this.opacity,
    required this.speed,
  });
  
  void update() {
    posY = (posY + speed) % 1.0;
  }
}

class _BackgroundPainter extends CustomPainter {
  final List<_AnimatedBackground> elements;
  final double animationValue;
  
  _BackgroundPainter(this.elements, this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
      
    for (final element in elements) {
      element.update();
      
      paint.color = const Color(0xFF1E3A8A).withOpacity(element.opacity * animationValue);
      
      canvas.drawCircle(
        Offset(
          element.posX * size.width,
          element.posY * size.height,
        ),
        element.size,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return true;
  }
}
