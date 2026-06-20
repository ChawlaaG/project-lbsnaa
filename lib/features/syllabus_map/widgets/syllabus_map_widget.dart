// ... (imports remain)
import 'package:flutter/material.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/syllabus_region.dart';

class SyllabusMapWidget extends StatefulWidget {
  final List<SyllabusRegion> regions;
  final Function(String regionId) onRegionTap;
  final String? userAvatarUrl;
  final Map<String, double>? regionMastery; // 0.0 to 100.0

  const SyllabusMapWidget({
    super.key,
    required this.regions,
    required this.onRegionTap,
    this.userAvatarUrl,
    this.regionMastery,
  });

  @override
  State<SyllabusMapWidget> createState() => _SyllabusMapWidgetState();
}

class _SyllabusMapWidgetState extends State<SyllabusMapWidget> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Sweep every 4 seconds
    )..repeat();
    _radarAnimation = Tween<double>(begin: -0.2, end: 1.2).animate(_radarController);
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }
  // Key Syllabus Locations (Code Names Only)
  static const List<Map<String, dynamic>> _stateLabels = [
    {'label': 'JK', 'top': 40.0, 'left': 90.0, 'id': 'IN-JK'},
    {'label': 'PB', 'top': 80.0, 'left': 90.0, 'id': 'IN-PB'},
    {'label': 'HP', 'top': 70.0, 'left': 110.0, 'id': 'IN-HP'},
    {'label': 'UT', 'top': 90.0, 'left': 130.0, 'id': 'IN-UT'},
    {'label': 'DL', 'top': 105.0, 'left': 115.0, 'id': 'IN-DL'},
    {'label': 'RX', 'top': 140.0, 'left': 60.0, 'id': 'IN-RJ'}, // Rajasthan
    {'label': 'UP', 'top': 135.0, 'left': 160.0, 'id': 'IN-UP'},
    {'label': 'BR', 'top': 150.0, 'left': 210.0, 'id': 'IN-BR'},
    {'label': 'WB', 'top': 180.0, 'left': 230.0, 'id': 'IN-WB'},
    {'label': 'NE', 'top': 130.0, 'left': 280.0, 'id': 'IN-AS'}, // North East General
    {'label': 'GJ', 'top': 190.0, 'left': 40.0, 'id': 'IN-GJ'},
    {'label': 'MP', 'top': 190.0, 'left': 130.0, 'id': 'IN-MP'},
    {'label': 'MH', 'top': 230.0, 'left': 80.0, 'id': 'IN-MH'},
    {'label': 'TS', 'top': 260.0, 'left': 140.0, 'id': 'IN-TG'},
    {'label': 'AP', 'top': 290.0, 'left': 150.0, 'id': 'IN-AP'},
    {'label': 'KA', 'top': 300.0, 'left': 100.0, 'id': 'IN-KA'},
    {'label': 'TN', 'top': 350.0, 'left': 140.0, 'id': 'IN-TN'},
    {'label': 'KL', 'top': 340.0, 'left': 110.0, 'id': 'IN-KL'},
    {'label': 'OR', 'top': 210.0, 'left': 190.0, 'id': 'IN-OR'},
    {'label': 'CH', 'top': 200.0, 'left': 170.0, 'id': 'IN-CT'}, // Chhattisgarh
  ];

  Color _getColorForMastery(double? mastery) {
    if (mastery == null) return Colors.grey.shade800; // Unknown/Locked
    if (mastery <= 0) return Colors.grey.shade800;
    if (mastery < 30) return Colors.redAccent.withValues(alpha: 0.6); // Critical
    if (mastery < 70) return Colors.amber.withValues(alpha: 0.6); // Warning
    return Colors.greenAccent.withValues(alpha: 0.6); // Secure
  }

  @override
  Widget build(BuildContext context) {
    // Generate Color Map
    final Map<String, Color> stateColors = {};
    for (var region in widget.regions) {
      if (!region.isLocked) {
        // Using mastery color if available, else fallback to associated color
        if (widget.regionMastery != null && widget.regionMastery!.containsKey(region.id)) {
          stateColors[region.id] = _getColorForMastery(widget.regionMastery![region.id]);
        } else {
          stateColors[region.id] = region.associatedColor.withValues(alpha: 0.8);
        }
      } else {
        stateColors[region.id] = Colors.grey.shade800;
      }
    }

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 1. The panning wrapper
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 3.5,
                  panEnabled: true,
                  scaleEnabled: true,
                  boundaryMargin: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth,
                    vertical: constraints.maxHeight,
                  ),
                  clipBehavior: Clip.none,
                  child: Center(
                    child: SizedBox(
                      width: 350,
                      height: 400,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 1. The Base Map
                          SimpleMap(
                            instructions: SMapIndia.instructions,
                            defaultColor: Colors.grey.shade800, // Darker Grey for "Secret Base" feel
                            colors: stateColors, // Apply Heatmap 
                            countryBorder: const CountryBorder(
                              color: Colors.white12, // Faint border
                              width: 0.5,
                            ),
                            callback: (id, name, tapDetails) {
                              debugPrint("SimpleMap Tapped: $id");
                              // Direct interaction handling
                              widget.onRegionTap(id);
                            },
                          ),
                          
                          // 2. The "Code Name" Layer (Text Only)
                          ..._stateLabels.map((l) => Positioned(
                            top: l['top'] as double,
                            left: l['left'] as double,
                            child: GestureDetector(
                              onTap: () {
                                 debugPrint("Label Tapped: ${l['label']}");
                                 widget.onRegionTap(l['id'] as String);
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Pulsing Beacon
                                  if (widget.regionMastery?.containsKey(l['id']) ?? false)
                                    RepaintBoundary(
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(bottom: 2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _getColorForMastery(widget.regionMastery![l['id']]),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _getColorForMastery(widget.regionMastery![l['id']]).withValues(alpha: 0.8),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        ),
                                      ),
                                    ),
                                  Text(
                                    l['label'] as String,
                                    style: GoogleFonts.rajdhani( // Typography Update
                                      color: Colors.cyanAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        const Shadow(offset: Offset(1, 1), color: Colors.black, blurRadius: 2),
                                      ],
                                    ),
                                  ),
                                  // Mini Mastery Bar
                                  if (widget.regionMastery?.containsKey(l['id']) ?? false)
                                    Container(
                                      width: 20,
                                      height: 3,
                                      margin: const EdgeInsets.only(top: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(1.5),
                                        border: Border.all(color: Colors.white12, width: 0.5),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: (widget.regionMastery![l['id']]! / 100.0).clamp(0.0, 1.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _getColorForMastery(widget.regionMastery![l['id']]),
                                            borderRadius: BorderRadius.circular(1.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Fixed Overlay Layers
              // Vignette Overlay (The "Fade" to background)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0F172A).withValues(alpha: 0.8), // Semi-transparent Slate
                        const Color(0xFF0F172A), // Solid Slate at edges
                      ],
                      stops: const [0.4, 0.85, 1.0],
                      center: Alignment.center,
                      radius: 0.85,
                    ),
                  ),
                ),
              ),

              // Animated Radar Sweep
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _radarAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, constraints.maxHeight * _radarAnimation.value),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.cyanAccent.withValues(alpha: 0.8),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // HUD Overlay
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        "MISSION: TAP A REGION TO ENGAGE",
                        style: GoogleFonts.shareTechMono(
                          color: Colors.cyanAccent,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}

