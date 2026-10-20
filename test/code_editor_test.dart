import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/java.dart';

void main() {
  test('CodeController can be instantiated with python and java', () {
    final controller = CodeController(text: 'print("hello")', language: python);
    expect(controller.text, 'print("hello")');
    controller.language = java;
    expect(controller.language, java);
  });
}
