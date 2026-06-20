import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/features/auth/screens/login_screen.dart';
import 'package:cadre_upsc/features/auth/providers/user_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cadre_upsc/features/profile/services/analytics_service.dart';
import 'package:cadre_upsc/features/offline/services/offline_pack_service.dart';
import 'package:cadre_upsc/features/offline/screens/bunker_screen.dart';
import 'package:cadre_upsc/features/auth/services/auth_service.dart';
import 'package:cadre_upsc/features/gamification/screens/mission_log_screen.dart';
import 'package:cadre_upsc/features/profile/screens/privacy_policy_screen.dart';
import 'package:cadre_upsc/features/profile/screens/terms_screen.dart';
import 'package:cadre_upsc/core/services/sound_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cadre_upsc/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isDeleting = false;
  bool _audioEnabled = true;
  bool _notifsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _audioEnabled = prefs.getBool('audio_enabled') ?? true;
        _notifsEnabled = prefs.getBool('notifs_enabled') ?? true;
      });
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (mounted) {
       Navigator.of(context).pushAndRemoveUntil(
         MaterialPageRoute(builder: (context) => const LoginScreen()),
         (route) => false,
       );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('DELETE ACCOUNT?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'This action is IRREVERSIBLE. All your progress, XP, and data will be permanently deleted.\n\nAre you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE FOREVER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isDeleting = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // 1. Delete Firestore Subcollections (Ghost Data Cleanup)
          final firestore = FirebaseFirestore.instance;
          final userRef = firestore.collection('users').doc(user.uid);
          
          final subcollections = ['progress', 'quiz_results', 'answered_questions', 'completions', 'offline_packs'];
          for (final sub in subcollections) {
             final snapshot = await userRef.collection(sub).get();
             if (snapshot.docs.isNotEmpty) {
               final batch = firestore.batch();
               for (final doc in snapshot.docs) {
                 batch.delete(doc.reference);
               }
               await batch.commit();
             }
          }

          // 2. Delete Firestore Main User Doc
          await userRef.delete();
          
          // 3. Delete Auth Account
          await user.delete();

          if (mounted) {
            // 4. Navigate to Login
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: $e. You may need to re-login first.')),
          );
        }
      }
    }
  }

  void _launchPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final user = ref.read(userProvider);
    final nameController = TextEditingController(text: user.name);
    final bioController = TextEditingController(text: user.bio);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("EDIT PROFILE", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Name", labelStyle: TextStyle(color: Colors.white54)),
            ),
             const SizedBox(height: 16),
            TextField(
              controller: bioController,
              style: const TextStyle(color: Colors.white),
               decoration: const InputDecoration(labelText: "Motto / Bio", labelStyle: TextStyle(color: Colors.white54)),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
             ElevatedButton(
             onPressed: () async {
                // Update Firestore
                try {
                  if (user.uid != 'guest' && FirebaseAuth.instance.currentUser != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                      'name': nameController.text.trim(),
                      'bio': bioController.text.trim(),
                    }, SetOptions(merge: true));
                  }
                  if (!dialogContext.mounted) return;
                  ref.read(userProvider.notifier).updateProfile(nameController.text.trim(), bioController.text.trim(), user.targetYear ?? '');
                  Navigator.pop(dialogContext);
                  scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green));
                } catch (e) {
                  debugPrint("Error updating profile: $e");
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  scaffoldMessenger.showSnackBar(SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red));
                }
             },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            child: const Text("UPDATE"),
          ),
        ],
      ),
    );
  }
  Future<void> _showAvatarSelectionDialog() async {
    final user = ref.read(userProvider);
    final List<String> presetAvatars = [
      'https://api.dicebear.com/9.x/bottts/png?seed=Alpha&backgroundColor=1E293B',
      'https://api.dicebear.com/9.x/bottts/png?seed=Bravo&backgroundColor=1E293B',
      'https://api.dicebear.com/9.x/bottts/png?seed=Charlie&backgroundColor=1E293B',
      'https://api.dicebear.com/9.x/bottts/png?seed=Delta&backgroundColor=1E293B',
      'https://api.dicebear.com/9.x/bottts/png?seed=Echo&backgroundColor=1E293B',
      'https://api.dicebear.com/9.x/bottts/png?seed=Foxtrot&backgroundColor=1E293B',
      'https://api.dicebear.com/9.x/avataaars/png?seed=1&backgroundColor=1E293B',
      'https://api.dicebear.com/9.x/avataaars/png?seed=2&backgroundColor=1E293B',
      'https://api.dicebear.com/9.x/avataaars/png?seed=3&backgroundColor=1E293B',
    ];
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("CHANGE AVATAR", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: presetAvatars.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final avatar = presetAvatars[index];
              final isSelected = user.avatarUrl == avatar;
              return GestureDetector(
                onTap: () async {
                  try {
                    if (user.uid != 'guest' && FirebaseAuth.instance.currentUser != null) {
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                        'avatarUrl': avatar,
                      }, SetOptions(merge: true));
                    }
                    if (!dialogContext.mounted) return;
                    ref.read(userProvider.notifier).updateAvatar(avatar);
                    Navigator.pop(dialogContext);
                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Avatar updated!'), backgroundColor: Colors.green));
                  } catch (e) {
                    debugPrint("Error updating avatar: $e");
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    scaffoldMessenger.showSnackBar(SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red));
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.transparent, width: 3),
                  ),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(avatar),
                    backgroundColor: Colors.blueGrey,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final rank = user.rank; // New Getter
    
    // Mock Stats for Phase 56 (until AnalyticsService is fully wired for these specific numbers)
    // In real implementation, these would come from user.stats or AnalyticsService

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
           // Background Grid
           Positioned.fill(
             child: Opacity(
               opacity: 0.1, 
               child: Image.asset('assets/images/grid_bg.png', repeat: ImageRepeat.repeat, errorBuilder: (c,e,s) => Container(color: Colors.transparent))
             ),
           ),
           
           SafeArea(
             child: SingleChildScrollView(
               padding: const EdgeInsets.all(24.0),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // 1. HEADER: Classified Stamp
                   Center(
                     child: Text(
                        "YOUR PROFILE",
                       style: GoogleFonts.blackOpsOne(
                         color: Colors.white10,
                         fontSize: 32,
                         letterSpacing: 4.0,
                       ),
                     ),
                   ),
                   const SizedBox(height: 32),
                   
                   // 2. ID CARD ROW
                   Row(
                     children: [
                       // Avatar with Rank Border
                       GestureDetector(
                         onTap: _showAvatarSelectionDialog, // Quick edit on avatar tap too
                         child: Stack(
                           children: [
                             Container(
                               padding: const EdgeInsets.all(4),
                               decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 border: Border.all(color: Colors.amber, width: 2),
                                 boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 20)]
                               ),
                               child: CircleAvatar(
                                 radius: 40,
                                 backgroundColor: Colors.blueGrey,
                                 foregroundImage: NetworkImage(user.avatarUrl ?? 'https://api.dicebear.com/9.x/bottts/png?seed=Cadet&backgroundColor=1E293B'),
                                 onForegroundImageError: (_, __) {},
                                 child: Text(
                                   (user.name ?? 'C')[0].toUpperCase(),
                                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                                 ),
                               ),
                             ),
                             Positioned(
                               bottom: 0,
                               right: 0,
                               child: Container(
                                 padding: const EdgeInsets.all(4),
                                 decoration: BoxDecoration(
                                   color: Colors.amber,
                                   shape: BoxShape.circle,
                                   border: Border.all(color: const Color(0xFF0F172A), width: 2),
                                 ),
                                 child: const Icon(Icons.edit, color: Colors.black, size: 14),
                               ),
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(width: 20),
                       // Name & Rank
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               children: [
                                 Expanded(
                                   child: Text(
                                     user.name?.toUpperCase() ?? 'NEW USER',
                                     style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                   ),
                                 ),
                                 IconButton(
                                   icon: const Icon(Icons.edit, color: Colors.cyanAccent, size: 18),
                                   onPressed: _showEditProfileDialog,
                                    tooltip: "Edit Profile",
                                 ),
                               ],
                             ),
                             Text(
                               rank,
                               style: GoogleFonts.shareTechMono(color: Colors.amber, fontSize: 14, letterSpacing: 1.5),
                             ),
                             if (user.bio != null && user.bio!.isNotEmpty) ...[
                               const SizedBox(height: 4),
                               Text(
                                 "\"${user.bio}\"",
                                 style: GoogleFonts.caveat(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                                 maxLines: 2,
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ],
                             const SizedBox(height: 8),
                             // XP Bar
                             ClipRRect(
                               borderRadius: BorderRadius.circular(4),
                               child: LinearProgressIndicator(
                                 value: (user.xpPoints % 1000) / 1000, 
                                 backgroundColor: Colors.white10,
                                 valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
                                 minHeight: 6,
                               ),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               "${user.xpPoints} XP",
                               style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 10),
                             ),
                           ],
                         ),
                       )
                     ],
                   ),
                   
                   const SizedBox(height: 40),

                   // 3. SERVICE RECORD GRID
                    _buildSectionHeader("YOUR STATS"),
                   FutureBuilder<Map<String, String>>(
                     future: AnalyticsService().getServiceRecord(),
                     builder: (context, snapshot) {
                       final stats = snapshot.data ?? {"accuracy": "--", "winRate": "--"};
                       return Row(
                         children: [
                            _buildStatCard("QUIZZES", "${user.totalQuizzesTaken}", Colors.cyan, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionLogScreen()));
                           }),
                           const SizedBox(width: 16),
                           _buildStatCard("COMPLETION", stats["completion"] ?? "--", Colors.greenAccent),
                           const SizedBox(width: 16),
                           _buildStatCard("ACCURACY", stats["accuracy"] ?? "--", Colors.purpleAccent),
                           const SizedBox(width: 16),
                           _buildStatCard("STREAK", "${user.currentStreak}", Colors.orangeAccent),
                         ],
                       );
                     }
                   ),

                   const SizedBox(height: 32),
                   
                   // 4. WAR ROOM ANALYTICS
                   const _SubjectRadarChart(),
                   
                   const SizedBox(height: 32),

                   // 5. SETTINGS
                    _buildSectionHeader("SETTINGS"),
                    _buildActionTile(Icons.music_note, "Audio Feedback", () {}, isToggle: true, toggleValue: _audioEnabled, onToggle: (v) async {
                      setState(() => _audioEnabled = v);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('audio_enabled', v);
                      SoundService().setEnabled(v);
                    }),
                    _buildActionTile(Icons.notifications, "Priority Alerts", () {}, isToggle: true, toggleValue: _notifsEnabled, onToggle: (v) async {
                      setState(() => _notifsEnabled = v);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notifs_enabled', v);
                      if (v) { await NotificationService().scheduleDailyBriefing(); } else { await NotificationService().cancelRetentionNotifications(); }
                    }),
                   
                   const SizedBox(height: 16),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 0.0),
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                       decoration: BoxDecoration(
                         color: const Color(0xFF1E293B),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: DropdownButtonHideUnderline(
                         child: DropdownButton<String>(
                           value: user.difficultyLevel,
                           dropdownColor: const Color(0xFF1E293B),
                           style: const TextStyle(color: Colors.white),
                           icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
                           isExpanded: true,
                           items: ["Cadet", "Officer", "Commander"]
                               .map((level) => DropdownMenuItem(
                                     value: level,
                                     child: Row(
                                       children: [
                                         Icon(
                                           level == "Cadet" ? Icons.shield_outlined : 
                                           level == "Officer" ? Icons.security : Icons.gpp_good,
                                           color: level == "Cadet" ? Colors.green : 
                                                  level == "Officer" ? Colors.amber : Colors.red,
                                           size: 18,
                                         ),
                                         const SizedBox(width: 12),
                                          Text("Difficulty: $level", style: GoogleFonts.orbitron(fontSize: 14)),
                                       ],
                                     ),
                                   ))
                               .toList(),
                           onChanged: (newValue) async {
                             if (newValue != null && newValue != user.difficultyLevel) {
                               // Update Firestore
                               try {
                                 if (user.uid != 'guest' && FirebaseAuth.instance.currentUser != null) {
                                   await FirebaseFirestore.instance
                                       .collection('users')
                                       .doc(user.uid)
                                       .set({'difficultyLevel': newValue}, SetOptions(merge: true));
                                 } else if (user.uid == 'guest') {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to save settings permanently.')));
                                 }
                                 
                                 // Update locally regardless to allow UI to reflect change immediately
                                 ref.read(userProvider.notifier).updateDifficulty(newValue);
                               } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red));
                               }
                             }
                           },
                         ),
                       ),
                     ),
                   ),
                   
                   const SizedBox(height: 32),
                   
                   // 6. BUNKER PROTOCOL (Offline Mode)
                     _buildSectionHeader("OFFLINE MODE"),
                   _buildActionTile(Icons.download_for_offline, "Download Offline Pack", () async {
                      // Trigger Download
                      ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('📦 Downloading offline pack...')),
                      );
                      
                      final success = await OfflinePackService().downloadBunkerPack();
                      
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                           content: Text(success ? '✅ Offline pack downloaded!' : '❌ Download failed. Please retry.'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                   }),
                   _buildActionTile(Icons.wifi_off, "Go Offline (Bunker)", () {
                     Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BunkerScreen()));
                   }),
                   const SizedBox(height: 32),

                   // Dev tools removed for production

                   // 8. PROTOCOLS
                     _buildSectionHeader("LEGAL"),
                    _buildActionTile(Icons.privacy_tip, "Privacy Policy", _launchPrivacyPolicy),
                    _buildActionTile(Icons.description, "Terms of Service", () { Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsScreen())); }),

                   const SizedBox(height: 48),

                   // Log Out
                   _buildActionTile(Icons.logout, "Log Out", _signOut),

                   const SizedBox(height: 24),

                   // Danger Zone
                   Container(
                     decoration: BoxDecoration(
                       color: Colors.red.withValues(alpha: 0.05),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                     ),
                     child: ListTile(
                       leading: const Icon(Icons.delete_forever, color: Colors.red),
                       title: Text("DELETE ACCOUNT", style: GoogleFonts.rajdhani(color: Colors.red, fontWeight: FontWeight.bold)),
                        subtitle: const Text("Permanently delete all your data.", style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                       onTap: _isDeleting ? null : _deleteAccount,
                       trailing: _isDeleting 
                         ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) 
                         : const Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16),
                     ),
                   ),
                    const SizedBox(height: 24),
                    Center(child: Text("CADRE v1.0.6", style: GoogleFonts.shareTechMono(color: Colors.white10, fontSize: 10))),
                 ],
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3))
          ),
          child: Column(
            children: [
              Text(value, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.shareTechMono(color: color, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap, {bool isToggle = false, bool toggleValue = true, Function(bool)? onToggle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: isToggle 
          ? Switch(value: toggleValue, onChanged: onToggle, activeThumbColor: Colors.amber) 
          : const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        onTap: isToggle ? null : onTap,
      ),
    );
  }
}

class _SubjectRadarChart extends StatefulWidget {
  const _SubjectRadarChart();

  @override
  State<_SubjectRadarChart> createState() => _SubjectRadarChartState();
}

class _SubjectRadarChartState extends State<_SubjectRadarChart> {
  final AnalyticsService _analyticsService = AnalyticsService();
  Map<String, double>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _analyticsService.getSubjectStrengths();
    if(mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _showTacticalAnalysis(BuildContext context) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );

    // Fetch Analysis
    final analysis = await _analyticsService.getAIAnalysis();

    // Close Loading
    if (context.mounted) Navigator.pop(context);

    // Show Result
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
            title: Text("SUBJECT ANALYSIS", style: GoogleFonts.blackOpsOne(color: Colors.cyanAccent, letterSpacing: 1.5)),
          content: SingleChildScrollView(
            child: Text(
              analysis,
              style: GoogleFonts.shareTechMono(color: Colors.white, height: 1.4),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text("CLOSE", style: TextStyle(color: Colors.cyanAccent)),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    if (_data == null || _data!.isEmpty) return const SizedBox.shrink();

    // Map data to RadarEntries
    final keys = _data!.keys.toList();
    final values = _data!.values.toList();
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
               "SUBJECT ANALYSIS",
              style: TextStyle(
                color: Colors.amber, 
                fontSize: 12, 
                letterSpacing: 2.0, 
                fontWeight: FontWeight.bold
              ),
            ),
            Row(
              children: [
                 IconButton(
                  icon: const Icon(Icons.psychology, color: Colors.cyanAccent, size: 20),
                   tooltip: "AI-Powered Analysis",
                  onPressed: () => _showTacticalAnalysis(context),
                ),
                IconButton(
                   icon: const Icon(Icons.refresh, color: Colors.white24, size: 16),
                   onPressed: _loadData,
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: RadarChart(
            RadarChartData(
              dataSets: [
                RadarDataSet(
                  fillColor: Colors.cyanAccent.withValues(alpha: 0.2), // Sci-fi Cyan
                  borderColor: Colors.cyanAccent,
                  entryRadius: 2,
                  dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
                  borderWidth: 2,
                ),
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              radarBorderData: const BorderSide(color: Colors.white12),
              titlePositionPercentageOffset: 0.1,
              titleTextStyle: const TextStyle(color: Colors.white70, fontSize: 10),
              // Use getTitle to map index to key (fl_chart 1.1.1 API confirmed)
              getTitle: (index, angle) {
                if (index < keys.length) {
                  return RadarChartTitle(text: keys[index], angle: 0); // Keep text horizontal
                }
                return const RadarChartTitle(text: "");
              },
              tickCount: 1,
              ticksTextStyle: const TextStyle(color: Colors.transparent),
              gridBorderData: const BorderSide(color: Colors.white12, width: 1),
              radarShape: RadarShape.polygon,
            ),
            duration: const Duration(milliseconds: 1000), // Cinematic entry
            curve: Curves.easeInOut,
          ),
        ),
      ],
    );
  }
}

