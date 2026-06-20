import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ai_sensei/services/gemini_content_service.dart';
import '../../news/services/news_service.dart';

class AdminContentScreen extends StatefulWidget {
  final String topicName;

  const AdminContentScreen({super.key, required this.topicName});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  final List<String> _logs = [];
  bool _isGenerating = false;

  // --- LOGGING ---
  void _addLog(String message) {
    setState(() {
      _logs.add("[${DateTime.now().second}s] $message");
    });
  }

  // --- SINGLE QUIZ GENERATION ---
  Future<void> _generateQuiz() async {
    setState(() {
      _isGenerating = true;
      _logs.clear();
    });

    _addLog("Initializing Librarian Protocol (Single Mode)...");
    _addLog("Target Topic: ${widget.topicName}");

    try {
      final service = GeminiContentService();
      _addLog("Contacting Gemini 1.5 Flash...");
      
      final parts = widget.topicName.split(' - ');
      final stateName = parts.length > 1 ? "India" : "General"; 
      final subject = widget.topicName;

      await service.generateQuizForTopic(widget.topicName, subject, stateName);
      
      _addLog("Quiz Generated Successfully!");
      _addLog("Saved to Firestore: quizzes/${widget.topicName}");

    } catch (e) {
      _addLog("ERROR: $e");
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

   // --- NEWS OPERATION ---
  final TextEditingController _newsHeadlineController = TextEditingController();
  final TextEditingController _newsSummaryController = TextEditingController();
  final TextEditingController _newsSourceController = TextEditingController();

  Future<void> _postNews() async {
    if (_newsHeadlineController.text.isEmpty) return;
    
    try {
      _addLog("Posting News...");
      await NewsService().postBrief(
        _newsHeadlineController.text,
        _newsSummaryController.text,
        _newsSourceController.text.isEmpty ? null : _newsSourceController.text,
      );
      _addLog("News Posted Successfully!");
      _newsHeadlineController.clear();
      _newsSummaryController.clear();
      _newsSourceController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("News Deployed!")));
    } catch (e) {
      _addLog("Error Posting News: $e");
    }
  }

  // --- BULK GENERATION OPERATION ---
  Future<void> _bulkGenerate() async {
    setState(() {
      _isGenerating = true;
      _logs.clear();
    });
    
    _addLog("INITIATING BULK AMMO CRATE...");
    final topics = [
      "Indian Polity - Parliament",
      "Indian History - Freedom Struggle",
      "Indian Economy - RBI",
      "Indian Geography - Rivers",
      "Environment - Climate Change"
    ];
    
    final service = GeminiContentService();
    int successCount = 0;

    for (int i = 0; i < topics.length; i++) {
       final topic = topics[i];
       _addLog("[${i+1}/5] Targeting: $topic");
       
       try {
         final parts = topic.split(' - ');
         final subject = parts.length > 1 ? parts[1] : topic;
         final stateName = parts.length > 1 ? parts[0] : "General";

         await service.generateQuizForTopic(topic, subject, stateName);
         _addLog(">> Success!");
         successCount++;
       } catch (e) {
         _addLog(">> Failed: $e");
       }
       
       if (i < topics.length - 1) {
         _addLog("Cooling down (5s)...");
         await Future.delayed(const Duration(seconds: 5));
       }
    }
    
    _addLog("OPERATION COMPLETE. Generated $successCount/5 Quizzes.");
    if (mounted) setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("ADMIN: THE LIBRARIAN", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- TABS / SECTIONS ---
            DefaultTabController(
              length: 3,
              child: Column(
                children: [
                   const TabBar(
                     indicatorColor: Colors.amber,
                     labelColor: Colors.amber,
                     unselectedLabelColor: Colors.white54,
                     tabs: [
                       Tab(icon: Icon(Icons.bolt), text: "QUIZ"),
                       Tab(icon: Icon(Icons.newspaper), text: "NEWS"),
                       Tab(icon: Icon(Icons.storage), text: "BULK"),
                     ],
                   ),
                   const SizedBox(height: 20),
                   SizedBox(
                     height: 350, // Fixed height for tab view area
                     child: TabBarView(
                       children: [
                         // TAB 1: SINGLE GENERATOR
                         Column(
                           children: [
                             Container(
                               padding: const EdgeInsets.all(16),
                               decoration: BoxDecoration(
                                 color: Colors.blueAccent.withValues(alpha: 0.2),
                                 borderRadius: BorderRadius.circular(12),
                                 border: Border.all(color: Colors.blueAccent),
                               ),
                               child: Column(
                                 children: [
                                   const Icon(Icons.auto_awesome, size: 48, color: Colors.amber),
                                   const SizedBox(height: 16),
                                   Text(
                                     "Topic: ${widget.topicName}",
                                     style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                   ),
                                   const SizedBox(height: 8),
                                   const Text("Generate 5 Hard MCQ Questions via AI", style: TextStyle(color: Colors.white54)),
                                 ],
                               ),
                             ),
                             const SizedBox(height: 20),
                             if (_isGenerating)
                               const CircularProgressIndicator(color: Colors.amber)
                             else
                               ElevatedButton.icon(
                                  onPressed: _generateQuiz,
                                  icon: const Icon(Icons.bolt),
                                  label: const Text("GENERATE SINGLE QUIZ"),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                               ),
                           ],
                         ),
                         
                         // TAB 2: NEWS REPORTER
                         SingleChildScrollView(
                           child: Column(
                             children: [
                               TextField(
                                 controller: _newsHeadlineController,
                                 style: const TextStyle(color: Colors.white),
                                 decoration: const InputDecoration(labelText: "Headline", labelStyle: TextStyle(color: Colors.white54)),
                               ),
                               TextField(
                                 controller: _newsSummaryController,
                                 style: const TextStyle(color: Colors.white),
                                 decoration: const InputDecoration(labelText: "Summary (3 lines)", labelStyle: TextStyle(color: Colors.white54)),
                                 maxLines: 3,
                               ),
                               TextField(
                                 controller: _newsSourceController,
                                 style: const TextStyle(color: Colors.white),
                                 decoration: const InputDecoration(labelText: "Source URL (Optional)", labelStyle: TextStyle(color: Colors.white54)),
                               ),
                               const SizedBox(height: 20),
                               ElevatedButton(
                                 onPressed: _postNews,
                                 style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                 child: const Text("POST DAILY BRIEF", style: TextStyle(color: Colors.white)),
                               ),
                             ],
                           ),
                         ),
                         
                         // TAB 3: BULK GENERATOR
                         Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             const Icon(Icons.rocket_launch, size: 40, color: Colors.orangeAccent),
                             const SizedBox(height: 10),
                             const Text("Generate 5x Quizzes (Polity, History, Econ, Geo, Env)", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                             const SizedBox(height: 20),
                             if (_isGenerating)
                                const Text("OPERATION IN PROGRESS...", style: TextStyle(color: Colors.amber))
                             else
                               ElevatedButton(
                                 onPressed: _bulkGenerate,
                                 style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                 child: const Text("ACTIVATE BULK GENERATOR", style: TextStyle(color: Colors.white)),
                               ),
                           ],
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            const Text("SYSTEM LOGS:", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(_logs[index], style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Courier', fontSize: 12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
