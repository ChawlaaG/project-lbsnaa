class UserEntity {
  final String uid;
  final String? name; // Added for Chat/UI
  final int currentLevel;
  final int xpPoints;
  final int currentStreak;
  final int totalQuizzesTaken; // New: Total Missions
  final List<String> territoryUnlocked;
  final String? squadId;
  final String? avatarUrl;
  final String? bio; // New: User motto/bio
  final String? targetYear; // New: Target Exam Year (e.g., "2026")
  final String difficultyLevel; // New: Cadet, Officer, Commander
  final String? lastActiveDate; // YYYY-MM-DD format for streak tracking
  final bool isPremium; // Indicates if user has unlocked premium features

  const UserEntity({
    required this.uid,
    this.name,
    this.currentLevel = 1,
    this.xpPoints = 0,
    this.currentStreak = 0,
    this.totalQuizzesTaken = 0,
    this.territoryUnlocked = const [],
    this.squadId,
    this.avatarUrl,
    this.bio,
    this.targetYear,
    this.difficultyLevel = 'Officer',
    this.lastActiveDate,
    this.isPremium = false,
  });

  String get rank {
    if (xpPoints < 1000) return "CADET";
    if (xpPoints < 3000) return "OFFICER";
    if (xpPoints < 6000) return "COMMANDER";
    if (xpPoints < 10000) return "STRATEGIST";
    return "GRANDMASTER";
  }

  UserEntity copyWith({
    String? uid,
    String? name,
    int? currentLevel,
    int? xpPoints,
    int? currentStreak,
    int? totalQuizzesTaken,
    List<String>? territoryUnlocked,
    String? squadId,
    String? avatarUrl,
    String? bio,
    String? targetYear,
    String? difficultyLevel,
    String? lastActiveDate,
    bool? isPremium,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      currentLevel: currentLevel ?? this.currentLevel,
      xpPoints: xpPoints ?? this.xpPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      totalQuizzesTaken: totalQuizzesTaken ?? this.totalQuizzesTaken,
      territoryUnlocked: territoryUnlocked ?? this.territoryUnlocked,
      squadId: squadId ?? this.squadId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      targetYear: targetYear ?? this.targetYear,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  // Placeholder for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'currentLevel': currentLevel,
      'xpPoints': xpPoints,
      'currentStreak': currentStreak,
      'totalQuizzesTaken': totalQuizzesTaken,
      'territoryUnlocked': territoryUnlocked,
      'squadId': squadId,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'targetYear': targetYear,
      'difficultyLevel': difficultyLevel,
      'lastActiveDate': lastActiveDate,
      'isPremium': isPremium,
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      uid: map['uid'] as String? ?? 'unknown',
      name: map['name'] as String?,
      currentLevel: (map['currentLevel'] as num?)?.toInt() ?? 1,
      xpPoints: (map['xpPoints'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      totalQuizzesTaken: (map['totalQuizzesTaken'] as num?)?.toInt() ?? 0,
      territoryUnlocked: List<String>.from(map['territoryUnlocked'] ?? []),
      squadId: map['squadId'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      bio: map['bio'] as String?,
      targetYear: map['targetYear'] as String?,
      difficultyLevel: map['difficultyLevel'] as String? ?? 'Officer',
      lastActiveDate: map['lastActiveDate'] as String?,
      isPremium: map['isPremium'] as bool? ?? false,
    );
  }
}
