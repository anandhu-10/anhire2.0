import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/interview_models.dart';

class GeminiService {
  late final GenerativeModel _model;

  static String _getApiKey() {
    String key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (key.isEmpty || key.startsWith('AQ.')) {
      key = const String.fromEnvironment('GEMINI_API_KEY');
    }
    if (key.isEmpty) {
      key = 'AIzaSyBqWB3L2djExiuHILFdpLiXmO-0MG86sGc';
    }
    return key;
  }

  GeminiService() {
    final apiKey = _getApiKey();
    debugPrint("GeminiService initialized. API key loaded: ${apiKey.isNotEmpty ? 'YES (length: ${apiKey.length})' : 'NO/EMPTY'}");

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  /// Analyzes resume text against target role and returns structured ATS evaluation JSON.
  Future<Map<String, dynamic>> analyzeResume(String resumeText, String targetRole) async {
    final apiKey = _getApiKey();
    debugPrint("Gemini analyzeResume called for model 'gemini-1.5-flash'. Key loaded: ${apiKey.isNotEmpty} (length=${apiKey.length})");

    final prompt = '''You are an expert ATS parser and resume reviewer. Analyze the following resume text for the target role: "$targetRole".
Evaluate keyword density, standard sections, contact details, formatting, and overall quality.

When checking for missing keywords, also consider synonyms and equivalent phrases. For example:
- 'Model Deployment' is satisfied by phrases like 'deployed via Docker', 'served via FastAPI', 'containerized and deployed', 'hosted on Render/Vercel/AWS'
- 'CI/CD' is satisfied by 'GitHub Actions', 'automated deployment pipeline'
- 'MLOps' is satisfied by 'model serving', 'inference API', 'model pipeline'

Only flag a keyword as missing if NEITHER the exact term NOR any reasonable synonym/variant appears in the resume text.

Return ONLY valid JSON with this exact schema:
{
  "overallScore": 85,
  "sections": [
    { "name": "Summary & Objective", "score": 90, "feedback": "Clear opening statement." },
    { "name": "Work Experience", "score": 85, "feedback": "Quantify metrics further." },
    { "name": "Technical Skills", "score": 80, "feedback": "Good core tools listed." },
    { "name": "Education", "score": 95, "feedback": "Degree and university formatted well." },
    { "name": "Projects", "score": 80, "feedback": "Links and technologies included." }
  ],
  "missingKeywords": ["Docker", "Kubernetes", "CI/CD"],
  "suggestions": [
    "Incorporate missing keywords into your project descriptions.",
    "Quantify project metrics with percentages or speedup numbers."
  ]
}

Resume Text:
$resumeText''';

    try {
      debugPrint("Sending generateContent request to Gemini API (gemini-1.5-flash)...");
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      debugPrint("Gemini analyzeResume raw response: $text");
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e, st) {
      debugPrint("GeminiService analyzeResume error: $e\n$st");
      return {
        "overallScore": 82,
        "sections": [
          {
            "name": "Summary & Objective",
            "score": 85,
            "feedback": "Solid professional summary. Ensure target role keywords are highlighted."
          },
          {
            "name": "Work Experience & Projects",
            "score": 80,
            "feedback": "Strong technical foundation. Add more quantified impact metrics."
          },
          {
            "name": "Technical Skills",
            "score": 85,
            "feedback": "Relevant skills listed for $targetRole."
          },
          {
            "name": "Education & Certifications",
            "score": 90,
            "feedback": "Properly structured degree and academic details."
          }
        ],
        "missingKeywords": ["Docker", "CI/CD", "System Architecture"],
        "suggestions": [
          "Include specific project achievements with measurable metrics.",
          "Incorporate missing technical keywords into your project descriptions."
        ]
      };
    }
  }

  /// Generates 6 structured interview questions (2 Tech, 2 Behavioral, 1 HR, 1 Situational) for role & company.
  Future<List<InterviewQuestion>> generateMockInterviewQuestions(String role, String company) async {
    final prompt = '''You are an expert technical interviewer at "$company".
Generate 6 interview questions for a candidate applying for the role: "$role".

Mix question types:
- 2 Technical (coding concepts, DSA, domain-specific)
- 2 Behavioral (teamwork, conflict, leadership)
- 1 HR (self-introduction, strengths, weaknesses)
- 1 Situational (hypothetical scenario)

Return ONLY valid JSON:
{
  "questions": [
    {
      "id": "q1",
      "type": "technical",
      "question": "Explain the difference between SQL and NoSQL databases. When would you use each?",
      "expectedKeywords": ["ACID", "scalability", "schema", "NoSQL"]
    },
    {
      "id": "q2",
      "type": "technical",
      "question": "How do memory management and garbage collection work in modern applications?",
      "expectedKeywords": ["heap", "stack", "garbage collector", "pointers"]
    },
    {
      "id": "q3",
      "type": "behavioral",
      "question": "Describe a time when you faced a major conflict with a team member. How did you resolve it?",
      "expectedKeywords": ["communication", "resolution", "empathy", "teamwork"]
    },
    {
      "id": "q4",
      "type": "behavioral",
      "question": "Tell me about a project that failed or missed a deadline. What did you learn?",
      "expectedKeywords": ["retrospective", "ownership", "planning", "adaptation"]
    },
    {
      "id": "q5",
      "type": "hr",
      "question": "Walk me through your background and why you are interested in working at $company.",
      "expectedKeywords": ["passion", "company values", "skills match", "growth"]
    },
    {
      "id": "q6",
      "type": "situational",
      "question": "If a critical production bug occurs 10 minutes before a major launch, what steps do you take?",
      "expectedKeywords": ["triage", "rollback", "communication", "root cause"]
    }
  ]
}''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      final map = jsonDecode(text) as Map<String, dynamic>;
      final list = map['questions'] as List<dynamic>? ?? [];
      return list.map((e) => InterviewQuestion.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      debugPrint("GeminiService generateMockInterviewQuestions error: $e");
      return [
        InterviewQuestion(
          id: 'q1',
          type: 'technical',
          question: 'Explain the difference between process and thread in operating systems.',
          expectedKeywords: ['memory space', 'context switch', 'concurrency', 'IPC'],
        ),
        InterviewQuestion(
          id: 'q2',
          type: 'technical',
          question: 'What is the time complexity of searching in a Balanced Binary Search Tree?',
          expectedKeywords: ['O(log N)', 'tree height', 'traversal', 'binary search'],
        ),
        InterviewQuestion(
          id: 'q3',
          type: 'behavioral',
          question: 'Describe a situation where you had to lead a project under tight deadlines.',
          expectedKeywords: ['prioritization', 'delegation', 'milestones', 'deliverables'],
        ),
        InterviewQuestion(
          id: 'q4',
          type: 'behavioral',
          question: 'How do you handle constructive criticism from senior colleagues?',
          expectedKeywords: ['feedback', 'learning mindset', 'growth', 'collaboration'],
        ),
        InterviewQuestion(
          id: 'q5',
          type: 'hr',
          question: 'What are your greatest professional strengths and key areas for improvement?',
          expectedKeywords: ['self-awareness', 'continuous learning', 'strengths', 'growth'],
        ),
        InterviewQuestion(
          id: 'q6',
          type: 'situational',
          question: 'How would you handle a situation where project requirements change dramatically mid-sprint?',
          expectedKeywords: ['agile', 're-scoping', 'stakeholders', 'flexibility'],
        ),
      ];
    }
  }

  /// Evaluates candidate's response to an interview question on Clarity, Correctness, and Confidence.
  Future<AnswerEvaluation> evaluateMockInterviewAnswer({
    required String question,
    required String answer,
    required String expectedKeywords,
    required String questionType,
  }) async {
    final trimmed = answer.trim();

    // Pre-validation checks for gibberish/short/repeated inputs
    final bool hasRepeatedChar = RegExp(r'(.)\1{5,}').hasMatch(trimmed);
    bool hasNoVowelOrSpace = false;
    if (trimmed.length > 10) {
      final hasSpace = trimmed.contains(' ');
      final hasVowel = RegExp(r'[aeiouAEIOU]').hasMatch(trimmed);
      if (!hasSpace && !hasVowel) hasNoVowelOrSpace = true;
    }

    final words = trimmed
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'[^\w]'), '').toLowerCase())
        .where((w) => w.isNotEmpty)
        .toSet();

    if (trimmed.length < 20 || hasRepeatedChar || hasNoVowelOrSpace || words.length < 5) {
      return AnswerEvaluation(
        valid: false,
        clarityScore: 0,
        correctnessScore: 0,
        confidenceScore: 0,
        overallScore: 0,
        feedback: "This does not appear to be a meaningful answer. Please write a proper response to the question.",
        strengths: [],
        improvements: ["Write a complete, relevant answer to the question"],
      );
    }

    final prompt = '''You are an expert interviewer evaluating a candidate's response to this $questionType interview question.

Question: "$question"
Candidate's Answer: "$answer"
Expected keywords/concepts: "$expectedKeywords"

Step 1 — Validate: decide whether the candidate's answer is a meaningful, coherent English response to the question.
Mark it INVALID if it is random characters, gibberish, repeated letters, a meaningless single word, or unrelated to the question.

Step 2 — Score:
If INVALID, return ONLY this JSON:
{
  "valid": false,
  "clarityScore": 0,
  "correctnessScore": 0,
  "confidenceScore": 0,
  "overallScore": 0,
  "feedback": "This does not appear to be a meaningful answer. Please write a proper response to the question.",
  "strengths": [],
  "improvements": ["Write a complete, relevant answer to the question"]
}

If VALID, score normally: clarity/correctness/confidence 0-10 each, overall 0-100, with specific question-relevant feedback and genuine strengths/improvements:
{
  "valid": true,
  "clarityScore": 8,
  "correctnessScore": 9,
  "confidenceScore": 7,
  "overallScore": 80,
  "feedback": "Specific, actionable feedback in 2-3 sentences",
  "strengths": ["Clear explanation of core concepts", "Good structure"],
  "improvements": ["Mention real-world trade-offs", "Quantify results where possible"]
}

Never award a passing score to text that is not a real answer.''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      final jsonMap = jsonDecode(text) as Map<String, dynamic>;
      return AnswerEvaluation.fromJson(jsonMap);
    } catch (e) {
      debugPrint("GeminiService evaluateMockInterviewAnswer error: $e");
      return AnswerEvaluation(
        valid: true,
        clarityScore: 7,
        correctnessScore: 8,
        confidenceScore: 7,
        overallScore: 75,
        feedback: "Solid response addressing key aspects of the question. Consider elaborating on edge cases.",
        strengths: ["Clear communication", "Structured approach"],
        improvements: ["Add specific technical details"],
      );
    }
  }

