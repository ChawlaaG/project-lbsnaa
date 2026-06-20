class SquadEntity {
  final String id;
  final String name;
  final List<String> memberIds;
  final int squadXp;
  final int weeklyGoal;
  final double currentWeeklyHours;
  final int warScore;
  final String? enemySquadId;

  const SquadEntity({
    required this.id,
    required this.name,
    required this.memberIds,
    this.squadXp = 0,
    this.weeklyGoal = 40,
    this.currentWeeklyHours = 0.0,
    this.warScore = 0,
    this.enemySquadId,
  });

  SquadEntity copyWith({
    String? id,
    String? name,
    List<String>? memberIds,
    int? squadXp,
    int? weeklyGoal,
    double? currentWeeklyHours,
    int? warScore,
    String? enemySquadId,
  }) {
    return SquadEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      memberIds: memberIds ?? this.memberIds,
      squadXp: squadXp ?? this.squadXp,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      currentWeeklyHours: currentWeeklyHours ?? this.currentWeeklyHours,
      warScore: warScore ?? this.warScore,
      enemySquadId: enemySquadId ?? this.enemySquadId,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'memberIds': memberIds,
      'squadXp': squadXp,
      'weeklyGoal': weeklyGoal,
      'currentWeeklyHours': currentWeeklyHours,
      'warScore': warScore,
      'enemySquadId': enemySquadId,
    };
  }

  factory SquadEntity.fromMap(Map<String, dynamic> map) {
    return SquadEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      memberIds: List<String>.from(map['memberIds']),
      squadXp: map['squadXp'] as int? ?? 0,
      weeklyGoal: map['weeklyGoal'] as int? ?? 40,
      currentWeeklyHours: (map['currentWeeklyHours'] as num?)?.toDouble() ?? 0.0,
      warScore: map['warScore'] as int? ?? 0,
      enemySquadId: map['enemySquadId'] as String?,
    );
  }
}
