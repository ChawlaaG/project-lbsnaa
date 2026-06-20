import 'package:flutter/material.dart';
import '../models/squad_entity.dart';
import '../services/squad_service.dart';
import 'package:cadre_upsc/core/widgets/glass_container.dart';
import 'package:cadre_upsc/core/widgets/radar_grid_background.dart';
import 'package:cadre_upsc/features/squads/screens/squad_war_screen.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/providers/user_provider.dart';

class SquadScreen extends ConsumerWidget {
  const SquadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final squadService = SquadService();

    if (user.squadId == null) {
      return _buildNoSquadView(context, ref);
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          centerTitle: false,
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.grid_view), text: "STUDY GROUP"),
              Tab(icon: Icon(Icons.chat), text: "CHAT"),
              Tab(icon: Icon(Icons.emoji_events), text: "GROUP CHALLENGE"),
            ],
          ),
        ),
        body: StreamBuilder<SquadEntity?>(
          stream: squadService.getSquadStream(user.squadId!),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final squad = snapshot.data;
            if (squad == null) {
               return const Center(child: Text('Study group not found', style: TextStyle(color: Colors.white)));
            }

            return TabBarView(
              children: [
                // Tab 1: Members & Stats (Existing)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSquadHeader(squad),
                      const SizedBox(height: 24),
                      _buildSquadSlots(squad, context, ref),
                      const SizedBox(height: 32),
                      _buildLibraryView(squad),
                      const SizedBox(height: 32),
                      _buildSquadChallenges(squad),
                      const SizedBox(height: 32),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            squadService.leaveSquad(squad.id, user.uid);
                          },
                          child: const Text('LEAVE GROUP', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ),
                    ],
                  ),
                ),

                 // Tab 2: Chat
                 _ChatTab(squadId: squad.id, userId: user.uid, userName: user.name ?? 'Cadet'),

                 // Tab 3: Squad Wars
                 SquadWarScreen(squadId: squad.id),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoSquadView(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const Positioned.fill(
          child: RadarGridBackground(color: Colors.cyanAccent),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: GlassContainer(
              padding: const EdgeInsets.all(32),
              color: const Color(0xFF1E293B),
              opacity: 0.6,
              blur: 15,
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.group_off_rounded, size: 48, color: Colors.cyanAccent),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "LONE WOLF",
                    style: GoogleFonts.orbitron(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Join a study group to learn together, participate in squad wars, and boost your rank.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showJoinSquadDialog(context, ref),
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text("FIND SQUAD"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCreateSquadDialog(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("CREATE SQUAD"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateSquadDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Create Study Group', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter Group Name',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  final user = ref.read(userProvider);
                  await SquadService().createSquad(nameController.text, user.uid);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('CREATE', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showJoinSquadDialog(BuildContext context, WidgetRef ref) async {
    // Fetch available squads
    final squads = await SquadService().getAvailableSquads();
    
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Join a Group', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: squads.isEmpty 
            ? const Text('No groups available.', style: TextStyle(color: Colors.white54))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: squads.length,
                itemBuilder: (context, index) {
                  final s = squads[index];
                  return ListTile(
                    title: Text(s.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${s.memberIds.length}/5 Members', style: const TextStyle(color: Colors.white54)),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        try {
                          final user = ref.read(userProvider);
                          await SquadService().joinSquad(s.id, user.uid);
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('JOIN'),
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadHeader(SquadEntity squad) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      color: Colors.blueGrey.shade900,
      opacity: 0.6,
      blur: 20,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      child: Column(
        children: [
          Text(
            squad.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'GROUP XP',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                  ),
                  Text(
                    '${squad.squadXp}',
                    style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'WEEKLY GOAL',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                  ),
                  Text(
                    '${squad.currentWeeklyHours.toInt()} / ${squad.weeklyGoal} HRS',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (squad.currentWeeklyHours / squad.weeklyGoal).clamp(0.0, 1.0),
              backgroundColor: Colors.black26,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildEmptySlot() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12, style: BorderStyle.solid),
          ),
          child: const Icon(Icons.add, color: Colors.white24),
        ),
         const SizedBox(height: 8),
        const Text(
          'RECRUIT',
          style: TextStyle(color: Colors.white12, fontSize: 10),
        ),
      ],
    );
  }


  Widget _buildLibraryView(SquadEntity squad) {
    // Phase 16: Real Activity Feed
    final squadService = SquadService();

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F3460),
      opacity: 0.5,
      blur: 10,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_library_rounded, size: 20, color: Colors.amber),
              const SizedBox(width: 8),
              const Text(
                'GROUP ACTIVITY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          StreamBuilder<List<SquadActivity>>(
            stream: squadService.getSquadActivityStream(squad.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Connection Offline', style: TextStyle(color: Colors.red));
              }
              
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final activities = snapshot.data!;
              if (activities.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.monitor_heart, color: Colors.blueAccent.withValues(alpha: 0.2), size: 48),
                        const SizedBox(height: 16),
                        Text("FLATLINE", style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 14)),
                        const SizedBox(height: 8),
                        const Text("The pack is silent. Start a drill.", style: TextStyle(color: Colors.white30, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: activities.map((activity) => _buildLibraryItem(
                  context, 
                  activity.userName, 
                  activity.actionType,
                  activity.description,
                  activity.timeAgo, 
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryItem(BuildContext context, String name, String type, String description, String time) {
    IconData icon;
    Color color;

    switch (type) {
      case 'conquered':
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case 'failed':
        icon = Icons.dangerous; // Skull-like
        color = Colors.redAccent;
        break;
      case 'studying':
      default:
        icon = Icons.menu_book;
        color = Colors.blueAccent;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    children: [
                      TextSpan(text: '$name ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (type == 'conquered')
                        const TextSpan(text: 'conquered ', style: TextStyle(color: Colors.amber)),
                      if (type == 'failed')
                        const TextSpan(text: 'failed ', style: TextStyle(color: Colors.redAccent)),
                      if (type == 'studying')
                        const TextSpan(text: 'is reading ', style: TextStyle(color: Colors.blueAccent)),
                      TextSpan(text: description),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadChallenges(SquadEntity squad) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF2E0219),
      opacity: 0.5,
      blur: 10,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech, size: 20, color: Colors.redAccent),
              const SizedBox(width: 8),
              const Text(
                'ACTIVE GOALS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Operation Blitzkrieg: real squadXp vs 5000 target
          _buildChallengeItem(
            "Operation: Blitzkrieg",
            "Earn 5000 Squad XP",
            squad.squadXp / 5000,
            "${squad.squadXp} / 5000 XP",
          ),
          const SizedBox(height: 12),
          // Operation Iron Wall: count members with active streaks
          FutureBuilder<int>(
            future: _countMembersWithStreak(squad.memberIds),
            builder: (context, snapshot) {
              final activeCount = snapshot.data ?? 0;
              final total = squad.memberIds.length;
              final progress = total > 0 ? activeCount / total : 0.0;
              return _buildChallengeItem(
                "Operation: Iron Wall",
                "All members maintain an active study streak",
                progress,
                "$activeCount / $total Active",
              );
            },
          ),
        ],
      ),
    );
  }

  Future<int> _countMembersWithStreak(List<String> memberIds) async {
    if (memberIds.isEmpty) return 0;
    int count = 0;
    for (final uid in memberIds) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final streak = (doc.data()?['currentStreak'] as num?)?.toInt() ?? 0;
        if (streak > 0) count++;
      } catch (_) {}
    }
    return count;
  }

  Widget _buildChallengeItem(String title, String desc, double progress, String progressText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(progressText, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.black26,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  // Updated to accept context/ref for Nudge
  Widget _buildSquadSlots(SquadEntity squad, BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ROSTER (MAX 5)',
          style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            if (index < squad.memberIds.length) {
              return _buildOccupiedSlot(index, squad.memberIds[index], context, ref); // Pass ID
            } else {
              return _buildEmptySlot();
            }
          }),
        ),
      ],
    );
  }
  
  // NOTE: memberIds is list of UIDs. 
  // For prototype, we might not have names map here unless we fetch user profiles.
  // We'll use "Cadet {i}" for now, but Nudge will send a generic "Someone nudged you" message to chat.

  Widget _buildOccupiedSlot(int index, String memberUid, BuildContext context, WidgetRef ref) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(memberUid).snapshots(),
      builder: (context, snapshot) {
        bool isOnline = false;
        String displayName = 'Cadet ${index + 1}';
        String? avatarUrl;

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          isOnline = data?['isOnline'] == true;
          final name = data?['name'] as String?;
          if (name != null && name.isNotEmpty) {
            displayName = name.length > 8 ? name.substring(0, 8) : name;
          }
          avatarUrl = data?['avatarUrl'] as String?;
        }

        return GestureDetector(
          onLongPress: () {
            final user = ref.read(userProvider);
            SquadService().sendMessage(
              'squads/${user.squadId}/messages',
              '👉 Nudged $displayName to study!',
              user.uid,
              user.name ?? 'Cadet',
              isSystem: true,
            );
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nudge sent to chat!")));
          },
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blueGrey.shade700,
                    foregroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : NetworkImage('https://api.dicebear.com/9.x/bottts/png?seed=$memberUid&backgroundColor=1E293B'),
                    onForegroundImageError: (_, __) {},
                    child: Text(
                            displayName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.greenAccent : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1A1A2E), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                displayName,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatTab extends StatefulWidget {
  final String squadId;
  final String userId;
  final String userName;

  const _ChatTab({required this.squadId, required this.userId, required this.userName});

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    
    SquadService().sendMessage(
      'squads/${widget.squadId}/messages', 
      _controller.text.trim(), 
      widget.userId, 
      widget.userName
    );
    _controller.clear();
    // Scroll to bottom
    if (_scrollController.hasClients) {
       _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: SquadService().getMessagesStream(widget.squadId), // Need to implement this in service
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Chat Offline... (${snapshot.error})", style: TextStyle(color: Colors.white54)));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final messages = snapshot.data!;
              if (messages.isEmpty) {
                return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.speaker_notes_off, color: Colors.blueAccent.withValues(alpha: 0.2), size: 48),
                    const SizedBox(height: 16),
                    Text("NO INTERCEPTS", style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 8),
                    const Text("Broadcast your first message to the squad.", style: TextStyle(color: Colors.white30, fontSize: 12)),
                  ],
                ),
              );
              }

              return ListView.builder(
                controller: _scrollController,
                reverse: true, // Show latest at bottom
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['senderId'] == widget.userId;
                  final isSystem = msg['isSystem'] == true;

                  if (isSystem) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['text'] ?? '',
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    );
                  }

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      decoration: BoxDecoration(
                         color: isMe ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.white10,
                         borderRadius: BorderRadius.only(
                           topLeft: const Radius.circular(12),
                           topRight: const Radius.circular(12),
                           bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                           bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                         ),
                         border: Border.all(color: isMe ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(msg['senderName'] ?? 'Unknown', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Input Area
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Broadcast message...",
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Colors.amber),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
