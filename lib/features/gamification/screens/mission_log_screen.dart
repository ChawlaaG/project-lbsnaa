import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/core/widgets/glass_container.dart';
import 'package:cadre_upsc/core/widgets/radar_grid_background.dart';
import 'package:cadre_upsc/features/auth/providers/user_provider.dart';

class MissionLogScreen extends ConsumerStatefulWidget {
  const MissionLogScreen({super.key});

  @override
  ConsumerState<MissionLogScreen> createState() => _MissionLogScreenState();
}

class _MissionLogScreenState extends ConsumerState<MissionLogScreen> {
  bool _isLoading = true;
  List<CompletedMission> _completedMissions = [];

  @override
  void initState() {
    super.initState();
    _fetchMissionLog();
  }

  Future<void> _fetchMissionLog() async {
    final user = ref.read(userProvider);

    try {
      // Fetch real completion records with actual timestamps
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('completions')
          .orderBy('completedAt', descending: true)
          .get();

      final missions = snapshot.docs.map((doc) {
        final data = doc.data();
        final regionId = data['regionId'] as String? ?? '';
        final topicTitle = data['topicTitle'] as String? ?? doc.id;
        final timestamp = data['completedAt'] as Timestamp?;
        return CompletedMission(
          title: topicTitle,
          region: _regionLabel(regionId),
          timestamp: timestamp?.toDate() ?? DateTime.now(),
          xp: 50,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _completedMissions = missions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching mission log: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _regionLabel(String regionId) {
    const map = {
      'IN-KL': 'Environment',
      'IN-MH': 'Economy',
      'IN-BR': 'History',
      'IN-DL': 'Polity',
      'IN-UT': 'Foundation',
    };
    return map[regionId] ?? regionId;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return "Today";
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("PAST QUIZZES", style: GoogleFonts.orbitron(letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: RadarGridBackground(color: Colors.cyan),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : _completedMissions.isEmpty
                    ? _buildEmptyState()
                    : _buildMissionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            "NO QUIZZES TAKEN",
            style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "Complete quizzes to see your history.",
            style: GoogleFonts.shareTechMono(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedMissions.length,
      itemBuilder: (context, index) {
        final mission = _completedMissions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassContainer(
            color: Colors.black.withValues(alpha: 0.4),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        mission.region,
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "+${mission.xp} XP",
                      style: GoogleFonts.orbitron(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(mission.timestamp),
                      style: GoogleFonts.shareTechMono(
                        color: Colors.greenAccent,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CompletedMission {
  final String title;
  final String region;
  final DateTime timestamp;
  final int xp;

  CompletedMission({
    required this.title,
    required this.region,
    required this.timestamp,
    required this.xp,
  });
}

