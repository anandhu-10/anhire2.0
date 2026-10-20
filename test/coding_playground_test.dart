import 'package:flutter_test/flutter_test.dart';
import 'package:placementprep/core/services/code_harness.dart';
import 'package:placementprep/core/services/piston_service.dart';
import 'package:placementprep/providers/coding_provider.dart';
import 'package:placementprep/models/coding_submission_model.dart';

void main() {
  group('CodeHarness Tests', () {
    test('appends Python runner harness to function-based code', () {
      const userCode = '''def two_sum(nums, target):
    return [0, 1]''';

      final prepared = CodeHarness.prepareCode(
        language: 'python',
        code: userCode,
      );

      expect(prepared.contains('def two_sum(nums, target):'), true);
      expect(prepared.contains('# --- ANHIRE RUNNER HARNESS ---'), true);
      expect(prepared.contains('json.loads'), true);
    });

    test('does not append Python harness if script already has __main__', () {
      const scriptCode = '''import sys
if __name__ == '__main__':
    print("hello")''';

      final prepared = CodeHarness.prepareCode(
        language: 'python',
        code: scriptCode,
      );

      expect(prepared, scriptCode);
    });

    test('adapts Java class Solution with Main driver harness', () {
      const javaCode = '''public class Solution {
    public int[] twoSum(int[] nums, int target) {
        return new int[]{0, 1};
    }
}''';

      final prepared = CodeHarness.prepareCode(
        language: 'java',
        code: javaCode,
      );

      expect(prepared.contains('class Solution'), true);
      expect(prepared.contains('public class Main'), true);
      expect(prepared.contains('public static void main(String[] args)'), true);
    });

    test(
      'preserves Java code that already defines public static void main',
      () {
        const customMain = '''import java.util.*;
public class Main {
    public static void main(String[] args) {
        System.out.println("custom output");
    }
}''';

        final prepared = CodeHarness.prepareCode(
          language: 'java',
          code: customMain,
        );

        expect(prepared, customMain);
      },
    );
  });

  group('Execution Logic & Output Normalization Tests', () {
    test('normalizeOutput strips extra newlines and windows CRLF', () {
      const raw = "  [0, 1]  \r\n\r\n";
      final norm = ExecutionNotifier.normalizeOutput(raw);
      expect(norm, '[0, 1]');
    });

    test(
      'PistonExecutionResult accurately identifies compilation failures',
      () {
        final jsonResponse = {
          'compile': {
            'code': 1,
            'output': "error: ';' expected",
            'stderr': "error: ';' expected",
          },
          'run': {'stdout': '', 'stderr': '', 'code': 0},
        };

        final res = PistonExecutionResult.fromPistonResponse(jsonResponse);
        expect(res.success, false);
        expect(res.isCompilationError, true);
        expect(res.exitCode, 1);
        expect(res.stderr.contains("error: ';' expected"), true);
      },
    );

    test('PistonExecutionResult handles timeout exit code 124', () {
      final jsonResponse = {
        'run': {'stdout': '', 'stderr': 'Time limit exceeded', 'code': 124},
      };

      final res = PistonExecutionResult.fromPistonResponse(jsonResponse);
      expect(res.success, false);
      expect(res.isTimeout, true);
    });
  });

  group('Submission Model Tests', () {
    test('CodingSubmissionModel serializes and deserializes correctly', () {
      final sub = CodingSubmissionModel(
        uid: 'user_123',
        problemId: 'cp_001',
        code: 'print("hello")',
        language: 'python',
        testResults: [
          SubmissionTestResult(
            testIndex: 1,
            passed: true,
            stdout: 'hello',
            stderr: '',
            expected: 'hello',
            actual: 'hello',
            input: '',
            status: 'Passed',
          ),
        ],
        passed: true,
        testCasesPassed: 1,
        testCasesTotal: 1,
        verdict: 'Accepted',
        submittedAt: DateTime(2026, 10, 20),
      );

      final map = sub.toMap();
      expect(map['uid'], 'user_123');
      expect(map['problemId'], 'cp_001');
      expect(map['verdict'], 'Accepted');
      expect(map['passed'], true);

      final reconstructed = CodingSubmissionModel.fromMap(map, 'doc_001');
      expect(reconstructed.id, 'doc_001');
      expect(reconstructed.uid, 'user_123');
      expect(reconstructed.testResults.length, 1);
      expect(reconstructed.testResults.first.passed, true);
      expect(reconstructed.testResults.first.status, 'Passed');
    });
  });
}
