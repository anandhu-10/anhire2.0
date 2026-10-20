import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'code_harness.dart';

class PistonExecutionResult {
  final bool success;
  final String stdout;
  final String stderr;
  final String output;
  final int exitCode;
  final int? executionTimeMs;
  final bool isTimeout;
  final bool isCompilationError;

  PistonExecutionResult({
    required this.success,
    required this.stdout,
    required this.stderr,
    required this.output,
    required this.exitCode,
    this.executionTimeMs,
    this.isTimeout = false,
    this.isCompilationError = false,
  });

  factory PistonExecutionResult.fromPistonResponse(
    Map<String, dynamic> json, {
    int? elapsedMs,
  }) {
    final compile = json['compile'] as Map<String, dynamic>?;
    final run = json['run'] as Map<String, dynamic>? ?? {};

    String stdout = run['stdout']?.toString() ?? '';
    String stderr = run['stderr']?.toString() ?? '';
    String output = run['output']?.toString() ?? '';
    int exitCode = (run['code'] as num?)?.toInt() ?? 0;

    bool compilationFailed = false;
    if (compile != null) {
      final compileCode = (compile['code'] as num?)?.toInt() ?? 0;
      final compileStderr = compile['stderr']?.toString() ?? '';
      final compileOutput = compile['output']?.toString() ?? '';
      if (compileCode != 0 || compileStderr.isNotEmpty) {
        compilationFailed = true;
        exitCode = compileCode != 0 ? compileCode : 1;
        stderr = compileStderr.isNotEmpty ? compileStderr : compileOutput;
        output = stderr;
      }
    }

    final bool isTimeout =
        exitCode == 124 ||
        stderr.toLowerCase().contains('time limit') ||
        stderr.toLowerCase().contains('timed out');

    return PistonExecutionResult(
      success: !compilationFailed && exitCode == 0 && stderr.isEmpty,
      stdout: stdout.trim(),
      stderr: stderr.trim(),
      output: output.trim(),
      exitCode: exitCode,
      executionTimeMs: elapsedMs,
      isTimeout: isTimeout,
      isCompilationError: compilationFailed,
    );
  }
}

class PistonService {
  final http.Client _httpClient;

  PistonService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// Executes code in Python or Java via Piston API against a given stdin string.
  Future<PistonExecutionResult> executeCode({
    required String language,
    required String code,
    String stdin = '',
  }) async {
    final rawUrl = dotenv.env['PISTON_API_URL']?.trim();
    final pistonUrl = (rawUrl != null && rawUrl.isNotEmpty)
        ? rawUrl
        : 'https://emkc.org/api/v2/piston/execute';

    final apiKey = dotenv.env['PISTON_API_KEY']?.trim();

    final langLower = language.toLowerCase();
    final isPython = langLower == 'python';
    final isJava = langLower == 'java';

    final pistonLang = isPython ? 'python' : (isJava ? 'java' : 'python');
    final version = isPython ? '3.10.0' : '15.0.2';
    final fileName = isPython ? 'main.py' : 'Main.java';

    // Apply smart harness for function/class template code if needed
    final preparedCode = CodeHarness.prepareCode(
      language: language,
      code: code,
    );

    final body = {
      'language': pistonLang,
      'version': version,
      'files': [
        {'name': fileName, 'content': preparedCode},
      ],
      'stdin': stdin,
    };

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final stopwatch = Stopwatch()..start();

    try {
      debugPrint("Sending execution request to $pistonUrl for $pistonLang...");
      final response = await _httpClient
          .post(Uri.parse(pistonUrl), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PistonExecutionResult.fromPistonResponse(
          data,
          elapsedMs: elapsedMs,
        );
      } else if (response.statusCode == 401) {
        final responseBody = response.body;
        return PistonExecutionResult(
          success: false,
          stdout: '',
          stderr:
              'Remote Execution Error (401 Unauthorized):\nPublic Piston API is whitelist-only. Please configure a custom PISTON_API_URL or PISTON_API_KEY in your .env file.\n\nServer response: $responseBody',
          output: 'Execution unauthorized',
          exitCode: 401,
          executionTimeMs: elapsedMs,
        );
      } else {
        debugPrint(
          "Piston API error status ${response.statusCode}: ${response.body}",
        );
        return PistonExecutionResult(
          success: false,
          stdout: '',
          stderr:
              'Execution server returned error ${response.statusCode}: ${response.body}',
          output: 'Execution failed',
          exitCode: response.statusCode,
          executionTimeMs: elapsedMs,
        );
      }
    } catch (e) {
      stopwatch.stop();
      final isTimeout = e.toString().toLowerCase().contains('timeout');
      debugPrint("PistonService connection error: $e");
      return PistonExecutionResult(
        success: false,
        stdout: '',
        stderr: isTimeout
            ? 'Execution timed out after 15 seconds. Please check for infinite loops or long-running computations.'
            : 'Network error executing code: $e',
        output: isTimeout ? 'Time Limit Exceeded' : 'Network error',
        exitCode: isTimeout ? 124 : 1,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        isTimeout: isTimeout,
      );
    }
  }
}
