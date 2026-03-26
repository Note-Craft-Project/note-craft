import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/level_selection_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: NoteCraftApp(),
    ),
  );
}

class NoteCraftApp extends StatelessWidget {
  const NoteCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoteCraft',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.ubuntuTextTheme(),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Scaffold(backgroundColor: Colors.transparent, body: Center(child: Text('Leaderboard'))),
    const Scaffold(backgroundColor: Colors.transparent, body: Center(child: Text('Profile'))),
  ];

  final List<Map<String, String>> _navItems = [
    {
      'label': 'Home',
      'activeIcon': 'assets/icons/home_active.svg',
      'inactiveIcon': 'assets/icons/home_inactive.svg',
    },
    {
      'label': 'Leaderboard',
      'activeIcon': 'assets/icons/leaderboard_active.svg',
      'inactiveIcon': 'assets/icons/leaderboard_inactive.svg',
    },
    {
      'label': 'Profile',
      'activeIcon': 'assets/icons/profile_active.svg',
      'inactiveIcon': 'assets/icons/profile_inactive.svg',
    },
  ];

  Widget _buildNavItem(int index, String activeIcon, String inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              isSelected ? activeIcon : inactiveIcon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isSelected ? const Color(0xFF4F8BFB) : const Color(0xFF91A1E2),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF4F8BFB) : const Color(0xFF91A1E2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: GradientBackground(
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(13),
            topRight: Radius.circular(13),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E6FE9).withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: _navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildNavItem(
              index,
              item['activeIcon']!,
              item['inactiveIcon']!,
              item['label']!,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Scale factors to convert Figma 360x640 coords to current screen size
    final double scaleX = size.width / 360;
    final double scaleY = size.height / 640;

    // Aura radius (Large, to ensure soft bleed)
    final double auraRadius = size.width * 0.9; 

    return Stack(
      children: [
        // 1. BASE: Pure White
        Positioned.fill(
          child: Container(color: Colors.white),
        ),

        // 2. BLUE LINEAR: 25% Opacity
        Positioned.fill(
          child: Opacity(
            opacity: 0.25,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D55CC), Color(0xFF91A1E2)],
                ),
              ),
            ),
          ),
        ),
        
        // 3. PURPLE AURA: Top-Left (Figma: 63.5, 20.5)
        Positioned(
          left: (63.5 * scaleX) - auraRadius,
          top: (20.5 * scaleY) - auraRadius,
          child: Opacity(
            opacity: 0.3,
            child: Container(
              width: auraRadius * 2,
              height: auraRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8441AC),
                    const Color(0xFF4F33BD).withValues(alpha: 0.5),
                    const Color(0xFF0E47B3).withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 4. ORANGE AURA: Bottom-Right (Figma: 298.4, 615.4)
        Positioned(
          left: (298.4 * scaleX) - auraRadius,
          top: (615.4 * scaleY) - auraRadius,
          child: Opacity(
            opacity: 0.175,
            child: Container(
              width: auraRadius * 2,
              height: auraRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE97108),
                    const Color(0xFF9B6245).withValues(alpha: 0.5),
                    const Color(0xFF0E47B3).withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.67, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 5. CONTENT LAYER
        child,
      ],
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTopBadge(context, '53', 'assets/icons/level.svg'),
                _buildTopBadge(context, '2', 'assets/icons/streak.svg'),
              ],
            ),
            const SizedBox(height: 30),
            Image.asset(
              'assets/images/logo_app.png',
              height: 125,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LevelSelectionScreen(mode: 'Rhythm'),
                        ),
                      );
                    },
                    child: _buildLessonCard('Rhythm', 'lv1', 0.4, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LevelSelectionScreen(mode: 'Tone'),
                        ),
                      );
                    },
                    child: _buildLessonCard('Tone', 'lv1', 0.4, true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLessonCard('Ear Training', 'lv1', 0.1, false),
            const SizedBox(height: 16),
            _buildLessonCard('Sight Reading', 'locked', 0.0, false),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBadge(BuildContext context, String value, String iconPath) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(iconPath, width: 16, height: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF0E2576),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(String title, String subtitle, double progress, bool isHalfWidth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E6FE9).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0E2576),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4F8BFB),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DEFF),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F8BFB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
