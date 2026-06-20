import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cadre_upsc/features/auth/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../onboarding/screens/prelims_briefing_screen.dart';
import 'prelims_dashboard.dart';
import 'package:cadre_upsc/core/widgets/particle_background.dart';
import 'package:cadre_upsc/features/gamification/screens/daily_operation_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    

  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Navy
      body: Stack(
        children: [
           // Background Elements (Subtle Gradient)
          Container(
             decoration: const BoxDecoration(
               gradient: LinearGradient(
                 begin: Alignment.topCenter,
                 end: Alignment.bottomCenter,
                 colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
               ),
             ),
          ),
          
          // Atmosphere (Particle Overlay)
          const Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 15,
              color: Colors.white10,
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "WELCOME TO CADRE, ${user.name?.toUpperCase() ?? 'OFFICER'}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "SELECT YOUR GATE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              fontFamily: 'Serif', // Fallback to Serif for now
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blueGrey,
                        foregroundImage: NetworkImage(user.avatarUrl ?? 'https://api.dicebear.com/9.x/bottts/png?seed=Cadet&backgroundColor=1E293B'),
                        onForegroundImageError: (_, __) {},
                        child: Text(
                          (user.name ?? 'C')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // THE THREE GATES
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildGateCard(
                          title: "GATE 1: PRELIMS",
                          subtitle: "THE SCREENING",
                          isLocked: false,
                          color: Colors.blueAccent,
                          onTap: () => _navigateToPrelims(),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),

                  // QUICK STRIKE SECTION
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('QUICK STRIKE',
                        style: GoogleFonts.orbitron(
                            color: Colors.white38, fontSize: 10, letterSpacing: 2)),
                  ),
                  _buildQuickStrikeCardWithBadge(
                    icon: Icons.bolt,
                    label: 'DAILY\nOPERATION',
                    color: Colors.greenAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DailyOperationScreen()),
                      );
                    },
                  ),

                  const Spacer(),
                  
                  // Footer
                  const Center(
                    child: Text(
                      "CADRE v1.0.6",
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGateCard({
    required String title,
    required String subtitle,
    required bool isLocked,
    required Color color,
    required VoidCallback onTap,
  }) {
    Widget card = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 140,
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFF1E293B) : const Color(0xFF1E293B).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked ? Colors.white10 : color.withValues(alpha: 0.6),
            width: isLocked ? 1 : 2,
          ),
          boxShadow: isLocked ? [] : [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isLocked ? Colors.white38 : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isLocked ? Colors.white24 : color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3.0,
                    ),
                  ),
                ],
              ),
            ),
            
            // Lock Icon / Arrow
            Positioned(
              right: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  isLocked ? Icons.lock : Icons.arrow_forward_ios,
                  color: isLocked ? Colors.white12 : Colors.white,
                  size: isLocked ? 32 : 24,
                ),
              ),
            ),
          ],
        ),
      );

    if (isLocked) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final sineValue = sin(_shakeController.value * pi * 4); // 2 cycles
            return Transform.translate(
              offset: Offset(sineValue * 10, 0),
              child: child,
            );
          },
          child: card,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }

  Widget _buildQuickStrikeCardWithBadge({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color.withValues(alpha: 0.4), size: 24),
                const SizedBox(height: 6),
                Text(label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                        color: color.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.cyan,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'LIVE',
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToPrelims() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenPrelimsOnboarding') ?? false;

    if (!mounted) return;

    if (hasSeenOnboarding) {
       Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const PrelimsDashboard()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const PrelimsBriefingScreen()),
      );
    }
  }
}
