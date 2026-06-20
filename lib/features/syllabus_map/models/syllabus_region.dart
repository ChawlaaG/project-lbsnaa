import 'package:flutter/material.dart';

class SyllabusRegion {
  final String id;
  final String subjectName;
  final bool isLocked;
  final double completionPercentage;
  final Color associatedColor;
  final List<SyllabusSubRegion> subRegions;

  const SyllabusRegion({
    required this.id,
    required this.subjectName,
    this.isLocked = true,
    this.completionPercentage = 0.0,
    required this.associatedColor,
    this.subRegions = const [],
  });

  SyllabusRegion copyWith({
    String? id,
    String? subjectName,
    bool? isLocked,
    double? completionPercentage,
    Color? associatedColor,
    List<SyllabusSubRegion>? subRegions,
  }) {
    return SyllabusRegion(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      isLocked: isLocked ?? this.isLocked,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      associatedColor: associatedColor ?? this.associatedColor,
      subRegions: subRegions ?? this.subRegions,
    );
  }
}

class SyllabusSubRegion {
  final String id;
  final String title;
  final bool isCompleted;

  const SyllabusSubRegion({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}
