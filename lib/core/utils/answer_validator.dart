import 'package:flutter/services.dart' show rootBundle;

class AnswerValidatorResult {
  final bool isValid;
  final String errorMessage;

  const AnswerValidatorResult({
    required this.isValid,
    this.errorMessage = '',
  });
}

class AnswerValidator {
  static Set<String>? _dictionary;

  /// Loads common English word list from assets/data/common_words.txt
  static Future<Set<String>> loadDictionary() async {
    if (_dictionary != null && _dictionary!.isNotEmpty) {
      return _dictionary!;
    }
    try {
      final content = await rootBundle.loadString('assets/data/common_words.txt');
      final lines = content.split('\n');
      _dictionary = lines
          .map((line) => line.trim().toLowerCase())
          .where((w) => w.isNotEmpty)
          .toSet();
    } catch (_) {
      _dictionary = <String>{};
    }
    return _dictionary!;
  }

  /// Loosened Layer A Word-Level Validation
  /// Rejects ONLY true non-answers / gibberish:
  /// - Any token has a 5+ consonant run (e.g. "chcfggfggfghgfh")
  /// - Fewer than 3 of the tokens are dictionary words (when cleaned tokens >= 3)
  /// - Whole answer has fewer than 4 word-like tokens
  static Future<AnswerValidatorResult> validateAnswerLayerA(String text) async {
    final trimmed = text.trim();
    const defaultErrorMsg = "This doesn't look like a meaningful answer. Please write a proper response to the question.";

    if (trimmed.isEmpty) {
      return const AnswerValidatorResult(isValid: false, errorMessage: defaultErrorMsg);
    }

    final rawTokens = trimmed.split(RegExp(r'\s+'));
    final cleanedTokens = rawTokens
        .map((t) => t.replaceAll(RegExp(r'[^\w]'), '').toLowerCase())
        .where((t) => t.isNotEmpty)
        .toList();

    if (cleanedTokens.isEmpty) {
      return const AnswerValidatorResult(isValid: false, errorMessage: defaultErrorMsg);
    }

    // 1. Any token contains a run of 5+ consonants (e.g. "chcfggfggfghgfh")
    final consonant5Regex = RegExp(r'[bcdfghjklmnpqrstvwxyz]{5,}', caseSensitive: false);
    for (final token in cleanedTokens) {
      if (consonant5Regex.hasMatch(token)) {
        return const AnswerValidatorResult(isValid: false, errorMessage: defaultErrorMsg);
      }
    }

    // 2. Count word-like tokens
    final vowelRegex = RegExp(r'[aeiouy]', caseSensitive: false);
    final consonant4Regex = RegExp(r'[bcdfghjklmnpqrstvwxyz]{4,}', caseSensitive: false);

    int wordLikeCount = 0;
    for (final token in cleanedTokens) {
      final isWordLike = token.length >= 1 &&
          (vowelRegex.hasMatch(token) || token.length == 1) &&
          !consonant4Regex.hasMatch(token);
      if (isWordLike) {
        wordLikeCount++;
      }
    }

    // Reject if fewer than 4 word-like tokens in whole answer
    if (wordLikeCount < 4) {
      return const AnswerValidatorResult(isValid: false, errorMessage: defaultErrorMsg);
    }

    // 3. Fewer than 3 of the tokens are dictionary words (if cleanedTokens >= 3)
    final dict = await loadDictionary();
    if (dict.isNotEmpty && cleanedTokens.length >= 3) {
      int dictMatchCount = 0;
      for (final token in cleanedTokens) {
        if (dict.contains(token)) {
          dictMatchCount++;
        }
      }

      if (dictMatchCount < 3) {
        return const AnswerValidatorResult(isValid: false, errorMessage: defaultErrorMsg);
      }
    }

    return const AnswerValidatorResult(isValid: true);
  }

  /// Synchronous version of Layer A check (if dictionary loaded)
  static AnswerValidatorResult validateAnswerLayerASync(String text) {
    final trimmed = text.trim();
    const defaultErrorMsg = "This doesn't look like a meaningful answer. Please write a proper response to the question.";

    if (trimmed.isEmpty) {
      return const AnswerValidatorResult(isValid: false, errorMessage: defaultErrorMsg);
    }

    final rawTokens = trimmed.split(RegExp(r'\s+'));
    final cleanedTokens = rawTokens
        .map((t) => t.replaceAll(RegExp(r'[^\w]'), '').toLowerCase())
        .where((t) => t.isNotEmpty)
        .toList();

    if (cleanedTokens.isEmpty) {
      return const AnswerValidatorResult(isValid: false, errorMessage: defaultErrorMsg);
    }

    final consonant5Regex = RegExp(r'[bcdfghjklmnpqrstvwxyz]{5,}', caseSensitive: false);
    for (final token in cleanedTokens) {
      if (consonant5Regex.hasMatch(token)) {
        return const AnswerValidatorResult(isValid: false, errorMessage: defaultErrorMsg);
      }
    }

    final vowelRegex = RegExp(r'[aeiouy]', caseSensitive: false);
    final consonant4Regex = RegExp(r'[bcdfghjklmnpqrstvwxyz]{4,}', caseSensitive: false);

    int wordLikeCount = 0;
    for (final token in cleanedTokens) {
      final isWordLike = token.length >= 1 &&
          (vowelRegex.hasMatch(token) || token.length == 1) &&
          !consonant4Regex.hasMatch(token);
      if (isWordLike) {
        wordLikeCount++;
      }
    }

    if (wordLikeCount < 4) {
      return const AnswerValidatorResult(isValid: false, errorMessage: defaultErrorMsg);
    }

    if (_dictionary != null && _dictionary!.isNotEmpty && cleanedTokens.length >= 3) {
      int dictMatchCount = 0;
      for (final token in cleanedTokens) {
        if (_dictionary!.contains(token)) {
          dictMatchCount++;
        }
      }

      if (dictMatchCount < 3) {
        return const AnswerValidatorResult(isValid: false, errorMessage: defaultErrorMsg);
      }
    }

    return const AnswerValidatorResult(isValid: true);
  }
}
