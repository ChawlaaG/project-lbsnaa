import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/core/models/user_entity.dart';
import 'package:cadre_upsc/core/widgets/glass_container.dart';
import 'package:cadre_upsc/features/gamification/screens/leaderboard_screen.dart';

class DashboardTopBar extends StatefulWidget {
  final UserEntity user;

  const DashboardTopBar({super.key, required this.user});

  @override
  State<DashboardTopBar> createState() => _DashboardTopBarState();
}

class _DashboardTopBarState extends State<DashboardTopBar> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF16213E),
      opacity: 0.6,
      blur: 15,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      border: Border(bottom: BorderSide(color: Colors.blueGrey.shade700.withValues(alpha: 0.8))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2), // Border width
            decoration: BoxDecoration(
              color: Colors.cyanAccent, // Signal Border
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)
              ],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey,
              foregroundImage: NetworkImage(widget.user.avatarUrl ?? 'https://api.dicebear.com/9.x/bottts/png?seed=Cadet&backgroundColor=1E293B'),
              onForegroundImageError: (_, __) {},
              child: Text(
                (widget.user.name ?? 'C')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'LEVEL ${widget.user.currentLevel}',
                      style: GoogleFonts.orbitron( // Typography: Headers
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.user.xpPoints} XP',
                      style: GoogleFonts.shareTechMono( // Typography: Data
                        color: Colors.cyanAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 18),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.user.currentStreak} DAY STREAK',
                      style: GoogleFonts.rajdhani( // Typography: Body
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    // Leaderboard Button
                    IconButton(
                      icon: const Icon(Icons.emoji_events, color: Colors.amber),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                      tooltip: "Global Rankings",
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (widget.user.xpPoints % 1000) / 1000,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

