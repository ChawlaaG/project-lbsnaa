import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/features/gamification/screens/quiz_loading_screen.dart';

class MissionControlSheet extends StatelessWidget {
  final String regionId;
  final Function(String message)? onMissionSelect;

  const MissionControlSheet({
    super.key, 
    required this.regionId,
    this.onMissionSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.public, color: Colors.cyanAccent),
              const SizedBox(width: 12),
              Text(
                "REGION: $regionId", 
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Select a subject to start a practice quiz.",
            style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildMissionCard(context, "History", Icons.history_edu, Colors.orange, regionId),
                _buildMissionCard(context, "Polity", Icons.gavel, Colors.redAccent, regionId),
                _buildMissionCard(context, "Geography", Icons.landscape, Colors.green, regionId),
                _buildMissionCard(context, "Economy", Icons.currency_rupee, Colors.blue, regionId),
                _buildMissionCard(context, "Environment", Icons.eco, Colors.lightGreenAccent, regionId),
                _buildMissionCard(context, "Sci-Tech", Icons.rocket_launch, Colors.purpleAccent, regionId),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("BONUS TOPICS", style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMissionCard(context, "CSAT", Icons.calculate, Colors.amber, regionId)),
              const SizedBox(width: 12),
              Expanded(child: _buildMissionCard(context, "Current Affairs", Icons.newspaper, Colors.cyanAccent, regionId)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context, String title, IconData icon, Color color, String regionId) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close sheet
        
        if (onMissionSelect != null) {
          onMissionSelect!("Starting $title Quiz...");
        }
        
        // Map Region Code to State Name (Expanded Mapper)
        String stateName = "India";
        
        // North
        if (regionId.contains("JK")) {
          stateName = "Jammu & Kashmir";
        } else if (regionId.contains("PB")) stateName = "Punjab";
        else if (regionId.contains("HP")) stateName = "Himachal Pradesh";
        else if (regionId.contains("UT")) stateName = "Uttarakhand";
        else if (regionId.contains("DL")) stateName = "Delhi";
        else if (regionId.contains("HR")) stateName = "Haryana";
        
        // West/Central
        else if (regionId.contains("RJ")) stateName = "Rajasthan";
        else if (regionId.contains("GJ")) stateName = "Gujarat";
        else if (regionId.contains("MH")) stateName = "Maharashtra";
        else if (regionId.contains("MP")) stateName = "Madhya Pradesh";
        else if (regionId.contains("CT")) stateName = "Chhattisgarh";
        
        // East/North-East
        else if (regionId.contains("BR")) stateName = "Bihar";
        else if (regionId.contains("WB")) stateName = "West Bengal";
        else if (regionId.contains("OR")) stateName = "Odisha";
        else if (regionId.contains("AS")) stateName = "North East Frontier";
        
        // South
        else if (regionId.contains("TG")) stateName = "Telangana";
        else if (regionId.contains("AP")) stateName = "Andhra Pradesh";
        else if (regionId.contains("KA")) stateName = "Karnataka";
        else if (regionId.contains("TN")) stateName = "Tamil Nadu";
        else if (regionId.contains("KL")) stateName = "Kerala";
        
        else if (regionId.contains("UP")) stateName = "Uttar Pradesh"; // Catch-all for UP logic if missed above

        // Construct Topic ID
        final topicId = "${regionId}_$title";

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizLoadingScreen(
              topicId: topicId,
              subjectName: title,
              stateName: stateName,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05), // Faint bg
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.rajdhani(color: color, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

