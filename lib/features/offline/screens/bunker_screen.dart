import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/features/offline/services/offline_pack_service.dart';
import 'package:cadre_upsc/features/gamification/screens/quiz_loading_screen.dart';
import 'package:cadre_upsc/features/gamification/models/quiz_entity.dart';

class BunkerScreen extends StatefulWidget {
  const BunkerScreen({super.key});

  @override
  State<BunkerScreen> createState() => _BunkerScreenState();
}

class _BunkerScreenState extends State<BunkerScreen> {
  List<QuizEntity> _packs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    // Artificial delay for effect
    await Future.delayed(const Duration(milliseconds: 500));
    final packs = OfflinePackService().getLocalPacks();
    if (mounted) {
      setState(() {
        _packs = packs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("BUNKER PROTOCOL", style: GoogleFonts.blackOpsOne(color: Colors.redAccent, letterSpacing: 2.0)),
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
        : _packs.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text("NO RATIONS FOUND", style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 18)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context), // Go back to profile to download
                    child: const Text("RETURN TO BASE TO DOWNLOAD SUPPLIES", style: TextStyle(color: Colors.cyanAccent)),
                  )
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _packs.length,
              itemBuilder: (context, index) {
                final pack = _packs[index];
                return _buildPackCard(pack);
              },
            ),
    );
  }

  Widget _buildPackCard(QuizEntity pack) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizLoadingScreen(
              topicId: pack.id,
              subjectName: "Offline Ops",
              stateName: "BUNKER",
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle
              ),
              child: const Icon(Icons.lock_clock, color: Colors.redAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pack.title, style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("${pack.questions.length} QUESTIONS // READY", style: GoogleFonts.shareTechMono(color: Colors.greenAccent, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }
}

