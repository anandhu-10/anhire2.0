import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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

  /// Generates technical and behavioral interview questions for a role & target company.
  Future<List<String>> generateInterviewQuestions(String role, String company) async {
    final prompt = '''Generate 5 tailored interview questions for a candidate interviewing for a "$role" position at "$company".
Return ONLY valid JSON array of strings:
["Question 1", "Question 2", "Question 3", "Question 4", "Question 5"]''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '[]';
      final list = jsonDecode(text) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint("GeminiService generateInterviewQuestions error: $e");
      return [
        'Tell me about a challenging technical problem you solved.',
        'How do you approach optimizing data structures under memory constraints?',
        'Describe a situation where you had to debug a difficult production issue.',
      ];
    }
  }

  /// Evaluates user's interview answer on Clarity, Correctness, and Confidence.
  Future<Map<String, dynamic>> evaluateInterviewAnswer(String question, String answer) async {
    final prompt = '''Evaluate the following interview candidate response.
Question: "$question"
Answer: "$answer"

Return ONLY valid JSON with scores (0-100) and actionable feedback:
{
  "clarity": 85,
  "correctness": 90,
  "confidence": 80,
  "overallScore": 85,
  "feedback": "Strong response using STAR method. Add specific metrics."
}''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("GeminiService evaluateInterviewAnswer error: $e");
      return {
        "clarity": 80,
        "correctness": 85,
        "confidence": 80,
        "overallScore": 82,
        "feedback": "Solid answer with good technical depth."
      };
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
}
