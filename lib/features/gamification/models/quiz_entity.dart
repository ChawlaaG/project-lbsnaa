class QuizEntity {
  final String id; // usually topicId
  final String title;
  final List<QuestionEntity> questions;

  const QuizEntity({
    required this.id,
    required this.title,
    required this.questions,
  });

  factory QuizEntity.fromMap(Map<String, dynamic> map, String id) {
    return QuizEntity(
      id: id,
      title: map['title'] ?? '',
      questions: (map['questions'] as List<dynamic>?)
              ?.map((x) => QuestionEntity.fromMap(x))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'questions': questions.map((x) => x.toMap()).toList(),
    };
  }

  /// Diagnostic Fallback: Loading 5 default sample questions to ensure quiz always starts.
  factory QuizEntity.sample() {
    return QuizEntity(
      id: 'diagnostic_sample',
      title: 'DIAGNOSTIC SAMPLE',
      questions: [
        const QuestionEntity(
          questionText: 'Who was the first President of India?',
          options: ['Dr. Rajendra Prasad', 'Dr. S Radhakrishnan', 'Zakir Hussain', 'V.V. Giri'],
          correctOptionIndex: 0,
          explanation: 'Dr. Rajendra Prasad was the first President of India, serving from 1950 to 1962.',
        ),
        const QuestionEntity(
          questionText: 'Which planet is known as the Red Planet?',
          options: ['Venus', 'Mars', 'Jupiter', 'Saturn'],
          correctOptionIndex: 1,
          explanation: 'Mars is known as the Red Planet due to iron oxide (rust) on its surface.',
        ),
        const QuestionEntity(
          questionText: 'What is the capital of France?',
          options: ['Berlin', 'Madrid', 'Paris', 'Rome'],
          correctOptionIndex: 2,
          explanation: 'Paris is the capital and most populous city of France.',
        ),
        const QuestionEntity(
          questionText: 'Which element has the chemical symbol "O"?',
          options: ['Osmium', 'Oxygen', 'Gold', 'Silver'],
          correctOptionIndex: 1,
          explanation: 'Oxygen is a chemical element with symbol O and atomic number 8.',
        ),
        const QuestionEntity(
          questionText: 'Who wrote "Wings of Fire"?',
          options: ['Chetan Bhagat', 'A.P.J. Abdul Kalam', 'Vikram Seth', 'Arundhati Roy'],
          correctOptionIndex: 1,
          explanation: '"Wings of Fire" is an autobiography of A.P.J. Abdul Kalam, former President of India.',
        ),
      ],
    );
  }
}


class QuestionEntity {
  final String questionText; // Fallback or full text
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  
  // Phase 47: Operation Typesetter Fields
  final String? type; // 'statement_analysis' or 'simple_mcq'
  final String? stem;
  final List<String>? statements;
  final String? ask;

  const QuestionEntity({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    this.type,
    this.stem,
    this.statements,
    this.ask,
  });

  factory QuestionEntity.fromMap(Map<String, dynamic> map) {
    return QuestionEntity(
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctOptionIndex: map['correctOptionIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
      type: map['type'],
      stem: map['stem'],
      statements: (map['statements'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      ask: map['ask'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      if (type != null) 'type': type,
      if (stem != null) 'stem': stem,
      if (statements != null) 'statements': statements,
      if (ask != null) 'ask': ask,
    };
  }
}
