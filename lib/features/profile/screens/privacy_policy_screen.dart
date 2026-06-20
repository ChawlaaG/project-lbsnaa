import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'PRIVACY POLICY',
          style: GoogleFonts.orbitron(
            color: Colors.cyanAccent,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('Privacy Policy'),
            _buildBody(
              'This privacy policy applies to the Cadre app (hereby referred to as "Application") '
              'for mobile devices that was created by Manish Chawla (hereby referred to as "Service Provider") '
              'as a Free service. This service is intended for use "AS IS".',
            ),

            _buildSection('Information Collection and Use',
              'The Application collects information when you download and use it. '
              'This information may include:\n\n'
              '• Your device\'s Internet Protocol address (e.g. IP address)\n'
              '• The pages of the Application that you visit, the time and date of your visit, '
              'the time spent on those pages\n'
              '• The time spent on the Application\n'
              '• The operating system you use on your mobile device\n\n'
              'The Application does not gather precise information about the location of your mobile device.\n\n'
              'The Application uses AI technologies (Google Gemini) solely to generate '
              'educational quiz content and study analysis. Your personal data is not used '
              'to train any AI models.\n\n'
              'The Service Provider may use the information you provided to contact you from '
              'time to time to provide you with important information, required notices and '
              'marketing promotions.\n\n'
              'For a better experience, while using the Application, the Service Provider may '
              'require you to provide us with certain personally identifiable information, '
              'including your Google account information. The information that the Service '
              'Provider requests will be retained by them and used as described in this privacy policy.',
            ),

            _buildSection('Third Party Access',
              'Only aggregated, anonymized data is periodically transmitted to external services '
              'to aid the Service Provider in improving the Application and their service.\n\n'
              'The Application utilizes the following third-party services that have their own '
              'Privacy Policy about handling data:\n\n'
              '• Google Play Services — policies.google.com/privacy\n'
              '• Google Analytics for Firebase — firebase.google.com/support/privacy\n'
              '• Firebase Crashlytics — firebase.google.com/support/privacy\n'
              '• Google Gemini AI — ai.google/responsibility/privacy\n\n'
              'The Service Provider may disclose User Provided and Automatically Collected Information:\n\n'
              '• As required by law, such as to comply with a subpoena or similar legal process;\n'
              '• When they believe in good faith that disclosure is necessary to protect their rights, '
              'protect your safety or the safety of others, investigate fraud, or respond to a government request;\n'
              '• With their trusted service providers who work on their behalf, do not have an independent '
              'use of the information we disclose to them, and have agreed to adhere to the rules set '
              'forth in this privacy statement.',
            ),

            _buildSection('Opt-Out Rights',
              'You can stop all collection of information by the Application easily by uninstalling it. '
              'You may use the standard uninstall processes as may be available as part of your mobile '
              'device or via the mobile application marketplace or network.',
            ),

            _buildSection('Data Retention Policy',
              'The Service Provider will retain User Provided data for as long as you use the Application '
              'and for a reasonable time thereafter. If you\'d like them to delete User Provided Data '
              'that you have provided via the Application, please contact them at manish0319@gmail.com '
              'and they will respond in a reasonable time.',
            ),

            _buildSection('Children',
              'The Service Provider does not use the Application to knowingly solicit data from or market '
              'to children under the age of 13.\n\n'
              'The Application does not address anyone under the age of 13. The Service Provider does not '
              'knowingly collect personally identifiable information from children under 13 years of age. '
              'In the case the Service Provider discovers that a child under 13 has provided personal '
              'information, the Service Provider will immediately delete this from their servers. If you '
              'are a parent or guardian and you are aware that your child has provided us with personal '
              'information, please contact the Service Provider (manish0319@gmail.com) so that they will '
              'be able to take the necessary actions.',
            ),

            _buildSection('Security',
              'The Service Provider is concerned about safeguarding the confidentiality of your information. '
              'The Service Provider provides physical, electronic, and procedural safeguards to protect '
              'information the Service Provider processes and maintains.',
            ),

            _buildSection('Changes',
              'This Privacy Policy may be updated from time to time for any reason. The Service Provider '
              'will notify you of any changes to the Privacy Policy by updating this page with the new '
              'Privacy Policy. You are advised to consult this Privacy Policy regularly for any changes, '
              'as continued use is deemed approval of all changes.\n\n'
              'This privacy policy is effective as of 2026-02-25.',
            ),

            _buildSection('Your Consent',
              'By using the Application, you are consenting to the processing of your information as '
              'set forth in this Privacy Policy now and as amended by us.',
            ),

            _buildSection('Contact Us',
              'If you have any questions regarding privacy while using the Application, or have questions '
              'about the practices, please contact the Service Provider via email at:\n\n'
              'manish0319@gmail.com',
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                'Effective: 2026-02-25 | com.cadre.upsc',
                style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 10),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: GoogleFonts.rajdhani(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.orbitron(
              color: Colors.cyanAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _buildBody(body),
          const SizedBox(height: 8),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildBody(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 13,
        height: 1.75,
        color: Colors.white70,
      ),
    );
  }
}