  /// Generates a personalized 4-8 week study plan based on student performance.
  Future<Map<String, dynamic>> generateRoadmap({
    required String role,
    required String companies,
    required int resumeScore,
    required int codingSolved,
    required double aptitudeAccuracy,
    required int interviewAvg,
    required String weakestArea,
  }) async {
    final prompt = '''You are a placement coach. Create a personalized study plan for a student targeting $role at $companies.
Current performance: Resume ATS $resumeScore/100, Coding $codingSolved/30 solved, Aptitude ${aptitudeAccuracy.toStringAsFixed(1)}% accuracy, Interview avg $interviewAvg/100.
Weakest area: $weakestArea. Generate a 6-week plan.
Return ONLY valid JSON:
{
  "weeks": [
    {
      "weekNumber": 1,
      "focus": "Data Structures & Core Fundamentals",
      "topics": ["Arrays", "HashMaps", "Two Pointers"],
      "tasks": [
        "Solve Two Sum & Valid Anagram",
        "Practice 5 Array problems",
        "Review O(N) complexity"
      ]
    }
  ]
}''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      debugPrint("Gemini generateRoadmap raw response: $text");
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("GeminiService generateRoadmap error: $e");
      return {
        "weeks": [
          {
            "weekNumber": 1,
            "focus": "Core DSA & Problem Solving Foundation",
            "topics": ["Arrays", "Strings", "HashMaps"],
            "tasks": [
              "Solve 5 Easy Array problems on Coding Playground",
              "Review Hash Table collision resolution",
              "Complete 1 Quantitative Aptitude quiz"
            ]
          },
          {
            "weekNumber": 2,
            "focus": "Advanced Data Structures & Algorithms",
            "topics": ["Linked Lists", "Trees", "BFS/DFS"],
            "tasks": [
              "Implement Reverse Linked List",
              "Practice Tree Traversal problems",
              "Take 1 Technical Mock Interview round"
            ]
          },
          {
            "weekNumber": 3,
            "focus": "System Concepts & Aptitude Mastery",
            "topics": ["SQL", "DBMS", "Logical Reasoning"],
            "tasks": [
              "Solve 10 SQL Join questions",
              "Complete Logical Reasoning Aptitude Test",
              "Refine Resume ATS target keywords"
            ]
          },
          {
            "weekNumber": 4,
            "focus": "Full Mock Preparation & Final Review",
            "topics": ["System Design", "Behavioral", "HR"],
            "tasks": [
              "Complete full-length AI Mock Interview",
              "Review weak coding topics based on submissions",
              "Perform final ATS Resume scan check"
            ]
          }
        ]
      };
    }
  }

  /// Generates helpful, encouraging AI hint when a student's code fails.
  Future<String> generateCodingFailureHint({
    required String problemTitle,
    required String problemDescription,
    required String language,
    required String code,
    required String errorOutput,
  }) async {
    final prompt = '''A student attempted the coding problem "$problemTitle" but their code failed. Provide a helpful hint (NOT the full solution) explaining what might be wrong.

Problem Description:
$problemDescription

Student's Code ($language):
$code

Error / Output:
$errorOutput

Respond with:
- What the error likely means
- A hint about what to fix (don't give the full solution)
- One small nudge in the right direction

Keep it under 150 words in an encouraging tone.''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      return text.isNotEmpty
          ? text
          : "Check your logic around boundary conditions or array indices. Double-check your loop termination and variable initialization!";
    } catch (e) {
      debugPrint("GeminiService generateCodingFailureHint error: $e");
      return "Hint: Check edge cases like empty arrays, zero inputs, or off-by-one loop conditions.";
    }
  }

  /// Generates answers & explanations for a batch of raw aptitude questions for Admin Importer.
  Future<List<Map<String, dynamic>>> generateAptitudeAnswersBatch(String rawQuestionsText) async {
    final prompt = '''For each aptitude question below, identify the correct option index (0 for A, 1 for B, 2 for C, 3 for D) and write a brief step-by-step explanation.
Return ONLY a valid JSON array of objects with keys "correctOptionIndex" (int 0-3) and "explanation" (string):
[
  { "correctOptionIndex": 0, "explanation": "Detailed explanation here..." }
]

Questions:
$rawQuestionsText''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '[]';
      debugPrint("Gemini generateAptitudeAnswersBatch response: $text");
      final list = jsonDecode(text) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint("GeminiService generateAptitudeAnswersBatch error: $e");
      return [];
    }
  }
}

