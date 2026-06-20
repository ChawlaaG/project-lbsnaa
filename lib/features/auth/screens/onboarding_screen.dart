import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/features/auth/screens/login_screen.dart';
import 'package:cadre_upsc/core/widgets/radar_grid_background.dart';
import 'package:cadre_upsc/core/widgets/pulse_icon.dart';
import 'package:cadre_upsc/core/services/sound_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _introKey = GlobalKey<IntroductionScreenState>();
  
  // Personnel File Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  
  // Validation state
  bool _nameError = false;
  String? _nameErrorText;

  Future<void> _onIntroEnd(context) async {
    // Validate name is required
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = true;
        _nameErrorText = 'NAME REQUIRED — Please enter your name';
      });
      SoundService().playError();
      // Navigate back to the form page (index 2)
      _introKey.currentState?.animateScroll(2);
      return;
    }

    // Validate name format (letters, spaces, periods only)
    final nameRegex = RegExp(r'^[a-zA-Z\s.]+$');
    if (!nameRegex.hasMatch(name)) {
      setState(() {
        _nameError = true;
        _nameErrorText = 'INVALID NAME — Letters, spaces, and periods only';
      });
      SoundService().playError();
      _introKey.currentState?.animateScroll(2);
      return;
    }

    if (name.length < 2) {
      setState(() {
        _nameError = true;
        _nameErrorText = 'TOO SHORT — Minimum 2 characters required';
      });
      SoundService().playError();
      _introKey.currentState?.animateScroll(2);
      return;
    }

    SoundService().playButtonTap();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);
    
    // Save Draft Profile
    await prefs.setString('draft_name', name);
    await prefs.setString('draft_bio', _bioController.text.trim());

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // Cinematic Upgrade: Pulse Icon Wrapper
  Widget _buildImage(IconData icon, Color color) {
    return PulseIcon(
      icon: icon,
      color: color,
      size: 80,
    );
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 16.0, color: Colors.white70);

    final pageDecoration = PageDecoration(
      titleTextStyle: GoogleFonts.orbitron(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
      bodyTextStyle: GoogleFonts.shareTechMono(textStyle: bodyStyle),
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.transparent,
      imagePadding: const EdgeInsets.only(bottom: 24),
      contentMargin: const EdgeInsets.all(16),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF050511), // Deep Space
      body: Stack(
        children: [
          // 1. Background Radar
          const Positioned.fill(child: RadarGridBackground(color: Colors.cyanAccent)),
          
          // 2. Onboarding Slider
          IntroductionScreen(
            key: _introKey,
            globalBackgroundColor: Colors.transparent,
            allowImplicitScrolling: true,
            autoScrollDuration: null,
            
            pages: [
              // SLIDE 1: IDENTITY
              PageViewModel(
                title: "WELCOME TO CADRE",
                body: "You're joining CADRE — a platform built to prepare India's next generation of civil servants.\n\nMussoorie is not a dream; it is your target.",
                image: _buildImage(Icons.fingerprint, Colors.cyanAccent),
                decoration: pageDecoration,
              ),
              
              // SLIDE 2: THEATRE
              PageViewModel(
                title: "THE SYLLABUS MAP",
                body: "The UPSC syllabus is vast, but it is finite. We've mapped every topic for you.\n\nMaster subjects from History to Polity, one by one.",
                image: _buildImage(Icons.map_outlined, Colors.greenAccent),
                decoration: pageDecoration,
              ),

              // SLIDE 3: PERSONNEL FILE (FORM)
              PageViewModel(
                title: "SET UP YOUR PROFILE",
                bodyWidget: Column(
                  children: [
                     Text("Tell us a bit about yourself to personalise your experience.", 
                          style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                     _buildTextField("YOUR NAME *", _nameController, Icons.person, 
                       maxLength: 50, isRequired: true),
                     const SizedBox(height: 16),
                     _buildTextField("SHORT BIO (OPTIONAL)", _bioController, Icons.format_quote,
                       maxLength: 120, isRequired: false),
                  ],
                ),
                image: _buildImage(Icons.badge, Colors.amber),
                decoration: pageDecoration,
              ),

              // SLIDE 4: PROTOCOL
              PageViewModel(
                title: "COMMENCE PROTOCOL",
                body: "Discipline is the bridge between goals and accomplishment.\n\nMaintain your daily streak, climb the ranks, and conquer the syllabus. The Academy awaits your arrival.",
                image: _buildImage(Icons.rocket_launch, Colors.purpleAccent),
                decoration: pageDecoration,
              ),
            ],
            onDone: () => _onIntroEnd(context),
            onChange: (index) {
              // Clear error when user navigates back to form
              if (index == 2 && _nameError) {
                // Keep error visible on form page
              } else {
                setState(() {
                  _nameError = false;
                  _nameErrorText = null;
                });
              }
              SoundService().playButtonTap();
            },
            showSkipButton: false, // Removed — name is required
            skipOrBackFlex: 0,
            nextFlex: 0,
            showBackButton: true,
            back: const Icon(Icons.arrow_back, color: Colors.white),
            next: const Icon(Icons.arrow_forward, color: Colors.cyanAccent),
            done: Text("LET'S BEGIN", style: GoogleFonts.orbitron(fontWeight: FontWeight.w600, color: Colors.cyanAccent)),
            curve: Curves.fastLinearToSlowEaseIn,
            controlsMargin: const EdgeInsets.all(16),
            dotsDecorator: DotsDecorator(
              size: const Size(10.0, 10.0),
              color: Colors.white24,
              activeSize: const Size(22.0, 10.0),
              activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
              activeColor: Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }

  // Cinematic Upgrade: Terminal Input with validation
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {
    int maxLength = 50,
    bool isRequired = false,
  }) {
    final bool showError = isRequired && _nameError && controller == _nameController;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 16),
          cursorColor: Colors.cyanAccent,
          cursorWidth: 4.0, // Terminal Blinking Cursor block
          maxLength: maxLength,
          onChanged: (value) {
            if (isRequired && _nameError) {
              setState(() {
                _nameError = false;
                _nameErrorText = null;
              });
            }
          },
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.orbitron(
              color: showError ? Colors.redAccent : Colors.cyanAccent,
            ),
            prefixIcon: Icon(icon, 
              color: showError ? Colors.redAccent : Colors.cyanAccent,
            ),
            counterStyle: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 10),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: showError ? Colors.redAccent : Colors.white24, 
                width: showError ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: showError ? Colors.redAccent : Colors.cyanAccent, 
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            filled: true,
            fillColor: showError ? Colors.red.withValues(alpha: 0.05) : Colors.black54,
          ),
          onTap: () => SoundService().playButtonTap(),
        ),
        if (showError && _nameErrorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              _nameErrorText!,
              style: GoogleFonts.shareTechMono(color: Colors.redAccent, fontSize: 11),
            ),
          ),
      ],
    );
  }

}
