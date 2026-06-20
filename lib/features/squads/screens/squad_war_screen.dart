import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/features/squads/services/squad_war_service.dart';
import 'package:cadre_upsc/features/squads/models/squad_entity.dart';
import 'package:cadre_upsc/core/widgets/particle_background.dart';
import 'package:cadre_upsc/features/gamification/screens/daily_operation_screen.dart';

class SquadWarScreen extends ConsumerStatefulWidget {
  final String squadId;

  const SquadWarScreen({super.key, required this.squadId});

  @override
  ConsumerState<SquadWarScreen> createState() => _SquadWarScreenState();
}

class _SquadWarScreenState extends ConsumerState<SquadWarScreen> {
  final SquadWarService _warService = SquadWarService();
  SquadEntity? _mySquad;
  SquadEntity? _enemySquad;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWar();
  }

  Future<void> _loadWar() async {
    final myDoc = await _warService.getSquadStream(widget.squadId).first;
    SquadEntity? enemy;
    if (myDoc?.enemySquadId != null) {
      enemy = await _warService.getSquadStream(myDoc!.enemySquadId!).first;
    } else {
      enemy = await _warService.getOrAssignWarEnemy(widget.squadId);
    }
    if (mounted) {
      setState(() {
        _mySquad = myDoc;
        _enemySquad = enemy;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = _warService.daysUntilMonday();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          const Positioned.fill(
            child: ParticleBackground(numberOfParticles: 12, color: Colors.red),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text('SQUAD WARS',
                          style: GoogleFonts.orbitron(
                              color: Colors.redAccent, fontSize: 20, letterSpacing: 2)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                        ),
                        child: Text('$daysLeft days left',
                            style:
                                GoogleFonts.shareTechMono(color: Colors.redAccent, fontSize: 11)),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                      : _buildWarView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarView() {
    final myScoreDisplay = _mySquad?.warScore ?? 0;
    final enemyScoreDisplay = _enemySquad?.warScore ?? 0;
    final total = (myScoreDisplay + enemyScoreDisplay).clamp(1, 99999);
    final myFraction = myScoreDisplay / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // VS Banner
          Row(
            children: [
              Expanded(
                child: _buildSquadBadge(
                    _mySquad?.name ?? 'YOUR SQUAD', myScoreDisplay, Colors.cyanAccent, true),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('VS',
                    style: GoogleFonts.blackOpsOne(
                        color: Colors.redAccent, fontSize: 24, letterSpacing: 3)),
              ),
              Expanded(
                child: _buildSquadBadge(
                    _enemySquad?.name ?? 'SEARCHING...', enemyScoreDisplay, Colors.redAccent, false),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // War score bar
          Text('WAR SCORE',
              style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Flexible(
                  flex: (myFraction * 100).round().clamp(1, 99),
                  child: Container(
                    height: 28,
                    color: Colors.cyanAccent,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 8),
                    child: Text('$myScoreDisplay',
                        style: GoogleFonts.orbitron(
                            color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                Flexible(
                  flex: ((1 - myFraction) * 100).round().clamp(1, 99),
                  child: Container(
                    height: 28,
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('$enemyScoreDisplay',
                        style: GoogleFonts.orbitron(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Contribute XP CTA
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('BATTLE CONTRIBUTIONS',
                    style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent, fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                    'Every quiz you complete scores war points for your squad. Complete a Daily Operation to make a big contribution.',
                    style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 12, height: 1.5)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyOperationScreen()),
                  ),
                  icon: const Icon(Icons.bolt),
                  label: Text('LAUNCH DAILY OPERATION',
                      style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                    foregroundColor: Colors.cyanAccent,
                    side: const BorderSide(color: Colors.cyanAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadBadge(String name, int score, Color color, bool isMe) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          child: Icon(isMe ? Icons.shield : Icons.local_fire_department,
              color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(name,
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
                color: color, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
        Text('$score WAR XP',
            style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
