import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/interview_models.dart';
import '../ai/ai_config.dart';
import '../ai/ai_logger.dart';
import '../ai/ai_validator.dart';
import '../utils/answer_validator.dart';

class AiService {
  static const String _workerUrl = 'https://anhire-ai.anandhuanil101225.workers.dev';

  final http.Client _httpClient;
  final FirebaseAuth _auth;

  AiService({http.Client? httpClient, FirebaseAuth? auth})
      : _httpClient = httpClient ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance;

  /// Retrieves current Firebase Auth ID token if available.
  Future<String?> _getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
    } catch (e) {
      debugPrint('AiService: Error retrieving Firebase ID token: $e');
    }
    return null;
  }

  /// Core helper to invoke the Cloudflare Worker Groq proxy.
  Future<Map<String, dynamic>> _callWorker({
    required String operation,
    required Map<String, dynamic> payload,
    required AiTask task,
    required String inputSummary,
    required Map<String, dynamic> fallbackData,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    String rawOutput = '';

    try {
      final token = await _getIdToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final body = jsonEncode({
        'operation': operation,
        'payload': payload,
      });

      final response = await _httpClient
          .post(
            Uri.parse(_workerUrl),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 45));

      stopwatch.stop();

      if (response.statusCode != 200) {
        debugPrint('AiService $operation worker error [${response.statusCode}]: ${response.body}');
        AiLogger.logAiCall(
          task: task,
          inputPayload: inputSummary,
          rawOutput: response.body,
          isValid: false,
          errorMessage: 'HTTP ${response.statusCode}: ${response.body}',
          latencyMs: stopwatch.elapsedMilliseconds,
        );
        return fallbackData;
      }

      rawOutput = response.body;
      final valResult = AiValidator.validateJson(task, rawOutput);

      if (valResult.isValid && valResult.parsedJson != null) {
        AiLogger.logAiCall(
          task: task,
          inputPayload: inputSummary,
          rawOutput: rawOutput,
          isValid: true,
          latencyMs: stopwatch.elapsedMilliseconds,
        );
        return valResult.parsedJson!;
      } else {
        AiLogger.logAiCall(
          task: task,
          inputPayload: inputSummary,
          rawOutput: rawOutput,
          isValid: false,
          errorMessage: valResult.errorMessage,
          latencyMs: stopwatch.elapsedMilliseconds,
        );
        return fallbackData;
      }
    } catch (e, st) {
      stopwatch.stop();
      debugPrint('AiService $operation exception: $e\n$st');
      AiLogger.logAiCall(
        task: task,
        inputPayload: inputSummary,
        rawOutput: rawOutput,
        isValid: false,
        errorMessage: e.toString(),
        latencyMs: stopwatch.elapsedMilliseconds,
      );
      return fallbackData;
    }
  }

  /// 1. Resume Analysis
  Future<Map<String, dynamic>> analyzeResume(String resumeText, String targetRole) async {
    final fallback = {
      "overallScore": 82,
      "sections": [
        {
          "name": "Summary & Objective",
          "score": 85,
          "feedback": "Solid professional summary. Highlight target role keywords."
        },
        {
          "name": "Work Experience & Projects",
          "score": 80,
          "feedback": "Strong technical foundation. Add quantified metrics."
        },
        {
          "name": "Technical Skills",
          "score": 85,
          "feedback": "Relevant skills listed for $targetRole."
        },
        {
          "name": "Education & Certifications",
          "score": 90,
          "feedback": "Properly formatted degree and academic details."
        }
      ],
      "missingKeywords": ["Docker", "CI/CD", "System Architecture"],
      "suggestions": [
        "Include specific project achievements with measurable metrics.",
        "Incorporate missing technical keywords into your project descriptions."
      ]
    };

    return _callWorker(
      operation: 'resume_analysis',
      payload: {
        'resumeText': resumeText,
        'targetRole': targetRole,
      },
      task: AiTask.resumeAnalysis,
      inputSummary: 'Role: $targetRole | Resume len: ${resumeText.length}',
      fallbackData: fallback,
    );
  }

  /// 2. Mock Interview Questions Generation
  Future<List<InterviewQuestion>> generateMockInterviewQuestions(String role, String company) async {
    final fallbackList = [
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

    final data = await _callWorker(
      operation: 'interview_question_generation',
      payload: {
        'role': role,
        'company': company,
      },
      task: AiTask.interviewQuestionGen,
      inputSummary: 'Role: $role | Company: $company',
      fallbackData: {
        'questions': fallbackList.map((q) => q.toJson()).toList(),
      },
    );

    final list = data['questions'] as List<dynamic>? ?? [];
    if (list.isEmpty) return fallbackList;
    return list.map((e) => InterviewQuestion.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// 3. Mock Interview Answer Evaluation
  Future<AnswerEvaluation> evaluateMockInterviewAnswer({
    required String question,
    required String answer,
    required String expectedKeywords,
    required String questionType,
  }) async {
    final layerACheck = await AnswerValidator.validateAnswerLayerA(answer);
    if (!layerACheck.isValid) {
      return AnswerEvaluation(
        valid: false,
        clarityScore: 0,
        correctnessScore: 0,
        confidenceScore: 0,
        overallScore: 0,
        feedback: layerACheck.errorMessage.isNotEmpty
            ? layerACheck.errorMessage
            : "This answer is not a valid, on-topic response to the question.",
        strengths: [],
        improvements: ["Provide a proper, meaningful response to the question."],
      );
    }

    final fallbackMap = AnswerEvaluation(
      valid: false,
      clarityScore: 0,
      correctnessScore: 0,
      confidenceScore: 0,
      overallScore: 0,
      feedback: "This answer is not a valid, on-topic response to the question.",
      strengths: [],
      improvements: ["Provide a relevant, meaningful answer to the question."],
    ).toJson();

    final data = await _callWorker(
      operation: 'interview_answer_evaluation',
      payload: {
        'question': question,
        'answer': answer,
        'expectedKeywords': expectedKeywords,
        'questionType': questionType,
      },
      task: AiTask.interviewAnswerEval,
      inputSummary: 'Q: $question | Ans: $answer',
      fallbackData: fallbackMap,
    );

    final bool validField = data['valid'] as bool? ?? false;
    final String relevanceField = (data['relevance'] as String? ?? '').toLowerCase();

    if (!validField || relevanceField == 'off_topic' || relevanceField == 'not_an_answer') {
      return AnswerEvaluation(
        valid: false,
        clarityScore: 0,
        correctnessScore: 0,
        confidenceScore: 0,
        overallScore: 0,
        feedback: data['feedback'] as String? ?? "This answer is not a valid, on-topic response to the question.",
        strengths: [],
        improvements: (data['improvements'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            ["Provide a relevant, meaningful answer to the question."],
      );
    }

    return AnswerEvaluation.fromJson(data);
  }

  /// 4. Learning Roadmap Generation
  Future<Map<String, dynamic>> generateRoadmap({
    required String role,
    required String companies,
    required int resumeScore,
    required int codingSolved,
    required double aptitudeAccuracy,
    required int interviewAvg,
    required String weakestArea,
  }) async {
    final fallback = {
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

    return _callWorker(
      operation: 'roadmap_generation',
      payload: {
        'role': role,
        'companies': companies,
        'resumeScore': resumeScore,
        'codingSolved': codingSolved,
        'aptitudeAccuracy': aptitudeAccuracy,
        'interviewAvg': interviewAvg,
        'weakestArea': weakestArea,
      },
      task: AiTask.learningRoadmap,
      inputSummary: 'Role: $role | Weakest: $weakestArea',
      fallbackData: fallback,
    );
  }

  /// 5. Coding Failure Hint
  Future<String> generateCodingFailureHint({
    required String problemTitle,
    required String problemDescription,
    required String language,
    required String code,
    required String errorOutput,
  }) async {
    final fallback = {
      "hint": "Check your logic around boundary conditions or array indices. Double-check your loop termination and variable initialization!"
    };

    final data = await _callWorker(
      operation: 'coding_hint',
      payload: {
        'problemTitle': problemTitle,
        'problemDescription': problemDescription,
        'language': language,
        'code': code,
        'errorOutput': errorOutput,
      },
      task: AiTask.codingHint,
      inputSummary: 'Problem: $problemTitle | Lang: $language',
      fallbackData: fallback,
    );

    return data['hint'] as String? ?? fallback['hint']!;
  }

  /// 6. Aptitude Single Question Answer & Explanation
  Future<Map<String, dynamic>> generateAptitudeAnswerSingle({
    required String question,
    required List<String> options,
  }) async {
    final fallback = {
      "answerIndex": 0,
      "explanation": "Solve by analyzing the question details and eliminating wrong choices."
    };

    return _callWorker(
      operation: 'aptitude_explanation',
      payload: {
        'question': question,
        'options': options,
      },
      task: AiTask.aptitudeAnswer,
      inputSummary: 'Q: ${question.length > 50 ? question.substring(0, 50) : question}',
      fallbackData: fallback,
    );
  }

  /// 7. Admin Batch Aptitude Generation
  Future<List<Map<String, dynamic>>> generateAptitudeAnswersBatch(String rawQuestionsText) async {
    final fallback = {
      "items": <Map<String, dynamic>>[]
    };

    final data = await _callWorker(
      operation: 'admin_batch_aptitude',
      payload: {
        'rawQuestionsText': rawQuestionsText,
      },
      task: AiTask.adminBatchAptitude,
      inputSummary: 'Batch length: ${rawQuestionsText.length}',
      fallbackData: fallback,
    );

    final list = data['items'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
