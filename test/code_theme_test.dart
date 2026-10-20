import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

void main() {
  test('CodeThemeData with atomOneDarkTheme works', () {
    final controller = CodeController(
      text: 'def test():\n    pass',
      language: python,
    );
    final theme = CodeThemeData(styles: atomOneDarkTheme);
    expect(theme.styles.isNotEmpty, true);
    expect(controller.text.isNotEmpty, true);
  });
}
