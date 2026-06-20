import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/features/auth/providers/user_provider.dart';
import 'package:cadre_upsc/features/gamification/services/daily_operation_service.dart';
import 'package:cadre_upsc/features/gamification/models/quiz_entity.dart';
import 'package:cadre_upsc/core/widgets/glass_container.dart';
import 'package:cadre_upsc/core/widgets/particle_background.dart';

class DailyOperationScreen extends ConsumerStatefulWidget {
  const DailyOperationScreen({super.key});

  @override
  ConsumerState<DailyOperationScreen> createState() => _DailyOperationScreenState();
}

class _DailyOperationScreenState extends ConsumerState<DailyOperationScreen> {
  final DailyOperationService _service = DailyOperationService();

  List<QuestionEntity>? _questions;
  bool _isLoading = true;
  bool _showLeaderboard = false;

  // Quiz state
  int _currentIndex = 0;
  double _score = 0;
  int _correctCount = 0;
  int? _selectedOption;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _loadOperation();
  }

  Future<void> _loadOperation() async {
    final user = ref.read(userProvider);
    final completed = await _service.hasCompletedToday(user.uid);
    final questions = await _service.getTodaysOperation();

    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoading = false;
        if (completed) _showLeaderboard = true;
      });
    }
  }

  void _answer(int optionIndex) {
    if (_isAnswered) return;
    final q = _questions![_currentIndex];
    setState(() {
      _isAnswered = true;
      _selectedOption = optionIndex;
      if (optionIndex == q.correctOptionIndex) {
        _score += 2.0;
        _correctCount++;
      } else {
        _score -= 0.66;
      }
    });
  }

  void _next() {
    if (_currentIndex < _questions!.length - 1) {
      setState(() {
        _currentIndex++;
        _isAnswered = false;
        _selectedOption = null;
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final user = ref.read(userProvider);
    await _service.submitScore(user.uid, user.name ?? 'Anonymous', _score);
    if (mounted) {
      setState(() {
        _showLeaderboard = true;
      });
    }
  }

  // Time remaining until midnight
  String _timeUntilReset() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return '${h}h ${m}m remaining';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('DAILY CHALLENGE',
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 15, letterSpacing: 1.5)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(_timeUntilReset(),
                  style: GoogleFonts.shareTechMono(color: Colors.redAccent, fontSize: 11)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ParticleBackground(numberOfParticles: 10, color: Colors.amber)),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : _questions == null
                    ? _buildError()
                    : _showLeaderboard
                        ? _buildLeaderboard()
                        : _buildQuiz(),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white38, size: 64),
          const SizedBox(height: 16),
          Text('NO CONNECTION', style: GoogleFonts.orbitron(color: Colors.white54)),
          const SizedBox(height: 8),
          Text('Check connection and try again.',
              style: GoogleFonts.shareTechMono(color: Colors.white30, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final q = _questions![_currentIndex];
    final total = _questions!.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text('Q ${_currentIndex + 1} / $total',
                        style: GoogleFonts.orbitron(color: Colors.amber, fontSize: 12)),
                  ],
                ),
              ),
              Text('SCORE: ${_score.toStringAsFixed(1)}',
                  style: GoogleFonts.orbitron(color: Colors.greenAccent, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / total,
            color: Colors.amber,
            backgroundColor: Colors.white10,
          ),
          const SizedBox(height: 24),

          // Question
          GlassContainer(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            padding: const EdgeInsets.all(20),
            child: Text(q.questionText,
                style: GoogleFonts.merriweather(
                    color: Colors.white, fontSize: 16, height: 1.6, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),

          // Options
          ...List.generate(q.options.length, (i) {
            Color border = Colors.white24;
            Color bg = Colors.white.withValues(alpha: 0.04);
            if (_isAnswered) {
              if (i == q.correctOptionIndex) {
                border = Colors.greenAccent;
                bg = Colors.green.withValues(alpha: 0.15);
              } else if (i == _selectedOption) {
                border = Colors.redAccent;
                bg = Colors.red.withValues(alpha: 0.15);
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: _isAnswered ? null : () => _answer(i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(q.options[i],
                      style: GoogleFonts.roboto(color: Colors.white, fontSize: 15)),
                ),
              ),
            );
          }),

          if (_isAnswered) ...[
            const Spacer(),
            ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.withValues(alpha: 0.2),
                foregroundColor: Colors.amber,
                side: const BorderSide(color: Colors.amber),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_currentIndex < total - 1 ? 'NEXT QUESTION' : 'SUBMIT ANSWERS',
                  style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Column(
      children: [
        // Score banner
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Text('CHALLENGE COMPLETE',
                  style: GoogleFonts.orbitron(color: Colors.amber, fontSize: 14, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('${_score.toStringAsFixed(1)} / ${(_questions?.length ?? 5) * 2}.0 XP',
                  style: GoogleFonts.orbitron(
                      color: Colors.amberAccent, fontSize: 36, fontWeight: FontWeight.bold)),
              Text('$_correctCount correct answers',
                  style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.leaderboard, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Text('NATIONAL LEADERBOARD — TODAY',
                  style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 12, letterSpacing: 1)),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: StreamBuilder<List<DailyScore>>(
            stream: _service.getLeaderboardStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
              }
              final entries = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: entries.length,
                itemBuilder: (ctx, i) {
                  final entry = entries[i];
                  final isMe = entry.uid == ref.read(userProvider).uid;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.amber.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isMe ? Colors.amber.withValues(alpha: 0.5) : Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Text('${i + 1}.',
                            style: GoogleFonts.orbitron(
                                color: i == 0
                                    ? Colors.amber
                                    : i == 1
                                        ? Colors.grey
                                        : Colors.white38,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isMe ? '${entry.userName} (YOU)' : entry.userName,
                            style: GoogleFonts.rajdhani(
                                color: isMe ? Colors.amber : Colors.white,
                                fontSize: 16,
                                fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
                          ),
                        ),
                        Text('${entry.score.toStringAsFixed(1)} XP',
                            style: GoogleFonts.orbitron(color: Colors.greenAccent, fontSize: 13)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
