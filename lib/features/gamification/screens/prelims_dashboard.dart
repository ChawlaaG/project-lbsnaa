import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadre_upsc/features/auth/providers/user_provider.dart';
import 'package:cadre_upsc/core/models/user_entity.dart';
import 'package:cadre_upsc/features/syllabus_map/widgets/syllabus_map_widget.dart';

import 'package:cadre_upsc/core/widgets/glass_container.dart';
import 'package:cadre_upsc/features/syllabus_map/screens/topic_list_screen.dart';
import 'package:cadre_upsc/features/news/screens/news_screen.dart';
import 'package:cadre_upsc/features/gamification/screens/quiz_loading_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/features/syllabus_map/services/syllabus_service.dart';

// Renamed from HomeDashboard
class PrelimsDashboard extends ConsumerStatefulWidget {
  const PrelimsDashboard({super.key});

  @override
  ConsumerState<PrelimsDashboard> createState() => _PrelimsDashboardState();
}

class _PrelimsDashboardState extends ConsumerState<PrelimsDashboard> with TickerProviderStateMixin {
  int _currentIndex = 0; // Default to GS


  // Syllabus data is now served from SyllabusService (same source as HomeDashboard)
  // No hardcoding needed here — unlock state is driven by user.territoryUnlocked

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(user),
      body: _buildBody(user),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  AppBar _buildAppBar(UserEntity user) {
     return AppBar(
       backgroundColor: const Color(0xFF0F172A),
       elevation: 0,
       leading: IconButton(
         icon: const Icon(Icons.arrow_back, color: Colors.white),
         onPressed: () => Navigator.of(context).pop(),
       ),
       title: Row(
         children: [
           Text("PRELIMS SIMULATOR", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
           const Spacer(),
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
               color: Colors.amber.withValues(alpha: 0.1),
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: Colors.amber),
             ),
             child: Text("${user.xpPoints} XP", style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
           ),
         ],
       ),
     );
  }

  Widget _buildBody(UserEntity user) {
    switch (_currentIndex) {
      case 0: // GS (Map)
        // Use same SyllabusService as HomeDashboard for consistent data
        final syllabusService = ref.read(syllabusServiceProvider);
        final baseRegions = syllabusService.getDashboardRegions();
        final currentSyllabusRegions = baseRegions.map((region) {
          final isUnlocked = user.territoryUnlocked.contains(region.id);
          return region.copyWith(isLocked: !isUnlocked);
        }).toList();

        return Stack(
          children: [
            SyllabusMapWidget(
              regions: currentSyllabusRegions,
              userAvatarUrl: user.avatarUrl ?? 'https://api.dicebear.com/9.x/bottts/png?seed=Cadet&backgroundColor=1E293B',
              onRegionTap: (regionId) {
                final regionIndex = currentSyllabusRegions.indexWhere((r) => r.id == regionId);
                if (regionIndex == -1) return;
                final region = currentSyllabusRegions[regionIndex];
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => TopicListScreen(
                    regionId: regionId,
                    subjectName: region.subjectName,
                    associatedColor: region.associatedColor,
                  )),
                );
              },
            ),
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionExamButton(
                    context: context,
                    user: user,
                    title: "TAKE GS PAPER 1",
                    color: Colors.cyanAccent,
                    onTap: () => _startFullExam(context, user, "GS PAPER 1", "PRELIMS_GS_FULL"),
                  ),
                  _buildActionExamButton(
                    context: context,
                    user: user,
                    title: "TAKE CSAT PAPER 2",
                    color: Colors.purpleAccent,
                    onTap: () => _startFullExam(context, user, "CSAT PAPER 2", "PRELIMS_CSAT_FULL"),
                  ),
                ],
              ),
            ),
          ],
        );

      case 1: // CSAT (Gym)
        return _buildCSATGym();

      case 2: // News
        return const NewsScreen();

      default:
        return const Center(child: Text("Functionality Offline"));
    }
  }

  Widget _buildActionExamButton({
    required BuildContext context,
    required UserEntity user,
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

  void _startFullExam(BuildContext context, UserEntity user, String paperName, String topicId) {
    // Proceed to Quiz Loading or Full screen mock.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizLoadingScreen(
        topicId: topicId,
        subjectName: 'PRELIMS MOCK',
        stateName: paperName,
      )),
    );
  }

  Widget _buildCSATGym() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "APTITUDE GYM (CSAT)",
          style: TextStyle(color: Colors.white54, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildCSATCard("Logic & Reasoning", "Pattern recognition drills.", Icons.psychology, Colors.purple, "CSAT_LOGIC_RAPID"),
        const SizedBox(height: 12),
        _buildCSATCard("Quantitative Aptitude", "Mathematical speed drills.", Icons.calculate, Colors.blue, "CSAT_MATH_RAPID"),
        const SizedBox(height: 12),
        _buildCSATCard("Reading Comprehension", "Speed reading tests.", Icons.menu_book, Colors.orange, "CSAT_RC_RAPID"),
      ],
    );
  }
  
  Widget _buildCSATCard(String title, String subtitle, IconData icon, Color color, String topicId) {
    return GlassContainer(
       padding: EdgeInsets.zero,
       color: const Color(0xFF1E293B),
       opacity: 0.8,
       borderRadius: BorderRadius.circular(12),
       border: Border.all(color: Colors.white12),
       child: Material(
         color: Colors.transparent,
         child: InkWell(
           borderRadius: BorderRadius.circular(12),
           splashColor: Colors.cyanAccent.withValues(alpha: 0.1),
           highlightColor: Colors.cyanAccent.withValues(alpha: 0.05),
           onTap: () => Navigator.of(context).push(
             MaterialPageRoute(builder: (_) => QuizLoadingScreen(
               topicId: topicId,
               subjectName: 'CSAT',
               stateName: title,
             )),
           ),
           child: Padding(
             padding: const EdgeInsets.all(20),
             child: Row(
               children: [
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: color.withValues(alpha: 0.2),
                     shape: BoxShape.circle,
                   ),
                   child: Icon(icon, color: color),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                       Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                     ],
                   ),
                 ),
                 const Icon(Icons.arrow_forward_ios, color: Colors.cyanAccent, size: 16),
               ],
             ),
           ),
         ),
       ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF16213E),
      selectedItemColor: Colors.amber,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'PAPER 1 (GS)'),
        BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'PAPER 2 (CSAT)'),
        BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'NEWS'),
      ],
    );
  }
}

