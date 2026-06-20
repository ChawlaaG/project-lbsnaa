import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../gamification/models/quiz_entity.dart';
import '../../../core/services/offline_mode_service.dart';
import '../../../features/offline/services/offline_pack_service.dart';
import 'package:cadre_upsc/core/services/guardrail_service.dart';

class GeminiContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Using Groq API Key
  final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  static const String _modelName = 'llama-3.3-70b-versatile';

  GeminiContentService() {}

  Future<String?> _callGroq(String prompt) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _modelName,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an advanced AI simulating UPSC exams. Respond primarily with standard structured JSON as requested.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    } else {
      debugPrint("GROQ API ERROR: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

  Future<QuizEntity> generateQuizForTopic(
    String topicId,
    String subject,
    String stateName, {
    String difficulty = 'Officer',
  }) async {
    // 1. Guardrail Check
    if (!await GuardrailService().canGenerateContent()) {
      debugPrint("🚫 GEMINI: Guardrail Blocked Request.");
      // Return Fallback immediately
      return _generateFallbackQuiz(topicId, subject, stateName);
    }

    debugPrint(
      "🚀 CONNECTING TO AI: $_modelName for $stateName (Level: $difficulty)",
    );

    // Bank-first strategy: prefer archived questions unless overridden by env.
    // Set PREFER_AI=true in .env to force AI generation even if bank has results.
    final bool preferAI = dotenv.env['PREFER_AI'] == 'true';
    if (!preferAI) {
      try {
        final bankedQuiz = await _fetchFromBank(topicId, subject, stateName);
        if (bankedQuiz != null) {
          debugPrint("🏦 BANNER: Served from Global Question Bank!");
          return bankedQuiz;
        }
      } catch (e) {
        debugPrint("🏦 BANK FETCH ERROR (continuing to AI): $e");
      }
    }

    // Phase 4: Bunker Mode - Offline Pack Loading
    if (topicId.startsWith('bunker_pack_')) {
      final pack = OfflinePackService().getPack(topicId);
      if (pack != null) {
        debugPrint("📦 BUNKER MODE: Loaded Offline Pack $topicId");
        return pack;
      } else {
        debugPrint("📦 BUNKER MODE: Pack not found!");
        // Fallback?
      }
    }

    // Phase 42: "Tactical" Prompt Tuning & Anti-Generic Constraints
    String prompt = '';

    // Strict Anti-Generic Rules (Active Defense against basic AI output)
    const String antiGenericRules = '''
      CRITICAL NEGATIVE CONSTRAINTS (DO NOT VIOLATE):
      - DO NOT ask simple factual trivia (e.g., "Who wrote...", "What is the capital of...", "When was X established").
      - DO NOT use generic options like "None of the above" or "All of the above" unless part of a complex logical trap.
      - DO NOT write questions that can be answered by eliminating one obviously wrong option.
      - Focus heavily on conceptual depth, constitutional implications, economic impacts, and structural mechanisms.
    ''';

    // Few-Shot Prompting Example (The Gold Standard)
    const String fewShotExample = '''
      EXAMPLE OF DESIRED QUALITY (EMULATE THIS STYLE):
      {
        "type": "statement_analysis",
        "stem": "With reference to the Indian economy, consider the following statements:",
        "statements": [
          "1. 'Commercial Paper' is a short-term unsecured promissory note.",
          "2. 'Certificate of Deposit' is a long-term instrument issued by the RBI.",
          "3. 'Call Money' is short-term finance used for interbank transactions."
        ],
        "ask": "Which of the statements given above is/are correct?",
        "options": ["1 and 2 only", "1 and 3 only", "2 and 3 only", "1, 2 and 3"],
        "correctOptionIndex": 1,
        "explanation": "Statement 1 is correct: Commercial Paper is an unsecured money market instrument. Statement 2 is incorrect: A Certificate of Deposit is a short-term, not long-term, instrument issued by banks, not exclusively the RBI. Statement 3 is correct: Call money is the borrowing or lending of funds for 1 day in the interbank market."
      }
    ''';

    // Difficulty Modifiers & Distractor Rules
    String diffInstruction = "";
    if (difficulty == "Cadet") {
      diffInstruction =
          "Create easier, direct questions. Focus on fundamental concepts. Distractors (wrong options) should be plausible but clearly distinguishable for a beginner.";
    } else if (difficulty == "Commander") {
      diffInstruction =
          "Create VERY DIFFICULT questions. Use multi-statement analysis, assertion-reasoning, and tricky options. Test deep conceptual understanding. Distractors must be highly plausible, based on common misconceptions or closely related (but incorrect) facts. \n\nIMPORTANT: Use 'Consider the following statements' format for at least 80% of questions.";
    } else {
      diffInstruction =
          "Create standard UPSC Prelims level questions. Mix of direct and conceptual. Avoid simple one-liners. Use statement-based questions where appropriate. Distractors should be challenging and logical, not obviously wrong fillers.";
    }

    if (topicId == 'PAPER_I_FULL_MOCK') {
      // ... (Existing Paper I Prompt) ...
      // PHASE 45: PAPER I - MIXED BAG MOCK
      prompt =
          '''
        You are simulating the UPSC PRELIMS PAPER I (General Studies).
        Create 15 Questions. Difficulty Level: $difficulty for Aspirants.
        
        $diffInstruction
        $antiGenericRules

        CRITICAL INSTRUCTION: RANDOMLY MIX THE SUBJECTS.
        Do NOT group them.
        Jump between: History, Polity, Geography, Economy, Environment, Science, and Current Affairs.
        
        Style: Statement-based, Match the following, Assertion-Reasoning. Force UPSC taxonomy (e.g., 'Consider the following', 'Which of the above is/are').
        Keep explanations precise (2-3 detailed sentences max). Detail WHY the correct answer is right AND why the primary distractor is wrong.

        $fewShotExample

        Output STRICT JSON in this exact format:
        {
          "questions": [
            {
              "type": "statement_analysis", 
              "stem": "Consider the following statements regarding...",
              "statements": ["1. Statement 1...", "2. Statement 2..."],
              "ask": "Which of the statements given above is/are correct?",
              "options": ["1 only", "2 only", "Both 1 and 2", "Neither 1 nor 2"],
              "correctOptionIndex": 0,
              "explanation": "..."
            }
          ]
        }
        ''';
    } else if (topicId == 'PAPER_II_CSAT_MOCK' || subject == 'CSAT') {
      // ... (Existing CSAT Prompt) ...
      // PROMPT OVERRIDE: CSAT PROTOCOL
      prompt =
          '''
      You are setting a UPSC CSAT Paper 2 Mock.
      Create 15 Questions. Difficulty: $difficulty.
      
      $diffInstruction
      $antiGenericRules

      Structure:
      - 4 Reading Comprehension (Short Passage + Inference).
      - 3 Logical Reasoning (Blood relations, Series, Syllogism).
      - 3 Basic Numeracy (Time & Work, Ratio, Percentages).
      
      Options must be tricky. Distractors must be plausible common errors in calculation or logic.
      Keep explanations precise (2-3 detailed sentences max). Explain the step-by-step logic concisely.

      Output STRICT JSON in this exact format:
      {
        "questions": [
          {
            "type": "simple_mcq",
            "stem": "A train passes a station...",
            "statements": [],
            "ask": "What is the length of the train?",
            "options": ["100m", "200m", "300m", "400m"],
            "correctOptionIndex": 0,
            "explanation": "..."
          }
        ]
      }
      ''';
    } else if (subject == 'Current Affairs') {
      // ... (Existing Current Affairs Prompt) ...
      // ... existing Current Affairs logic ...
      prompt =
          '''
      You are setting a UPSC Current Affairs Mock for $stateName (India).
      Create 15 MCQs based on events from the LAST 12 MONTHS.
      Difficulty: $difficulty.
      
      $diffInstruction
      $antiGenericRules

      PRIORITY FOCUS:
      1. Schemes/Events specific to $stateName (Government, Economy, Environment).
      2. If $stateName has limited recent national news, fill with significant National Indian Current Affairs.
      
      Focus on: Govt Schemes, Science & Tech, International Relations, Defense.
      Avoid static history. Do not use generic AI phrasing like 'The correct answer is'.

      Keep explanations precise (2-3 detailed sentences max). Explain the context of the current event and why the distractors are incorrect.

      $fewShotExample

      Output STRICT JSON in this exact format:
      {
        "questions": [
          {
            "type": "simple_mcq",
            "stem": "Who is the...",
            "statements": [],
            "ask": "Select the correct option.",
            "options": ["A", "B", "C", "D"],
            "correctOptionIndex": 0,
            "explanation": "..."
          }
        ]
      }
      ''';
    } else {
      // ... (Existing Standard Prompt) ...
      // STANDARD PROTOCOL
      prompt =
          '''
      Create 15 UPSC MCQs on $subject ($stateName).
      Topic: $stateName aka $topicId.
      Difficulty Level: $difficulty.
      
      $diffInstruction
      $antiGenericRules
      
      Focus strictly on Conceptual Clarity and Statement-Analysis (if difficulty is high).
      
      MANDATORY QUALITY CONTROL:
      1. NO repetitive or simple questions. Do not use generic filler distractors (e.g., "None of the above" unless strictly necessary).
      2. Construct 'Match the Following' or 'Chronological Order' questions where applicable.
      3. For 'Officer' and 'Commander' levels, use Statement-Analysis format (1 only, 2 only, Both, None).
      4. Force UPSC taxonomy (e.g., 'Consider the following', 'Which of the above is/are correct?'). No generic AI phrasing.
      
      Keep explanations precise (2-3 detailed sentences max). Detail WHY the correct answer is right AND why the primary distractor is wrong.
      
      $fewShotExample
      
      Output STRICT JSON in this exact format:
      {
        "questions": [
          {
            "type": "statement_analysis",
            "stem": "Consider the following statements regarding [Topic]:",
            "statements": ["1. Statement A...", "2. Statement B..."],
            "ask": "Which of the statements given above is/are correct?",
            "options": ["1 only", "2 only", "Both 1 and 2", "Neither 1 nor 2"],
            "correctOptionIndex": 2,
            "explanation": "Statement 1 is correct because... Statement 2 is correct because..."
          }
        ]
      }
      ''';
    }

    try {
      final responseText = await _callGroq(prompt);

      debugPrint('🤖 AI RESPONSE: $responseText');

      if (responseText == null) throw Exception("Empty response from Groq AI");

      // Verify and Parse JSON
      // Sanitize standard Markdown wrappers and remove any leading/trailing thought blocks or extra text
      String cleanJson = responseText;

      // Remove thought blocks if present (e.g. <thought>...</thought>)
      cleanJson = cleanJson.replaceAll(
        RegExp(r'<thought>.*?</thought>', dotAll: true),
        '',
      );

      // Extract JSON if it's wrapped in markers
      if (cleanJson.contains('```json')) {
        cleanJson = cleanJson.split('```json').last.split('```').first;
      } else if (cleanJson.contains('```')) {
        cleanJson = cleanJson.split('```').last.split('```').first;
      }

      cleanJson = cleanJson.trim();

      final Map<String, dynamic> data = jsonDecode(cleanJson);

      // Basic schema validation for AI response
      if (data['questions'] == null || data['questions'] is! List) {
        throw Exception('Invalid AI response: missing questions array');
      }

      final List<dynamic> questionsList = data['questions'];

      List<QuestionEntity> questions = questionsList.map((q) {
        // Fallback for questionText if using new structure
        String qText = q['questionText'] ?? '';
        if (qText.isEmpty && q['stem'] != null) {
          qText =
              "${q['stem']}\n\n${(q['statements'] as List?)?.join('\n') ?? ''}\n\n${q['ask'] ?? ''}"
                  .trim();
        }

        // Validate required fields per-question
        if (qText.isEmpty) throw Exception('Invalid question: empty text');
        if (q['options'] == null ||
            q['options'] is! List ||
            (q['options'] as List).isEmpty)
          throw Exception('Invalid question: options missing');
        if (q['correctOptionIndex'] == null ||
            (q['correctOptionIndex'] is! int))
          throw Exception('Invalid question: missing correctOptionIndex');
        final opts = List<String>.from(q['options']);
        final cIdx = q['correctOptionIndex'] as int;
        if (cIdx < 0 || cIdx >= opts.length)
          throw Exception('Invalid question: correctOptionIndex out of range');

        return QuestionEntity(
          questionText: qText,
          options: List<String>.from(q['options']),
          correctOptionIndex: q['correctOptionIndex'],
          explanation: q['explanation'],
          type: q['type'],
          stem: q['stem'],
          statements: (q['statements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
          ask: q['ask'],
        );
      }).toList();

      // Phase 46: The Harvester (Save to Bank)
      // Fire and forget to avoid blocking UI
      _harvestQuestions(questions, topicId, subject, stateName);

      // Phase 2: Bunker Mode - Cache Quiz for Offline Access
      try {
        // Wrap in try-catch to ensure cache failure doesn't crash app
        await OfflineModeService().cacheQuiz(
          topicId,
          jsonEncode(
            QuizEntity(
              id: topicId,
              title: "$stateName: $subject (Generated)",
              questions: questions,
            ).toMap(),
          ),
        );
      } catch (e) {
        debugPrint("OFFLINE CACHE FAIL: $e");
      }

      // 2. Record Success (Guardrail)
      await GuardrailService().recordGeneration();

      return QuizEntity(
        id: topicId,
        title: "$stateName: $subject (Generated)",
        questions: questions,
      );
    } catch (e) {
      debugPrint('❌ AI GENERATION FAIL: $e');

      // Phase 2: Bunker Mode - Try Offline Cache First
      try {
        final cachedJson = OfflineModeService().getCachedQuiz(topicId);
        if (cachedJson != null) {
          debugPrint("BUNKER MODE: Serving cached quiz for $topicId");
          final Map<String, dynamic> map = jsonDecode(cachedJson);
          return QuizEntity.fromMap(map, topicId);
        }
      } catch (cacheError) {
        debugPrint("BUNKER MODE FAIL: $cacheError");
      }

      // On failure, return offline fallback
      return _generateFallbackQuiz(topicId, subject, stateName);
    }
  }

  // Phase 46: The Harvester
  Future<void> _harvestQuestions(
    List<QuestionEntity> questions,
    String topicId,
    String subject,
    String stateName,
  ) async {
    try {
      final batch = _firestore.batch();
      int count = 0;

      for (var q in questions) {
        // Check for dupe (simple check, or rely on distinct generated content)
        // For speed, just add with a query check later or just add now.
        // Let's query first to be safe, or generate a hash.
        // For v1, let's just add new docs. Smart fetch handles randomization/dupe avoidance if we pick randoms.

        final docRef = _firestore.collection('global_question_bank').doc();

        batch.set(docRef, {
          'questionText': q.questionText,
          'options': q.options,
          'correctOptionIndex': q.correctOptionIndex,
          'explanation': q.explanation,
          'type': q.type,
          'stem': q.stem,
          'statements': q.statements,
          'ask': q.ask,
          'tags': [subject, stateName, topicId, 'UPSC', 'Hard'],
          'model': _modelName,
          'generatedAt': FieldValue.serverTimestamp(),
          'verified': false,
        });
        count++;
      }

      await batch.commit();
      debugPrint("🌾 HARVESTER: Saved $count questions to Bank.");
    } catch (e) {
      debugPrint("🌾 HARVESTER FAIL: $e");
    }
  }

  // Phase 46: Smart Fetch (with dedup)
  Future<QuizEntity?> _fetchFromBank(
    String topicId,
    String subject,
    String stateName,
  ) async {
    try {
      // Fetch 45 random questions for this subject/state
      final snapshot = await _firestore
          .collection('global_question_bank')
          .where('tags', arrayContains: subject)
          .limit(45) // Fetch more to allow dedup filtering
          .get();

      if (snapshot.docs.length < 15) return null; // Not enough data, use AI

      // Fetch previously answered question hashes for dedup
      Set<String> answeredHashes = {};
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final answeredDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('answered_questions')
              .doc(topicId)
              .get();
          if (answeredDoc.exists) {
            answeredHashes = Set<String>.from(
              answeredDoc.data()?['hashes'] ?? [],
            );
          }
        }
      } catch (_) {}

      // Filter out already-answered questions
      final freshDocs = snapshot.docs.where((doc) {
        final qText = doc.data()['questionText'] ?? '';
        return !answeredHashes.contains(qText.hashCode.toString());
      }).toList();

      // If fewer than 15 fresh questions, use all available (allow some repeats)
      final docsToUse = freshDocs.length >= 15
          ? freshDocs
          : snapshot.docs.toList();
      docsToUse.shuffle(); // Randomize client side

      // Take 15
      final selectedDocs = docsToUse.take(15).toList();

      List<QuestionEntity> questions = selectedDocs.map((doc) {
        final data = doc.data();
        return QuestionEntity(
          questionText: data['questionText'] ?? '',
          options: List<String>.from(data['options']),
          correctOptionIndex: data['correctOptionIndex'],
          explanation: data['explanation'],
          type: data['type'],
          stem: data['stem'],
          statements: (data['statements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
          ask: data['ask'],
        );
      }).toList();

      return QuizEntity(
        id: topicId,
        title: "$stateName: $subject (From Archive)",
        questions: questions,
      );
    } catch (e) {
      debugPrint("🏦 BANK FETCH FAIL: $e");
      return null;
    }
  }

  QuizEntity _generateFallbackQuiz(
    String topicId,
    String subject,
    String stateName,
  ) {
    return QuizEntity(
      id: topicId,
      title: "$stateName: $subject (Offline Simulation)",
      questions: [
        if (subject == 'History') ...[
          QuestionEntity(
            questionText:
                "Which ancient dynasty ruled parts of $stateName during the 4th century?",
            options: ["Gupta", "Maurya", "Chola", "Satavahana"],
            correctOptionIndex: 0,
            explanation:
                "The Gupta Empire had a significant presence in northern and central India.",
          ),
          QuestionEntity(
            questionText:
                "What represents a major historical event in $stateName's freedom struggle?",
            options: [
              "Salt March",
              "Tribal Revolt",
              "Peasant Movement",
              "All of the above",
            ],
            correctOptionIndex: 3,
            explanation:
                "Most Indian states participated in various forms of freedom struggle.",
          ),
        ] else if (subject == 'Polity') ...[
          QuestionEntity(
            questionText:
                "How many seats does $stateName generally send to the Lok Sabha?",
            options: ["10-20", "20-40", "40+", "Depends on population"],
            correctOptionIndex: 3,
            explanation:
                "Lok Sabha seats are allocated based on the population of the state.",
          ),
          QuestionEntity(
            questionText: "Who is the constitutional head of $stateName?",
            options: [
              "Chief Minister",
              "Governor",
              "High Court Chief Justice",
              "Speaker",
            ],
            correctOptionIndex: 1,
            explanation:
                "The Governor is the constitutional head of the state.",
          ),
        ] else if (subject == 'CSAT') ...[
          QuestionEntity(
            questionText:
                "If 15 men can complete a project in 20 days, how many days will 10 men take?",
            options: ["25", "30", "35", "40"],
            correctOptionIndex: 1, // 30
            explanation:
                "M1*D1 = M2*D2. 15*20 = 300 man-days. 300/10 = 30 days.",
          ),
          QuestionEntity(
            questionText: "Complete the series: 2, 6, 12, 20, ?",
            options: ["28", "30", "32", "42"],
            correctOptionIndex: 1, // 30
            explanation: "Pattern: 1*2, 2*3, 3*4, 4*5, so next is 5*6 = 30.",
          ),
        ] else if (subject == 'Current Affairs') ...[
          QuestionEntity(
            questionText:
                "Which country recently hosted the G20 Summit in 2023?",
            options: ["Brazil", "India", "Indonesia", "South Africa"],
            correctOptionIndex: 1,
            explanation:
                "India hosted the G20 Summit in New Delhi in September 2023.",
          ),
          QuestionEntity(
            questionText:
                "What is the primary objective of the PM-Vishwakarma Scheme?",
            options: [
              "Farmers Support",
              "Artisan Support",
              "Student Loans",
              "Digital India",
            ],
            correctOptionIndex: 1,
            explanation:
                "PM-Vishwakarma aims to support traditional artisans and craftspeople.",
          ),
        ] else ...[
          QuestionEntity(
            questionText:
                "Which sector contributes most to $stateName's economy?",
            options: ["Agriculture", "Services", "Manufacturing", "Tourism"],
            correctOptionIndex: 1, // Generic guess
            explanation:
                "The service sector is a dominant part of the Indian economy.",
          ),
        ],
        // Generic Filler
        const QuestionEntity(
          questionText: "What is the capital of India?",
          options: ["Mumbai", "New Delhi", "Kolkata", "Chennai"],
          correctOptionIndex: 1,
          explanation: "New Delhi is the capital of India.",
        ),
      ],
    );
  }

  // Phase 5: War Room - AI Analyst
  Future<String> generateInsights(Map<String, dynamic> stats) async {
    // 1. Guardrail Check
    if (!await GuardrailService().canGenerateContent()) {
      return "Tactical computer limits reached. Try again tomorrow.";
    }

    try {
      final prompt =
          '''
      You are a Senior Strategic Analyst for UPSC Aspirants.
      Analyze the following cadet performance data and provide a TACTICAL DEBRIEF.
      
      DATA:
      ${jsonEncode(stats)}
      
      OUTPUT REQUIREMENTS:
      1. Identify the WEAKEST subject (Critical Vulnerability).
      2. Identify the STRONGEST subject (Stronghold).
      3. Give 3 specific actionable recommendations to improve scores.
      
      TONE: Military, Encouraging, Precise. Max 100 words.
      Format as bullet points.
      ''';

      final responseText = await _callGroq(prompt);

      // 2. Record Success
      await GuardrailService().recordGeneration();

      return responseText ?? "Analysis failed. Re-engage.";
    } catch (e) {
      debugPrint("WAR ROOM AI FAIL: $e");
      return "Tactical computer offline. Maintain current course.";
    }
  }

  // Phase 6: Global Intel - News Analyst
  Future<Map<String, dynamic>> summarizeArticle(
    String title,
    String description,
  ) async {
    // 1. Guardrail Check
    if (!await GuardrailService().canGenerateContent()) {
      return {
        "summary": "• Raw Intelligence: $description",
        "tags": ["General Awareness", "Quota Exceeded"],
      };
    }

    try {
      final prompt =
          '''
      You are an Intelligence Officer for UPSC Aspirants.
      Analyze this news item:
      TITLE: $title
      CONTENT: $description

      OUTPUT JSON format:
      {
        "summary": "3 bullet points summarizing the key facts relevant to UPSC/Civil Services. Max 30 words per bullet.",
        "fullArticle": "A detailed 3-paragraph news report expanding on the facts provided, written in an engaging, authoritative tone suitable for an intelligence briefing. If context is known based on the facts, use it to expand the article. Minimum 150 words.",
        "tags": ["List", "Of", "3", "Relevant", "Syllabus", "Tags"]
      }
      
      Tags should be from: Polity, Economy, International Relations, Science, Environment, Social Issues, History, Geography.
      ''';

      final responseText = await _callGroq(prompt);

      // 2. Record Success
      await GuardrailService().recordGeneration(); // Record Success!

      final text = responseText;
      if (text == null) throw Exception("Empty AI Response");

      final cleanJson = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return jsonDecode(cleanJson);
    } catch (e) {
      debugPrint("NEWS INTEL FAIL: $e");
      // Fallback
      return {
        "summary": "• Raw Intelligence: $description",
        "fullArticle":
            "Connectivity to the intelligence server failed. Raw intelligence received:\n\n$description\n\nPlease check the source link for the full un-truncated details.",
        "tags": ["General Awareness"],
      };
    }
  }
}
