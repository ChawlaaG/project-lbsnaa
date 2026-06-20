import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadre_upsc/features/syllabus_map/providers/syllabus_provider.dart';
// import 'package:cadre_upsc/features/syllabus_map/services/syllabus_service.dart';
import 'package:cadre_upsc/features/auth/providers/user_provider.dart';
import 'package:cadre_upsc/core/widgets/glass_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../ai_sensei/services/gemini_evaluation_service.dart';
import '../../ai_sensei/widgets/evaluation_result_widget.dart';
import '../../gamification/services/quiz_service.dart';
import '../../gamification/screens/quiz_screen.dart';
import '../../../core/services/user_service.dart'; // Phase 16
import '../../admin/screens/admin_content_screen.dart'; // Phase 17
import '../../../core/widgets/app_bar_profile_button.dart';

class TopicListScreen extends ConsumerStatefulWidget {
  final String regionId;
  final String subjectName;
  final Color associatedColor;

  const TopicListScreen({
    super.key,
    required this.regionId,
    required this.subjectName,
    required this.associatedColor,
  });

  @override
  ConsumerState<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends ConsumerState<TopicListScreen> {
  @override
  Widget build(BuildContext context) {
    final syllabusAsyncValue = ref.watch(syllabusProvider(widget.regionId));

    return Scaffold(
      backgroundColor: const Color(0xFF050511),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.subjectName, style: GoogleFonts.orbitron(letterSpacing: 2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          AppBarProfileButton(),
        ],
      ),
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.associatedColor.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: widget.associatedColor.withValues(alpha: 0.4),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ],
              ),
            ),
          ),
          
          syllabusAsyncValue.when(
            data: (subject) {
              if (subject.topics.isEmpty) {
                 return const Center(child: Text("No intel available for this sector."));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: subject.topics.length,
                itemBuilder: (context, index) {
                  final topic = subject.topics[index];
                  // Trigger 'Studying' when viewing list? 
                  // Maybe not on every build. Ideally on tap.
                  // Since we don't have a "Topic Detail" screen yet, let's trigger it 
                  // when they open the "Practice" modal or click the checkbox (interaction).
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassContainer(
                      color: const Color(0xFF16213E),
                      opacity: 0.4,
                      blur: 5,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: topic.isCompleted ? Colors.green : Colors.grey.withValues(alpha: 0.3)
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          value: topic.isCompleted,
                          onChanged: (bool? value) async {
                             if (value == null) return;
                             
                             final user = ref.read(userProvider);
                             final service = ref.read(syllabusServiceProvider);

                             // Gatekeeper Logic (Phase 17)
                             if (value == true) { // Trying to mark as done
                               final hasPassed = await QuizService().hasPassedQuiz(user.uid, topic.title);
                               if (!hasPassed) {
                                 if (context.mounted) {
await showDialog<bool>(
                                     context: context,
                                     barrierDismissible: false,
                                     builder: (context) => AlertDialog(
                                       backgroundColor: const Color(0xFF16213E),
                                       title: const Text("GATEKEEPER ACTIVE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                       content: const Text("You cannot bypass this sector without proving your worth.\n\nEnter The Arena?", style: TextStyle(color: Colors.white70)),
                                       actions: [
                                         TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("RETREAT")),
                                         ElevatedButton(
                                           style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                            onPressed: () async {
                                              Navigator.pop(context, false); // Close dialog first
                                              if (context.mounted) {
                                                await Navigator.push(
                                                  context, 
                                                  MaterialPageRoute(builder: (context) => QuizScreen(topicId: topic.title, topicTitle: topic.title))
                                                );
                                              }
                                            },
                                            child: const Text("ENTER ARENA"),
                                          ),
                                       ],
                                     )
                                   );
                                   return; // Stop here if we went to quiz
                                 }
                               }
                             }
                             // Normal Toggle (if passed or if unchecking)


                             // Normal Toggle (if passed or if unchecking)
                             await service.toggleTopicCompletion(
                               user.uid, 
                               widget.regionId, 
                               topic.title, 
                               value
                             );
                             
                             // Phase 16: Log Activity if Completed
                             if (value == true) {
                               UserService().updateActivity(
                                 userId: user.uid,
                                 squadId: user.squadId ?? '',
                                 userName: user.name ?? 'Cadet',
                                 actionType: 'studying', // Marking as done = Studied
                                 description: 'completed ${topic.title}',
                               );
                             }

                             ref.invalidate(syllabusProvider(widget.regionId));
                          },
                        ),
                        title: Text(
                          topic.title,
                          style: GoogleFonts.inter(
                            color: topic.isCompleted ? Colors.greenAccent : Colors.white,
                            decoration: topic.isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: Colors.green,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Admin-only: The Librarian
                            if (ref.read(userProvider).uid == 'BKE2Hy0qjwbQXn1xEi9cHY5mgxw2') // Replace with your admin UID
                              IconButton(
                                icon: const Icon(Icons.auto_fix_high, color: Colors.purpleAccent),
                                tooltip: 'Summon The Librarian',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminContentScreen(topicName: topic.title),
                                    ),
                                  );
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
                              tooltip: 'Practice with AI Sensei',
                              onPressed: () {
                                // Phase 16: Log "Studying"
                                final user = ref.read(userProvider);
                                UserService().updateActivity(
                                     userId: user.uid,
                                     squadId: user.squadId ?? '',
                                     userName: user.name ?? 'Cadet',
                                     actionType: 'studying', 
                                     description: 'is practicing ${topic.title}',
                                );
                                _showSubmissionModal(context, topic.title);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
          ),
        ],
      ),
    );
  }

  void _showSubmissionModal(BuildContext context, String topicTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _SubmissionModal(topicTitle: topicTitle, regionId: widget.regionId),
    );
  }
}

