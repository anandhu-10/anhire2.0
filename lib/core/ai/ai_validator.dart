import 'dart:convert';
import 'ai_config.dart';

class AiValidationResult {
  final bool isValid;
  final String errorMessage;
  final Map<String, dynamic>? parsedJson;

  const AiValidationResult({
    required this.isValid,
    this.errorMessage = '',
    this.parsedJson,
  });
}

class AiValidator {
  /// Validates raw JSON output from Gemini against expected schema per task.
  static AiValidationResult validateJson(AiTask task, String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return const AiValidationResult(
        isValid: false,
        errorMessage: 'Raw AI output is empty',
      );
    }

    dynamic parsed;
    try {
      // Strip markdown code block wrappers ```json ... ``` if present
      String cleanText = trimmed;
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      } else if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      parsed = jsonDecode(cleanText);
    } catch (e) {
      return AiValidationResult(
        isValid: false,
        errorMessage: 'JSON parse failure: $e',
      );
    }

    if (parsed is! Map<String, dynamic> && parsed is! List) {
      return const AiValidationResult(
        isValid: false,
        errorMessage: 'JSON root object must be a Map or List',
      );
    }

    // Wrap List as Map if applicable
    final Map<String, dynamic> data = parsed is Map<String, dynamic>
        ? parsed
        : {'items': parsed};

    switch (task) {
      case AiTask.resumeAnalysis:
        return _validateResumeAnalysis(data);
      case AiTask.codingHint:
        return _validateCodingHint(data);
      case AiTask.aptitudeAnswer:
        return _validateAptitudeAnswer(data);
      case AiTask.interviewQuestionGen:
        return _validateInterviewQuestionGen(data);
      case AiTask.interviewAnswerEval:
        return _validateInterviewAnswerEval(data);
      case AiTask.learningRoadmap:
        return _validateLearningRoadmap(data);
      case AiTask.adminBatchAptitude:
        return _validateAdminBatchAptitude(data);
    }
  }

  static String buildRepairPrompt(String taskName, String errorMessage) {
    return '''Your previous JSON response for task "$taskName" failed schema validation.

Validation Error: $errorMessage

Please fix the error and return ONLY valid JSON strictly adhering to the specified schema without markdown wrappers or extra commentary.''';
  }

  // --- Task-Specific Validation Helpers ---

  static AiValidationResult _validateResumeAnalysis(Map<String, dynamic> data) {
    if (!data.containsKey('overallScore') || data['overallScore'] is! num) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing or invalid numeric field "overallScore"');
    }
    if (!data.containsKey('sections') || data['sections'] is! List) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing or invalid List field "sections"');
    }
    if (!data.containsKey('missingKeywords') || data['missingKeywords'] is! List) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing or invalid List field "missingKeywords"');
    }
    if (!data.containsKey('suggestions') || data['suggestions'] is! List) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing or invalid List field "suggestions"');
    }
    return AiValidationResult(isValid: true, parsedJson: data);
  }

  static AiValidationResult _validateCodingHint(Map<String, dynamic> data) {
    if (!data.containsKey('hint') || data['hint'] is! String || (data['hint'] as String).trim().isEmpty) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing or empty string field "hint"');
    }
    return AiValidationResult(isValid: true, parsedJson: data);
  }

  static AiValidationResult _validateAptitudeAnswer(Map<String, dynamic> data) {
    if (!data.containsKey('answerIndex') || data['answerIndex'] is! num) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing or invalid numeric field "answerIndex"');
    }
    final idx = (data['answerIndex'] as num).toInt();
    if (idx < 0 || idx > 3) {
      return AiValidationResult(isValid: false, errorMessage: 'Field "answerIndex" must be between 0 and 3, got: $idx');
    }
    if (!data.containsKey('explanation') || data['explanation'] is! String) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing or invalid string field "explanation"');
    }
    return AiValidationResult(isValid: true, parsedJson: data);
  }

  static AiValidationResult _validateInterviewQuestionGen(Map<String, dynamic> data) {
    if (!data.containsKey('questions') || data['questions'] is! List) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing or invalid List field "questions"');
    }
    final list = data['questions'] as List;
    if (list.length < 4) {
      return AiValidationResult(isValid: false, errorMessage: 'Expected at least 4-6 questions, got: ${list.length}');
    }
    return AiValidationResult(isValid: true, parsedJson: data);
  }

  static AiValidationResult _validateInterviewAnswerEval(Map<String, dynamic> data) {
    if (!data.containsKey('valid') || data['valid'] is! bool) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing or non-boolean field "valid"');
    }
    if (!data.containsKey('clarityScore') || data['clarityScore'] is! num) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing numeric field "clarityScore"');
    }
    if (!data.containsKey('correctnessScore') || data['correctnessScore'] is! num) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing numeric field "correctnessScore"');
    }
    if (!data.containsKey('confidenceScore') || data['confidenceScore'] is! num) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing numeric field "confidenceScore"');
    }
    if (!data.containsKey('overallScore') || data['overallScore'] is! num) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing numeric field "overallScore"');
    }
    if (!data.containsKey('feedback') || data['feedback'] is! String) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing string field "feedback"');
    }
    return AiValidationResult(isValid: true, parsedJson: data);
  }

  static AiValidationResult _validateLearningRoadmap(Map<String, dynamic> data) {
    if (!data.containsKey('weeks') || data['weeks'] is! List) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing or invalid List field "weeks"');
    }
    final list = data['weeks'] as List;
    if (list.length < 3 || list.length > 10) {
      return AiValidationResult(isValid: false, errorMessage: 'Field "weeks" should contain 4-8 weeks, got: ${list.length}');
    }
    return AiValidationResult(isValid: true, parsedJson: data);
  }

  static AiValidationResult _validateAdminBatchAptitude(Map<String, dynamic> data) {
    if (!data.containsKey('items') || data['items'] is! List) {
      return const AiValidationResult(isValid: false, errorMessage: 'Missing or invalid List field "items"');
    }
    return AiValidationResult(isValid: true, parsedJson: data);
  }
}
