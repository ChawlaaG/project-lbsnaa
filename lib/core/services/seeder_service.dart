import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SeederService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedSyllabus() async {
    // Safety: only run seeding when explicitly allowed via env var.
    if (dotenv.env['ALLOW_SEEDING'] != 'true') {
      debugPrint('Seeding blocked: ALLOW_SEEDING not enabled.');
      return;
    }

    // Check if new data exists (check for IN-UT)
    final checkDoc = await _firestore.collection('syllabus').doc('IN-UT').get();
    if (checkDoc.exists) {
      debugPrint('Syllabus (Phase 9) already seeded. Skipping.');
      return;
    }

    debugPrint('Seeding Syllabus Data (Phase 9)...');

    // 1. Uttarakhand (Foundation) - IN-UT
    await _firestore.collection('syllabus').doc('IN-UT').set({
      'subject': 'Foundation',
      'topics': [
        {'title': 'LBSNAA Basics', 'isCompleted': false},
        {'title': 'Ethics & Integrity', 'isCompleted': false},
        {'title': 'Officer Qualities', 'isCompleted': false},
      ],
    });

    // 2. Bihar (History) - IN-BR (Was North)
    await _firestore.collection('syllabus').doc('IN-BR').set({
      'subject': 'History',
      'topics': [
        {'title': 'Indus Valley Civilization', 'isCompleted': false},
        {'title': 'Vedic Age', 'isCompleted': false},
        {'title': 'Mauryan Empire', 'isCompleted': false},
        {'title': 'Gupta Period', 'isCompleted': false},
        {'title': 'Delhi Sultanate', 'isCompleted': false},
        {'title': 'Mughal Empire', 'isCompleted': false},
        {'title': 'British Conquest', 'isCompleted': false},
        {'title': '1857 Revolt', 'isCompleted': false},
        {'title': 'Freedom Struggle', 'isCompleted': false},
        {'title': 'Partition of India', 'isCompleted': false},
      ],
    });

    // 3. Maharashtra (Economy) - IN-MH (Was West)
    await _firestore.collection('syllabus').doc('IN-MH').set({
      'subject': 'Economy',
      'topics': [
        {'title': 'GDP & GNP', 'isCompleted': false},
        {'title': 'Inflation & CPI', 'isCompleted': false},
        {'title': 'Monetary Policy (RBI)', 'isCompleted': false},
        {'title': 'Fiscal Policy', 'isCompleted': false},
        {'title': 'Banking Sector', 'isCompleted': false},
        {'title': 'Share Market Basics', 'isCompleted': false},
        {'title': 'Budgeting', 'isCompleted': false},
      ],
    });

    // 4. Delhi (Polity) - IN-DL (Was Central)
    await _firestore.collection('syllabus').doc('IN-DL').set({
      'subject': 'Polity',
      'topics': [
        {'title': 'Preamble', 'isCompleted': false},
        {'title': 'Fundamental Rights', 'isCompleted': false},
        {'title': 'DPSP', 'isCompleted': false},
        {'title': 'Parliament', 'isCompleted': false},
        {'title': 'President & Governor', 'isCompleted': false},
        {'title': 'Supreme Court', 'isCompleted': false},
        {'title': 'Panchayati Raj', 'isCompleted': false},
      ],
    });

    // 5. Kerala (Environment) - IN-KL (Was NorthEast)
    await _firestore.collection('syllabus').doc('IN-KL').set({
      'subject': 'Environment',
      'topics': [
        {'title': 'Ecosystem Basics', 'isCompleted': false},
        {'title': 'Biodiversity', 'isCompleted': false},
        {'title': 'Climate Change', 'isCompleted': false},
        {'title': 'National Parks', 'isCompleted': false},
      ],
    });

    debugPrint('Syllabus Seeding Complete!');
  }

  Future<void> seedQuestions() async {
    // Safety: only run seeding when explicitly allowed via env var.
    if (dotenv.env['ALLOW_SEEDING'] != 'true') {
      debugPrint('Seeding blocked: ALLOW_SEEDING not enabled.');
      return;
    }

    // Check if questions exist
    final snapshot = await _firestore.collection('questions').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      debugPrint('Questions already seeded. Skipping.');
      return;
    }

    debugPrint('Seeding Questions...');

    final questions = [
      // History
      {
        'subject': 'History',
        'question':
            'Which Article deals with the "Right to Constitutional Remedies"?',
        'options': ['Article 21', 'Article 32', 'Article 14', 'Article 19'],
        'answer': 1,
      },
      {
        'subject': 'History',
        'question': 'Who was the first Governor-General of Bengal?',
        'options': [
          'Lord Clive',
          'Warren Hastings',
          'Lord Cornwallis',
          'Lord Dalhousie',
        ],
        'answer': 1,
      },
      {
        'subject': 'History',
        'question':
            'The "Sadar Diwani Adalat" was established by during the British East India Company rule by?',
        'options': ['Warren Hastings', 'Cornwallis', 'Wellesley', 'Dalhousie'],
        'answer': 0,
      },
      // Economy
      {
        'subject': 'Economy',
        'question': 'Which 5 Year Plan focused on "Growth with Stability"?',
        'options': ['4th Plan', '5th Plan', '8th Plan', '9th Plan'],
        'answer': 0,
      },
      {
        'subject': 'Economy',
        'question': 'Structure of RBI includes how many Deputy Governors?',
        'options': ['Two', 'Three', 'Four', 'Five'],
        'answer': 2,
      },
      // Polity
      {
        'subject': 'Polity',
        'question':
            'The concept of "Directive Principles of State Policy" was borrowed from?',
        'options': ['USA', 'Canada', 'Ireland', 'USSR'],
        'answer': 2,
      },
      {
        'subject': 'Polity',
        'question': 'Who is the guardian of the Constitution of India?',
        'options': [
          'The President',
          'The Prime Minister',
          'The Supreme Court',
          'The Parliament',
        ],
        'answer': 2,
      },
      {
        'subject': 'Polity',
        'question':
            'Which schedule of Indian Constitution deals with languages?',
        'options': [
          '7th Schedule',
          '8th Schedule',
          '9th Schedule',
          '10th Schedule',
        ],
        'answer': 1,
      },
      // Environment
      {
        'subject': 'Environment',
        'question': 'Which gas is known as "Greenhouse Gas"?',
        'options': ['Oxygen', 'Nitrogen', 'Carbon Dioxide', 'Hydrogen'],
        'answer': 2,
      },
      {
        'subject': 'Environment',
        'question': 'The "Silent Valley" National Park is located in?',
        'options': ['Karnataka', 'Tamil Nadu', 'Kerala', 'Andhra Pradesh'],
        'answer': 2,
      },
    ];

    final batch = _firestore.batch();
    for (var q in questions) {
      final docRef = _firestore.collection('questions').doc();
      batch.set(docRef, q);
    }
    await batch.commit();

    debugPrint('Questions Seeding Complete!');
  }

  Future<void> seedQuizzes() async {
    // Safety: only run seeding when explicitly allowed via env var.
    if (dotenv.env['ALLOW_SEEDING'] != 'true') {
      debugPrint('Seeding blocked: ALLOW_SEEDING not enabled.');
      return;
    }

    final checkDoc = await _firestore
        .collection('quizzes')
        .doc('Preamble')
        .get();
    if (checkDoc.exists) {
      debugPrint('Quizzes already seeded. Skipping.');
      return;
    }

    debugPrint('Seeding Quizzes (Phase 17)...');

    // Quiz for "Preamble"
    final quiz = {
      'title': 'Preamble & Basics',
      'questions': [
        {
          'questionText':
              'Which Amendment added the words "Socialist, Secular" to the Preamble?',
          'options': [
            '42nd Amendment',
            '44th Amendment',
            '1st Amendment',
            '86th Amendment',
          ],
          'correctOptionIndex': 0,
          'explanation':
              'The 42nd Amendment (1976) added Socialist, Secular, and Integrity.',
        },
        {
          'questionText': 'The Preamble is based on which document?',
          'options': [
            'Objective Resolution',
            'Government of India Act 1935',
            'Magna Carta',
            'Irish Constitution',
          ],
          'correctOptionIndex': 0,
          'explanation':
              'It is based on the Objective Resolution moved by Jawaharlal Nehru in 1946.',
        },
        {
          'questionText':
              'Which Article is known as the "Heart and Soul" of the Constitution?',
          'options': ['Article 14', 'Article 19', 'Article 21', 'Article 32'],
          'correctOptionIndex': 3,
          'explanation':
              'Dr. Ambedkar called Article 32 (Right to Constitutional Remedies) the Heart and Soul.',
        },
      ],
    };

    await _firestore.collection('quizzes').doc('Preamble').set(quiz);
    debugPrint('Quizzes Seeding Complete!');
  }

  Future<void> seedSyllabusQueue() async {
    // Safety: only run seeding when explicitly allowed via env var.
    if (dotenv.env['ALLOW_SEEDING'] != 'true') {
      debugPrint('Seeding blocked: ALLOW_SEEDING not enabled.');
      return;
    }

    final checkDoc = await _firestore
        .collection('syllabus_queue')
        .limit(1)
        .get();
    if (checkDoc.docs.isNotEmpty) {
      debugPrint('Syllabus Queue already populated. Skipping.');
      return;
    }

    debugPrint('Seeding Syllabus Queue (Harvester V1)...');

    // Fetch all syllabus regions
    final snapshot = await _firestore.collection('syllabus').get();

    final batch = _firestore.batch();
    int count = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final String subject = data['subject'] ?? 'General Studies';
      final String stateName = (data['subject'] as String)
          .split(':')
          .first
          .trim(); // "Kerala" from "Kerala: Environment"
      final List<dynamic> topics = data['topics'] ?? [];

      for (var topic in topics) {
        final title = topic['title'];
        final docRef = _firestore.collection('syllabus_queue').doc();

        batch.set(docRef, {
          'topicId': title, // Use title as ID for generation
          'subject': subject,
          'stateName': stateName,
          'status': 'pending',
          'priority': 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
        count++;
      }
    }

    await batch.commit();
    debugPrint('Syllabus Queue Seeding Complete! Added $count tasks.');
  }
}
