import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../gamification/screens/prelims_dashboard.dart';

class PrelimsBriefingScreen extends StatelessWidget {
  const PrelimsBriefingScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenPrelimsOnboarding', true);

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PrelimsDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 16.0, color: Colors.white70);
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700, color: Colors.amber),
      bodyTextStyle: bodyStyle,
      pageColor: Color(0xFF0F172A),
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      globalBackgroundColor: const Color(0xFF0F172A),
      allowImplicitScrolling: true,
      autoScrollDuration: null,
      pages: [
        PageViewModel(
          title: "WELCOME TO CADRE",
          body: "Two Papers. One Day. \nNegative Marking is Active. \n\nOnly the disciplined fall forward.",
          image: const Center(child: Icon(Icons.crisis_alert, size: 120, color: Colors.redAccent)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "PAPER 1: THE DECIDER",
          body: "100 Questions.\nHistory. Polity. Economy. Geography.\n\nThis score defines your Rank.",
          image: const Center(child: Icon(Icons.map, size: 120, color: Colors.blueAccent)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "PAPER 2: THE GATEKEEPER",
          body: "CSAT (Aptitude).\nMath & Logic.\n\nYou need 33% to survive. Do not ignore it.",
          image: const Center(child: Icon(Icons.calculate, size: 120, color: Colors.greenAccent)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "YOUR MISSION",
          body: "We don't teach. We test.\n\nProve your readiness in the Simulator.\nGood luck, Officer.",
          image: const Center(child: Icon(Icons.flag, size: 120, color: Colors.amber)),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _completeOnboarding(context),
      onSkip: () => _completeOnboarding(context), // You can override onSkip callback
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      //rtl: true, // Display as right-to-left
      back: const Icon(Icons.arrow_back, color: Colors.white),
      skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white54)),
      next: const Icon(Icons.arrow_forward, color: Colors.amber),
      done: const Text('ENTER SIMULATOR', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.amber)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Colors.white24,
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
        activeColor: Colors.amber,
      ),
    );
  }
}
