import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadre_upsc/features/auth/providers/user_provider.dart';
import 'package:cadre_upsc/features/gamification/services/daily_test_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cadre_upsc/features/news/services/news_ingestion_service.dart';
import 'package:cadre_upsc/features/profile/services/analytics_service.dart';

import 'package:cadre_upsc/features/syllabus_map/widgets/syllabus_map_widget.dart';
import 'package:cadre_upsc/features/syllabus_map/models/syllabus_region.dart';
import 'package:cadre_upsc/features/syllabus_map/services/syllabus_service.dart'; // Phase 2: Syllabus Service
import 'package:cadre_upsc/features/squads/screens/squad_screen.dart';
import 'package:confetti/confetti.dart';
import 'package:cadre_upsc/core/services/sound_service.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cadre_upsc/features/profile/screens/profile_screen.dart';
import 'package:cadre_upsc/features/gamification/screens/quiz_loading_screen.dart';
import 'package:cadre_upsc/core/widgets/radar_grid_background.dart';
import 'package:cadre_upsc/features/gamification/screens/rapidfire_screen.dart';

import 'package:cadre_upsc/features/news/screens/news_screen.dart';

// New Widgets
// Removed DashboardTopBar
import 'package:cadre_upsc/features/gamification/widgets/intel_ticker.dart';
import 'package:cadre_upsc/features/gamification/widgets/mission_control_sheet.dart';

