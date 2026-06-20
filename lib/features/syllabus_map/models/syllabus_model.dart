class SyllabusSubject {
  final String id;
  final String subject;
  final List<SyllabusTopic> topics;

  SyllabusSubject({
    required this.id,
    required this.subject,
    required this.topics,
  });

  factory SyllabusSubject.fromFirestore(String id, Map<String, dynamic> data) {
    return SyllabusSubject(
      id: id,
      subject: data['subject'] ?? 'Unknown',
      topics: (data['topics'] as List<dynamic>?)
              ?.map((t) => SyllabusTopic.fromMap(t))
              .toList() ??
          [],
    );
  }
}

class SyllabusTopic {
  final String title;
  final bool isCompleted;

  SyllabusTopic({
    required this.title,
    required this.isCompleted,
  });

  factory SyllabusTopic.fromMap(Map<String, dynamic> map) {
    return SyllabusTopic(
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }
  
  // Helper to create a copy with new status
  SyllabusTopic copyWith({bool? isCompleted}) {
    return SyllabusTopic(
      title: title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
