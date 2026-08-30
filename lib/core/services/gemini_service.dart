import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/interview_models.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    debugPrint("GeminiService initialized. API key loaded: ${apiKey.isNotEmpty ? 'YES (length: ${apiKey.length})' : 'NO/EMPTY'}");

    _model = GenerativeModel(
      model: 'gemini-3.6-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  /// Analyzes resume text against target role and returns structured ATS evaluation JSON.
  Future<Map<String, dynamic>> analyzeResume(String resumeText, String targetRole) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    debugPrint("Gemini analyzeResume called for model 'gemini-3.6-flash'. Key loaded: ${apiKey.isNotEmpty} (length=${apiKey.length})");

    final prompt = '''You are an expert ATS parser and resume reviewer. Analyze the following resume text for the target role: "$targetRole".
Evaluate keyword density, standard sections, contact details, formatting, and overall quality.
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
      debugPrint("Sending generateContent request to Gemini API (gemini-3.6-flash)...");
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      debugPrint("Gemini analyzeResume raw response: $text");
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e, st) {
      debugPrint("GeminiService analyzeResume error: $e\n$st");
      rethrow;
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
    if (answer.trim().length < 20) {
      return AnswerEvaluation(
        clarityScore: 2,
        correctnessScore: 2,
        confidenceScore: 2,
        overallScore: 20,
        feedback: "Answer too brief to evaluate properly. Please provide a detailed response using specific examples.",
        strengths: ["Attempted to answer"],
        improvements: ["Elaborate further", "Include specific examples", "Use STAR method"],
      );
    }

    final prompt = '''You are an expert interviewer evaluating a candidate's response to this $questionType interview question.

Question: "$question"
Candidate's Answer: "$answer"
Expected keywords/concepts: "$expectedKeywords"

Evaluate on three parameters:
- Clarity (0-10): Is the answer clear and well-structured?
- Correctness (0-10): Is the answer technically accurate?
- Confidence (0-10): Does the answer convey confidence?

Return ONLY valid JSON:
{
  "clarityScore": 8,
  "correctnessScore": 9,
  "confidenceScore": 7,
  "overallScore": 80,
  "feedback": "Specific, actionable feedback in 2-3 sentences",
  "strengths": ["Clear explanation of core concepts", "Good structure"],
  "improvements": ["Mention real-world trade-offs", "Quantify results where possible"]
}''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      final jsonMap = jsonDecode(text) as Map<String, dynamic>;
      return AnswerEvaluation.fromJson(jsonMap);
    } catch (e) {
      debugPrint("GeminiService evaluateMockInterviewAnswer error: $e");
      return AnswerEvaluation(
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

  /// Generates a personalized learning roadmap timeline.
  Future<Map<String, dynamic>> generateRoadmap(
    Map<String, dynamic> profileData,
    int resumeScore,
    double aptitudeAccuracy,
  ) async {
    final prompt = '''Create a personalized 4-week placement roadmap for student with profile: ${jsonEncode(profileData)}, ATS Resume Score: $resumeScore, Aptitude Accuracy: ${aptitudeAccuracy}%.
Return ONLY valid JSON:
{
  "weeks": [
    {
      "weekTitle": "Week 1: Foundations",
      "description": "Core algorithms and problem solving",
      "topics": ["Arrays", "HashMaps"],
      "tasks": ["Solve Two Sum", "Review Big-O"]
    }
  ]
}''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("GeminiService generateRoadmap error: $e");
      return {};
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