import '../../../core/services/seeding_service.dart';
import '../../../core/services/seeder_service.dart'; // Phase 6: Core Seeder
import '../../../core/services/notification_service.dart';
// import '../../../core/services/content_generation_service.dart'; // Disabled: harvester removed
import '../../../core/services/retention_service.dart';
import '../../../core/services/streak_service.dart';
import 'streak_broken_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0; // 0=Map, 1=News, 2=Rapidfire, 3=Squad, 4=Profile
  List<String> _newsHeadlines = ["LOADING NEWS...", "FETCHING UPDATES...", "CONNECTING..."];
  late ConfettiController _confettiController;
  final SoundService _soundService = SoundService();
  bool _showFirstQuizNudge = false;
  
  // Phase 47: Daily Test
  bool _isDailyPlayed = false;
  double? _dailyScore;

  // Phase 7: War Room Map Data
  Map<String, double> _regionMastery = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observe lifecycle

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Operation Live Feed: Initialize
    _initLiveFeed();

    // Operation War Room: Fetch Map Heatmap
    _fetchMapMastery();

    // Operation Drill Sergeant: Schedule Briefing
    _initNotifications();

    // Operation Ammo Drop: Auto-Seed History Content
    // Phase 6: Seed initial data (Authenticated)
    _seedAppContent();

    // Phase 2: Infinite Library (Harvester V2)
    // Disabled: Client-side harvester burns API quota per device.
    // ContentGenerationService().startHarvester();
    
    // Phase 2: Retention Engine - Session Start
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final user = ref.read(userProvider);
       RetentionService().onUserSessionStart(user.uid);
       _checkStreak(); // Check streak on every launch
       NotificationService().cancelInactivityNudge(); // User is active
       _checkFirstQuizNudge();
       _checkDailyStatus();
    });
  }

  Future<void> _checkDailyStatus() async {
    final status = await DailyTestService().isPlayedToday();
    final score = await DailyTestService().getTodayScore();
    if (mounted) {
      setState(() {
        _isDailyPlayed = status;
        _dailyScore = score;
      });
    }
  }

  Future<void> _checkFirstQuizNudge() async {
    final prefs = await SharedPreferences.getInstance();
    final hasDoneFirstQuiz = prefs.getBool('has_done_first_quiz') ?? false;
    if (!hasDoneFirstQuiz && mounted) {
      setState(() => _showFirstQuizNudge = true);
    }
  }

  Future<void> _dismissFirstQuizNudge({bool navigate = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_done_first_quiz', true);
    if (mounted) {
      setState(() => _showFirstQuizNudge = false);
      if (navigate) {
        setState(() => _currentIndex = 2); // Go to Rapidfire tab
      }
    }
  }

  Future<void> _checkStreak() async {
    final user = ref.read(userProvider);
    final result = await StreakService().checkAndUpdateStreak(
      user.uid,
      user.lastActiveDate,
      user.currentStreak,
      user.currentLevel,
    );
    if (result.status == StreakStatus.broken && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StreakBrokenScreen(previousStreak: result.previousStreak),
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = ref.read(userProvider);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      RetentionService().onUserSessionEnd(user.uid);
    } else if (state == AppLifecycleState.resumed) {
      RetentionService().onUserSessionStart(user.uid);
    }
  }

  Future<void> _initNotifications() async {
    await NotificationService().requestPermissions();
    await NotificationService().scheduleDailyBriefing();
  }

  Future<void> _initLiveFeed() async {
    // 1. Trigger Ingestion with 6-hour cooldown to prevent excessive API calls
    final prefs = await SharedPreferences.getInstance();
    final lastIngestion = prefs.getInt('last_news_ingestion_ms') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const sixHoursMs = 6 * 60 * 60 * 1000;
    if (now - lastIngestion > sixHoursMs) {
      NewsIngestionService().fetchAndIngestRSS();
      await prefs.setInt('last_news_ingestion_ms', now);
    }
    
    // 2. Fetch Latest Intel from Firestore
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('daily_brief')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.docs.isNotEmpty) {
        final titles = snapshot.docs.map((d) => d['headline'] as String).toList();
        if (mounted) {
          setState(() {
            _newsHeadlines = titles;
          });
        }
      }
    } catch (e) {
      debugPrint("Ticker Error: $e");
    }
  }

  Future<void> _fetchMapMastery() async {
    final strengths = await AnalyticsService().getSubjectStrengths();
    final Map<String, double> masteryMap = {};

    // Map Subjects to Regions (War Room Logic)
    // History -> Bihar (IN-BR)
    if (strengths.containsKey('History')) masteryMap['IN-BR'] = strengths['History']!;
    // Polity -> Delhi (IN-DL)
    if (strengths.containsKey('Polity')) masteryMap['IN-DL'] = strengths['Polity']!;
    // Economy -> Maharashtra (IN-MH)
    if (strengths.containsKey('Economy')) masteryMap['IN-MH'] = strengths['Economy']!;
    // Environment -> Kerala (IN-KL) (God's Own Country - Green)
    if (strengths.containsKey('Environment')) masteryMap['IN-KL'] = strengths['Environment']!;
    // Science -> Karnataka (IN-KA) (Silicon Valley)
    if (strengths.containsKey('Science')) masteryMap['IN-KA'] = strengths['Science']!;
    // Geography -> Madhya Pradesh (IN-MP) (Heart of India)
    if (strengths.containsKey('Geography')) masteryMap['IN-MP'] = strengths['Geography']!;
    // CSAT -> Tamil Nadu (IN-TN) (Math Genius Ramanujan)
    if (strengths.containsKey('CSAT')) masteryMap['IN-TN'] = strengths['CSAT']!;
    
    if (mounted) {
      setState(() {
        _regionMastery = masteryMap;
      });
    }
  }

  Future<void> _seedAppContent() async {
    // Only seed once per install — skips on every subsequent launch
    final prefs = await SharedPreferences.getInstance();
    final hasSeeded = prefs.getBool('has_seeded_v2') ?? false;
    if (hasSeeded) {
      debugPrint("Seeding already done. Skipping.");
      return;
    }

    // Defer seeding so the UI renders first
    await Future.delayed(const Duration(seconds: 10));
    if (!mounted) return;

    try {
      debugPrint("Starting First-Launch Seeding...");
      await SeederService().seedSyllabus();
      await SeederService().seedQuestions();
      await SeederService().seedQuizzes();
      await SeederService().seedSyllabusQueue();
      await SeedingService().seedHistoryRandomQuiz();
      await prefs.setBool('has_seeded_v2', true);
      debugPrint("Seeding complete. Flag set.");
    } catch (e) {
      debugPrint("Seeding Error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    
    // Phase 2: Data Service Migration
    final syllabusService = ref.watch(syllabusServiceProvider);
    final regions = syllabusService.getDashboardRegions();

    // Generate dynamic regions based on user progress
    final currentSyllabusRegions = regions.map((region) {
      final isUnlocked = user.territoryUnlocked.contains(region.id);
      return region.copyWith(isLocked: !isUnlocked);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow stack background to show
      body: Stack(
        children: [
          // Phase 10: Particle Background
          // Phase 45: Command Center Visuals (Radar Grid)
          const Positioned.fill(
            child: IgnorePointer(
              child: RadarGridBackground(color: Color(0xFF00F0FF)), // Cyan
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    
                    // REFACTORED: Intel Ticker Widget
                    IntelTicker(headlines: _newsHeadlines),
                    
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildBody(currentSyllabusRegions, user.avatarUrl, user),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
          ),
          // First-quiz nudge banner (only on Map tab, only on first session)
          if (_showFirstQuizNudge && _currentIndex == 0)
            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: _showFirstQuizNudge ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D3B5E), Color(0xFF0A2E4A)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2), blurRadius: 16, spreadRadius: 2),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.cyanAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('FIRST QUIZ AWAITS', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                            const SizedBox(height: 2),
                            const Text('Tap to start your first Practice quiz and earn XP', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _dismissFirstQuizNudge(navigate: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                          ),
                          child: const Text('GO →', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _dismissFirstQuizNudge(),
                        child: const Icon(Icons.close, color: Colors.white38, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody(List<SyllabusRegion> currentRegions, String? avatarUrl, dynamic user) {
    switch (_currentIndex) {
      case 0: // Map
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
          child: Stack(
            children: [
              SyllabusMapWidget(
                regions: currentRegions,
                regionMastery: _regionMastery,
                userAvatarUrl: avatarUrl ?? 'https://api.dicebear.com/9.x/bottts/png?seed=Cadet&backgroundColor=1E293B',
                onRegionTap: (regionId) {
                   _soundService.playButtonTap();
                   _showStateDossier(context, regionId);
                },
              ),
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Phase 47: Daily Test Mission
                    _buildDailyTestButton(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionExamButton(
                      context: context,
                      user: user,
                      title: "GS PAPER 1",
                      color: Colors.cyanAccent,
                      onTap: () => _startFullExam(context, user, "GS PAPER 1", "PRELIMS_GS_FULL"),
                    ),
                    _buildActionExamButton(
                      context: context,
                      user: user,
                      title: "CSAT PAPER 2",
                      color: Colors.purpleAccent,
                      onTap: () => _startFullExam(context, user, "CSAT PAPER 2", "PRELIMS_CSAT_FULL"),
                    ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 1: // Intel / News
        return const NewsScreen();
      case 2: // Rapidfire
        return const RapidfireScreen();
      case 3: // Squad
        return const SquadScreen();
      case 4: // Profile
        return const ProfileScreen();
      default:
        return const Center(child: Text("Error: Unknown Tab"));
    }
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF0F172A),
      selectedItemColor: Colors.cyanAccent,
      unselectedItemColor: Colors.blueGrey,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.orbitron(fontSize: 8),
      unselectedLabelStyle: GoogleFonts.orbitron(fontSize: 8),
      currentIndex: _currentIndex,
      onTap: (index) {
        HapticFeedback.lightImpact();
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'MAP'),
        BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'NEWS'),
        BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'PRACTICE'),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'GROUPS'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
      ],
    );
  }

  void _showStateDossier(BuildContext context, String regionId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return MissionControlSheet(
          regionId: regionId,
          onMissionSelect: (msg) {
             // Optional logic: Analytics track event
             debugPrint("Mission Selected: $msg");
          }
        );
      },
    );
  }

  Widget _buildActionExamButton({
    required BuildContext context,
    required dynamic user,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Material(
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium, 
                  color: user.isPremium ? color : Colors.grey, 
                  size: 16
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.shareTechMono(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startFullExam(BuildContext context, dynamic user, String paperName, String topicId) {
    // Proceed to Quiz Loading or Full screen mock.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizLoadingScreen(
        topicId: topicId,
        subjectName: 'PRELIMS MOCK',
        stateName: paperName,
      )),
    );
  }

  Widget _buildDailyTestButton() {
    final color = _isDailyPlayed ? Colors.greenAccent : Colors.amberAccent;
    final label = _isDailyPlayed ? "COMPLETED TODAY" : "START DAILY TEST";
    final subLabel = _isDailyPlayed && _dailyScore != null 
        ? "Score: ${_dailyScore!.toStringAsFixed(2)}" 
        : "5 Questions | +2 / -0.66";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Material(
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isDailyPlayed ? null : _startDailyTest,
          splashColor: color.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isDailyPlayed ? Icons.check_circle : Icons.bolt, 
                    color: color, 
                    size: 24
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subLabel,
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isDailyPlayed)
                  const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startDailyTest() async {
    _soundService.playButtonTap();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuizLoadingScreen(
          topicId: 'daily_mission',
          subjectName: 'DAILY TEST',
          stateName: 'MISSION',
          isDailyTest: true,
        ),
      ),
    );

    // Refresh status after returning
    if (result != null) {
      _checkDailyStatus();
    }
  }

} // End of HomeDashboard State class
