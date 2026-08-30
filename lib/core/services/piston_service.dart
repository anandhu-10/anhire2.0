import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PistonExecutionResult {
  final bool success;
  final String stdout;
  final String stderr;
  final String output;
  final int exitCode;

  PistonExecutionResult({
    required this.success,
    required this.stdout,
    required this.stderr,
    required this.output,
    required this.exitCode,
  });

  factory PistonExecutionResult.fromPistonResponse(Map<String, dynamic> json) {
    final run = json['run'] as Map<String, dynamic>? ?? {};
    final stdout = run['stdout']?.toString() ?? '';
    final stderr = run['stderr']?.toString() ?? '';
    final output = run['output']?.toString() ?? '';
    final exitCode = (run['code'] as num?)?.toInt() ?? 0;

    return PistonExecutionResult(
      success: exitCode == 0 && stderr.isEmpty,
      stdout: stdout.trim(),
      stderr: stderr.trim(),
      output: output.trim(),
      exitCode: exitCode,
    );
  }
}

class PistonService {
  static const String _pistonUrl = 'https://emkc.org/api/v2/piston/execute';

  /// Executes code in Python or Java via Piston API against a given stdin string.
  Future<PistonExecutionResult> executeCode({
    required String language,
    required String code,
    String stdin = '',
  }) async {
    final langLower = language.toLowerCase();
    final isPython = langLower == 'python';
    final isJava = langLower == 'java';

    final pistonLang = isPython ? 'python' : (isJava ? 'java' : 'python');
    final version = isPython ? '3.10.0' : '15.0.2';
    final fileName = isPython ? 'main.py' : 'Main.java';

    final body = {
      'language': pistonLang,
      'version': version,
      'files': [
        {
          'name': fileName,
          'content': code,
        }
      ],
      'stdin': stdin,
    };

    try {
      debugPrint("Sending execution request to Piston API for $pistonLang...");
      final response = await http.post(
        Uri.parse(_pistonUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PistonExecutionResult.fromPistonResponse(data);
      } else {
        debugPrint("Piston API error status ${response.statusCode}: ${response.body}");
        return PistonExecutionResult(
          success: false,
          stdout: '',
          stderr: 'Execution server returned error ${response.statusCode}',
          output: 'Execution failed',
          exitCode: 1,
        );
      }
    } catch (e) {
      debugPrint("PistonService connection error: $e");
      return PistonExecutionResult(
        success: false,
        stdout: '',
        stderr: 'Network error executing code: $e',
        output: 'Network error',
        exitCode: 1,
      );
    }
  }
}
