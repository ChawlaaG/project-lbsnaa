import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart'; // Prep for init
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/auth/providers/user_provider.dart';
import 'core/services/retention_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/gamification/screens/home_dashboard.dart';
import 'core/services/notification_service.dart';
import 'core/services/offline_mode_service.dart';
import 'core/services/guardrail_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/services/force_update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Zero-Budget: Firebase Spark
  await dotenv.load(fileName: ".env"); // Load environment variables
  // Phase 6: Seed initial data
  // Phase 6: Seeding moved to HomeDashboard (Authenticated)
  
  // Phase 2: Drill Sergeant
  await NotificationService().init();

  // Phase 2: Bunker Mode
  await OfflineModeService().init();

  // Phase 4: Guardrails
  await GuardrailService().init();

  // Fix: Force Firestore to fetch fresh data from server on app launch.
  // Without this, Firestore serves its local offline cache on first open
  // after a new APK install, making the app appear to show an older version.
  try {
    await FirebaseFirestore.instance.enableNetwork();
  } catch (_) {}

  runApp(
    const ProviderScope(
      child: ProjectLBSNAAApp(),
    ),
  );
}

class ProjectLBSNAAApp extends ConsumerStatefulWidget {
  const ProjectLBSNAAApp({super.key});

  @override
  ConsumerState<ProjectLBSNAAApp> createState() => _ProjectLBSNAAAppState();
}

class _ProjectLBSNAAAppState extends ConsumerState<ProjectLBSNAAApp> with WidgetsBindingObserver {
  bool? _showOnboarding;
  bool _needsUpdate = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final needsUpdate = await ForceUpdateService.isUpdateRequired();
    await Future.delayed(const Duration(milliseconds: 1500)); // Minimum splash duration
    setState(() {
      _showOnboarding = prefs.getBool('showOnboarding') ?? true;
      _needsUpdate = needsUpdate;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final user = ref.read(userProvider);
    if (user.uid.isEmpty || user.uid == 'guest') return; 

    if (state == AppLifecycleState.resumed) {
      RetentionService().onUserSessionStart(user.uid);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      RetentionService().onUserSessionEnd(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CADRE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050511), // Deep Space
        primaryColor: const Color(0xFF00F0FF), // Neon Cyan
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F0FF),
          secondary: Color(0xFFFF003C), // Neon Red
          surface: Color(0xFF121225),
          onError: Colors.redAccent,
        ),
        cardColor: const Color(0xFF1E293B),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF0F172A),
          modalBackgroundColor: Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ).copyWith(
          displayLarge: GoogleFonts.orbitron(textStyle: Theme.of(context).textTheme.displayLarge, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white),
          displayMedium: GoogleFonts.orbitron(textStyle: Theme.of(context).textTheme.displayMedium, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white),
          titleLarge: GoogleFonts.orbitron(textStyle: Theme.of(context).textTheme.titleLarge, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1, color: Colors.white),
          titleMedium: GoogleFonts.orbitron(textStyle: Theme.of(context).textTheme.titleMedium, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: Colors.white),
        ),
        useMaterial3: true,
      ),
      home: _showOnboarding == null 
        ? Scaffold(
            backgroundColor: const Color(0xFF050511),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CADRE',
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00F0FF),
                      letterSpacing: 6,
                      shadows: [
                        Shadow(color: const Color(0xFF00F0FF).withValues(alpha: 0.6), blurRadius: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your UPSC Preparation Command Center',
                    style: GoogleFonts.shareTechMono(
                      fontSize: 12,
                      color: Colors.white54,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFF00F0FF),
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          )
        : _needsUpdate
          ? const _ForceUpdateScreen()
          : _showOnboarding! 
            ? const OnboardingScreen() 
            : StreamBuilder<User?>(
                initialData: FirebaseAuth.instance.currentUser,
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(
                      backgroundColor: const Color(0xFF050511),
                      body: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CADRE',
                              style: GoogleFonts.orbitron(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF00F0FF),
                                letterSpacing: 6,
                                shadows: [
                                  Shadow(color: const Color(0xFF00F0FF).withValues(alpha: 0.6), blurRadius: 20),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFF00F0FF),
                                strokeWidth: 2.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasData) {
                    return const HomeDashboard();
                  }
                  return const LoginScreen();
                },
              ),
    );
  }
}

/// Shown when the app version is older than the minimum required.
/// Non-dismissible — user must update to continue.
class _ForceUpdateScreen extends StatefulWidget {
  const _ForceUpdateScreen();

  @override
  State<_ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<_ForceUpdateScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050511),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
                child: const Icon(Icons.system_update, color: Colors.amber, size: 64),
              ),
              const SizedBox(height: 24),
              Text(
                'Update Required',
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'A new version of CADRE is available.\nPlease update to continue.',
                textAlign: TextAlign.center,
                style: GoogleFonts.shareTechMono(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => ForceUpdateService.showUpdateDialog(context),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Update Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
