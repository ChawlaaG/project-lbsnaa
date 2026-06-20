import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'TERMS OF ENGAGEMENT',
          style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 13, letterSpacing: 1.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terms of Service', style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Effective: 2026-02-25', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 24),

            _section('1. Acceptance', 'By downloading or using CADRE, you agree to be bound by these Terms of Service. If you do not agree, please do not use the Application.'),

            _section('2. Use of the App',
              '• CADRE is designed for UPSC preparation purposes only.\n'
              '• You must be at least 13 years of age to use this Application.\n'
              '• You agree not to use the Application for any unlawful purpose or in any way that could harm other users.\n'
              '• You are responsible for maintaining the confidentiality of your account.'),

            _section('3. User Content',
              '• Squad messages and chat content you create remain your responsibility.\n'
              '• You agree not to post offensive, harmful, or misleading content.\n'
              '• We reserve the right to remove content that violates these terms.'),

            _section('4. AI-Generated Content',
              'CADRE uses Google Gemini AI to generate educational quiz questions and study analysis. '
              'While we strive for accuracy, AI-generated content may occasionally contain errors. '
              'Always verify critical information against official UPSC sources and study materials.'),

            _section('5. Intellectual Property',
              'The CADRE application, its design, code, and branding are the intellectual property of '
              'Manish Chawla. UPSC syllabus content is sourced from publicly available government materials. '
              'You may not copy, modify, or distribute the Application without explicit permission.'),

            _section('6. In-App Features',
              '• The leaderboard and squad features are for entertainment and motivation purposes.\n'
              '• XP points, ranks, and badges hold no real-world monetary value.\n'
              '• We reserve the right to modify, add, or remove features at any time.'),

            _section('7. Disclaimers',
              '• CADRE is an unofficial preparation aid and is NOT affiliated with UPSC, LBSNAA, or any government body.\n'
              '• We do not guarantee specific exam results from using this Application.\n'
              '• The Application is provided "AS IS" without warranties of any kind.'),

            _section('8. Limitation of Liability',
              'To the maximum extent permitted by applicable law, Manish Chawla shall not be liable for '
              'any indirect, incidental, or consequential damages resulting from your use of CADRE.'),

            _section('9. Termination',
              'We reserve the right to terminate or suspend your account at any time for violations of these '
              'Terms or for any other reason at our discretion.'),

            _section('10. Changes',
              'We may update these Terms from time to time. Continued use of the Application after changes '
              'constitutes acceptance of the revised Terms.'),

            _section('11. Contact',
              'For questions about these Terms, contact:\nmanish0319@gmail.com'),

            const SizedBox(height: 32),
            Center(child: Text('com.cadre.upsc | v1.0', style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 10))),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.75)),
          const SizedBox(height: 4),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }
}
