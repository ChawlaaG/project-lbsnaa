import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/features/auth/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text("LEADERBOARD", style: GoogleFonts.orbitron(letterSpacing: 2.0, fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: const [
              Tab(text: "ALL USERS"),
              Tab(text: "TOP SQUADS"),
            ],
          ),
        ),
        body: Stack(
          children: [
             // Background
             Positioned.fill(
               child: Opacity(
                 opacity: 0.1, 
                 child: Image.asset('assets/images/grid_bg.png', repeat: ImageRepeat.repeat, errorBuilder: (c,e,s) => Container(color: Colors.transparent))
               ),
             ),
             
             TabBarView(
               children: [
                 // 1. GLOBAL AGENTS
                 _buildUserLeaderboard(user.uid),

                 // 2. TOP SQUADS
                 _buildSquadLeaderboard(user.squadId),
               ],
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserLeaderboard(String myUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('xpPoints', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Failed to load", style: TextStyle(color: Colors.red)));
        }
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 64),
                  const SizedBox(height: 20),
                  Text(
                    "NO RANKINGS YET",
                    style: GoogleFonts.orbitron(color: Colors.amber, fontSize: 16, letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "You could be #1 right now.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Complete quizzes in Rapidfire to earn XP and claim your rank.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unknown Agent';
            final xp = data['xpPoints'] ?? 0;
            final uid = docs[index].id;
            final isMe = uid == myUid;
            
            return _buildRankCard(index + 1, name, "$xp XP", isMe, false);
          },
        );
      },
    );
  }

  Widget _buildSquadLeaderboard(String? mySquadId) {
     return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('squads')
          .orderBy('squadXp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyan));
        }
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_off, color: Colors.white24, size: 48),
                const SizedBox(height: 16),
                Text("NO SQUADS DEPLOYED", style: GoogleFonts.shareTechMono(color: Colors.white54)),
              ],
            )
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unknown Squad';
            final xp = data['squadXp'] ?? 0;
            final squadId = docs[index].id;
            final isMySquad = squadId == mySquadId;
            
            return _buildRankCard(index + 1, name, "$xp XP", isMySquad, true);
          },
        );
      },
    );
  }

  Widget _buildRankCard(int rank, String title, String subtitle, bool isHighlight, bool isSquad) {
    final rankStyle = rank <= 3 
      ? GoogleFonts.orbitron(color: rank == 1 ? Colors.amber : rank == 2 ? Colors.grey : Colors.brown, fontSize: 16, fontWeight: FontWeight.bold)
      : GoogleFonts.orbitron(color: Colors.white54, fontSize: 12);
    
    final glowColor = isSquad ? Colors.cyanAccent : Colors.amber;

    // Avatar color based on rank
    Color avatarColor;
    if (rank == 1) {
      avatarColor = Colors.amber;
    } else if (rank == 2) avatarColor = Colors.grey.shade400;
    else if (rank == 3) avatarColor = const Color(0xFFCD7F32); // Bronze
    else avatarColor = const Color(0xFF1E3A5F);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isHighlight ? glowColor.withValues(alpha: 0.1) : const Color(0xFF1E293B),
        border: isHighlight ? Border.all(color: glowColor, width: 1.5) : Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isHighlight ? [BoxShadow(color: glowColor.withValues(alpha: 0.2), blurRadius: 10)] : [],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor,
          radius: 20,
          child: Text(
            "#$rank",
            style: rankStyle.copyWith(fontSize: rank <= 3 ? 12 : 11),
          ),
        ),
        title: Text(
          title.toUpperCase(), 
          style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500, fontSize: 18)
        ),
        trailing: Text(
          subtitle, 
          style: GoogleFonts.shareTechMono(color: isSquad ? Colors.cyanAccent : Colors.tealAccent, fontSize: 16)
        ),
      ),
    );
  }
}