class _SubmissionModal extends ConsumerStatefulWidget {
  final String topicTitle;
  final String regionId;

  const _SubmissionModal({required this.topicTitle, required this.regionId});

  @override
  ConsumerState<_SubmissionModal> createState() => _SubmissionModalState();
}

class _SubmissionModalState extends ConsumerState<_SubmissionModal> {
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;
  final ImagePicker _picker = ImagePicker();

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() => _isAnalyzing = true);

      // Analyze with Gemini
      final service = GeminiEvaluationService();
      final result = await service.evaluateAnswer(File(image.path), widget.topicTitle);

      if (mounted) {
        setState(() {
          _result = result;
          _isAnalyzing = false;
        });

        // Auto-Complete Check
        final scoreStr = result['score'] as String? ?? '0/10';
        final score = int.tryParse(scoreStr.split('/')[0]) ?? 0;
        
        if (score >= 5) {
          // Mark as done!
          final user = ref.read(userProvider);
          final syllabusService = ref.read(syllabusServiceProvider);
          await syllabusService.toggleTopicCompletion(
             user.uid, 
             widget.regionId, 
             widget.topicTitle, 
             true
          );
          
          // Phase 16: Log Activity via AI
          UserService().updateActivity(
               userId: user.uid,
               squadId: user.squadId ?? '',
               userName: user.name ?? 'Cadet',
               actionType: 'conquered', 
               description: 'mastered ${widget.topicTitle} with AI Sensei',
          );

          // Play Sound
          // SoundService().playLevelUp(); // Assuming static or instance
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(
                 content: Text('🎉 Passed! Topic Marked as Completed!'),
                 backgroundColor: Colors.green,
               )
             );
             // Refresh list
             ref.invalidate(syllabusProvider(widget.regionId));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("EVALUATION RESULT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(child: EvaluationResultWidget(evaluation: _result!)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "PRACTICE: ${widget.topicTitle}",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Upload a handwritten answer for AI grading.",
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          if (_isAnalyzing)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Colors.amber),
                  SizedBox(height: 16),
                  Text("The Sensei is reading...", style: TextStyle(color: Colors.amber)),
                ],
              ),
            )
          else ...[
            ElevatedButton.icon(
              onPressed: () => _handleImageSelection(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text("TAKE PHOTO"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _handleImageSelection(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text("CHOOSE FROM GALLERY"),
              style: OutlinedButton.styleFrom(
                 foregroundColor: Colors.white,
                 side: const BorderSide(color: Colors.white24),
                 padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}
