import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/core/widgets/glass_container.dart';
import 'package:cadre_upsc/core/widgets/particle_background.dart';
import 'package:cadre_upsc/features/gamification/data/upsc_syllabus_data.dart';
import 'package:cadre_upsc/features/gamification/screens/quiz_loading_screen.dart';
import 'package:cadre_upsc/features/profile/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class RapidfireScreen extends StatefulWidget {
  const RapidfireScreen({super.key});

  @override
  State<RapidfireScreen> createState() => _RapidfireScreenState();
}

class _RapidfireScreenState extends State<RapidfireScreen> {
  // Currently selected subject to show topics for
  UpscSubject? _selectedSubject;
  String _selectedDifficulty = 'Officer'; // Default difficulty
  Map<String, double> _subjectMastery = {};
  bool _isMasteryLoading = true;
  
  // Search and Favorites
  String _searchQuery = "";
  bool _isSearching = false;
  Set<String> _favoriteTopics = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMasteryData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMasteryData() async {
    final strengths = await AnalyticsService().getSubjectStrengths();
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorite_topics') ?? [];
    
    if (mounted) {
      setState(() {
        _subjectMastery = strengths;
        _isMasteryLoading = false;
        _favoriteTopics = favorites.toSet();
      });
    }
  }

  Future<void> _toggleFavorite(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteTopics.contains(topic)) {
        _favoriteTopics.remove(topic);
      } else {
        _favoriteTopics.add(topic);
      }
    });
    await prefs.setStringList('favorite_topics', _favoriteTopics.toList());
  }

  void _launchMixedBag() {
    final random = Random();
    final subject = UpscSyllabusData.subjects[random.nextInt(UpscSyllabusData.subjects.length)];
    final topic = subject.topics[random.nextInt(subject.topics.length)];
    _launchQuiz(topic, subject);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Navy
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: "Search topics...",
                hintStyle: GoogleFonts.rajdhani(color: Colors.white54),
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            )
          : Text(
              "Practice Quiz",
              style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: Colors.cyanAccent,
              ),
            ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.cyanAccent),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = "";
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background
          const Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 8,
              color: Colors.blueAccent,
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header / Instruction
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      children: [
                        Text(
                          "Choose a subject to start practicing.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.rajdhani(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDifficultySelector(),
                      ],
                    ),
                  ),

                // Main Content
                Expanded(
                  child: _searchQuery.isNotEmpty
                      ? _buildSearchResults()
                      : (_selectedSubject == null
                          ? _buildSubjectGrid()
                          : _buildTopicList(_selectedSubject!)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectGrid() {
    return Column(
      children: [
        if (_selectedSubject == null) 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                   "SUBJECT PROGRESS",
                  style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 10, letterSpacing: 1.5),
                ),
                TextButton.icon(
                  onPressed: _launchMixedBag,
                  icon: const Icon(Icons.shuffle, size: 14, color: Colors.cyanAccent),
                  label: Text("MIXED BAG", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 10)),
                ),
              ],
            ),
          ),
        
        // Favorite Topics Quick Access
        if (_selectedSubject == null && _favoriteTopics.isNotEmpty && _searchQuery.isEmpty)
          Container(
            height: 60,
            margin: const EdgeInsets.only(top: 8),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _favoriteTopics.length,
              itemBuilder: (context, index) {
                final topic = _favoriteTopics.elementAt(index);
                // Find subject for this topic
                UpscSubject? topicSubject;
                for (var s in UpscSyllabusData.subjects) {
                   if (s.topics.contains(topic)) {
                     topicSubject = s;
                     break;
                   }
                }
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ActionChip(
                    backgroundColor: (topicSubject?.color ?? Colors.cyanAccent).withValues(alpha: 0.1),
                    side: BorderSide(color: (topicSubject?.color ?? Colors.cyanAccent).withValues(alpha: 0.3)),
                    label: Text(
                      topic,
                      style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _launchQuiz(topic, topicSubject ?? UpscSyllabusData.subjects[0]),
                  ),
                );
              },
            ),
          ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.95, // Adjusted for mastery text
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: UpscSyllabusData.subjects.length,
            itemBuilder: (context, index) {
              final subject = UpscSyllabusData.subjects[index];
              return _buildSubjectCard(subject);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDiffChip("Cadet"),
        const SizedBox(width: 8),
        _buildDiffChip("Officer"),
        const SizedBox(width: 8),
        _buildDiffChip("Commander"),
      ],
    );
  }

  Widget _buildDiffChip(String label) {
    bool isSelected = _selectedDifficulty == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white24),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.orbitron(
            color: isSelected ? Colors.cyanAccent : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(UpscSubject subject) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubject = subject;
        });
      },
      child: GlassContainer(
        color: subject.color.withValues(alpha: 0.1),
        border: Border.all(
          color: subject.color.withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
        blur: 10,
        opacity: 0.1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: subject.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(subject.icon, color: subject.color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              subject.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${subject.topics.length} TOPICS",
              style: GoogleFonts.shareTechMono(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
            if (!_isMasteryLoading) ...[
              const SizedBox(height: 8),
              Text(
                "MASTERY: ${_subjectMastery[subject.name]?.round() ?? 10}%",
                style: GoogleFonts.shareTechMono(
                  color: _getMasteryColor(_subjectMastery[subject.name] ?? 10),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getMasteryColor(double score) {
    if (score > 80) return Colors.greenAccent;
    if (score > 50) return Colors.amberAccent;
    return Colors.redAccent;
  }

  Widget _buildSearchResults() {
    final List<MapEntry<String, UpscSubject>> results = [];
    for (var subject in UpscSyllabusData.subjects) {
      for (var topic in subject.topics) {
        if (topic.toLowerCase().contains(_searchQuery.toLowerCase())) {
          results.add(MapEntry(topic, subject));
        }
      }
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
               "NO RESULTS FOUND",
              style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _buildTopicTile(results[index].key, results[index].value);
      },
    );
  }

  Widget _buildTopicList(UpscSubject subject) {
    return Column(
      children: [
        // Subject Header (Back button to grid)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
                onPressed: () {
                  setState(() {
                    _selectedSubject = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              Icon(subject.icon, color: subject.color, size: 24),
              const SizedBox(width: 12),
              Text(
                subject.name.toUpperCase(),
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        
        const Divider(color: Colors.white10),

        // Topic List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subject.topics.length,
            itemBuilder: (context, index) {
              final topic = subject.topics[index];
              return _buildTopicTile(topic, subject);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopicTile(String topic, UpscSubject subject) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const Icon(Icons.ads_click, color: Colors.white54, size: 20),
          title: Text(
            topic,
            style: GoogleFonts.merriweather(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _favoriteTopics.contains(topic) ? Icons.star : Icons.star_border,
                  color: _favoriteTopics.contains(topic) ? Colors.amberAccent : Colors.white24,
                  size: 20,
                ),
                onPressed: () => _toggleFavorite(topic),
              ),
              const Icon(Icons.chevron_right, color: Colors.cyanAccent),
            ],
          ),
          onTap: () {
            // Initiate Quiz
            _launchQuiz(topic, subject);
          },
        ),
      ),
    );
  }

  void _launchQuiz(String topic, UpscSubject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizLoadingScreen(
          topicId: "RAPIDFIRE_${subject.id}_${topic.replaceAll(' ', '_')}", // Unique ID
          subjectName: subject.name,
          stateName: "Rapidfire",
          difficulty: _selectedDifficulty,
        ),
      ),
    );
  }
}

