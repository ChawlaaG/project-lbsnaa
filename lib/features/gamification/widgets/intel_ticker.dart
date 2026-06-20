import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadre_upsc/core/widgets/glass_container.dart';

import 'dart:async';

class IntelTicker extends StatefulWidget {
  final List<String> headlines;

  const IntelTicker({super.key, required this.headlines});

  @override
  State<IntelTicker> createState() => _IntelTickerState();
}

class _IntelTickerState extends State<IntelTicker> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        final maxScrollExtent = _scrollController.position.maxScrollExtent;
        final currentScrollPosition = _scrollController.position.pixels;
        
        if (currentScrollPosition < maxScrollExtent) {
          _scrollController.jumpTo(currentScrollPosition + 1.0); // Scroll speed
        } else {
          // Wrap around seamlessly
          _scrollController.jumpTo(0.0);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 24,
      color: Colors.black.withValues(alpha: 0.3), // Darker, cleaner ticker background
      child: RepaintBoundary(
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(), // Disable manual scrolling to avoid fighting timer
          itemCount: widget.headlines.length * 10, // Artificial infinite loop modifier
          itemBuilder: (context, index) {
            final actualIndex = index % widget.headlines.length;
            return _buildTickerItem(context, widget.headlines[actualIndex]);
          },
        ),
      ),
    );
  }

  Widget _buildTickerItem(BuildContext context, String text) {
    return GestureDetector(
      onTap: () => _showIntelDetails(context, text),
      child: Padding(
        padding: const EdgeInsets.only(right: 32.0),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.shareTechMono( // Typography: Code/Data
              color: Colors.cyanAccent, // Unified Cyan
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showIntelDetails(BuildContext context, String headline) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "LATEST NEWS",
                  style: GoogleFonts.orbitron(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.cyanAccent,
                    textStyle: GoogleFonts.orbitron(fontSize: 12),
                  ),
                  child: const Text("CLOSE"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
