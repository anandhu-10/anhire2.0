import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'ai_config.dart';

class AiLogger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference get _collection => _firestore.collection('ai_logs');

  /// Logs an AI execution attempt to the "ai_logs" Firestore collection.
  static Future<void> logAiCall({
    required AiTask task,
    required String inputPayload,
    required String rawOutput,
    required bool isValid,
    required int latencyMs,
    String? errorMessage,
    bool repaired = false,
  }) async {
    final taskName = task.name;
    final logData = {
      'task': taskName,
      'inputPayload': inputPayload.length > 500 ? '${inputPayload.substring(0, 500)}...' : inputPayload,
      'rawOutput': rawOutput.length > 1000 ? '${rawOutput.substring(0, 1000)}...' : rawOutput,
      'isValid': isValid,
      'repaired': repaired,
      'latencyMs': latencyMs,
      'errorMessage': errorMessage,
      'createdAt': Timestamp.now(),
    };

    try {
      await _collection.add(logData);
      debugPrint('AiLogger: Successfully logged $taskName (latency: ${latencyMs}ms, isValid: $isValid)');
    } catch (e) {
      debugPrint('AiLogger warning: Failed to write ai_log document: $e');
    }
  }
}
