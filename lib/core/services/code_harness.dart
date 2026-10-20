class CodeHarness {
  /// Prepares code for execution with Piston by appending a driver harness
  /// for function-based starter templates if the student has not written their own driver/main.
  static String prepareCode({required String language, required String code}) {
    final langLower = language.toLowerCase();

    if (langLower == 'python') {
      return _preparePythonCode(code);
    } else if (langLower == 'java') {
      return _prepareJavaCode(code);
    }

    return code;
  }

  static String _preparePythonCode(String code) {
    final trimmed = code.trim();
    // If the student already wrote standard competitive programming with main / stdin / input
    if (trimmed.contains('if __name__') ||
        trimmed.contains('input(') ||
        trimmed.contains('sys.stdin')) {
      return code;
    }

    // Only append harness if user defined a function
    if (!trimmed.contains('def ')) {
      return code;
    }

    return '''$code

# --- ANHIRE RUNNER HARNESS ---
if __name__ == '__main__':
    import sys, json, inspect
    _funcs = [obj for name, obj in list(globals().items()) if inspect.isfunction(obj) and not name.startswith('_')]
    if _funcs:
        _fn = _funcs[-1]
        _raw = sys.stdin.read().strip()
        _args = []
        if _raw:
            for _line in _raw.split('\\n'):
                _s = _line.strip()
                if not _s: continue
                try:
                    _args.append(json.loads(_s))
                except Exception:
                    if _s.lower() == 'true': _args.append(True)
                    elif _s.lower() == 'false': _args.append(False)
                    else:
                        try:
                            _args.append(int(_s))
                        except ValueError:
                            try:
                                _args.append(float(_s))
                            except ValueError:
                                _args.append(_s)
        try:
            _res = _fn(*_args)
            if _res is not None:
                if isinstance(_res, bool):
                    print(str(_res).lower())
                elif isinstance(_res, (list, dict)):
                    print(json.dumps(_res))
                else:
                    print(_res)
        except Exception:
            import traceback
            traceback.print_exc()
''';
  }

  static String _prepareJavaCode(String code) {
    // If user already wrote public static void main, keep it intact
    if (code.contains('public static void main')) {
      // Ensure the class name is Main if it has public class
      if (code.contains('public class ') &&
          !code.contains('public class Main')) {
        return code.replaceFirst(
          RegExp(r'public class \w+'),
          'public class Main',
        );
      }
      return code;
    }

    // If it has "public class Solution", make it package-private so Main can be in the same file
    String modified = code;
    if (modified.contains('public class Solution')) {
      modified = modified.replaceFirst(
        'public class Solution',
        'class Solution',
      );
    }

    // If Solution is present, attach Main runner
    if (modified.contains('class Solution')) {
      return '''$modified

// --- ANHIRE RUNNER HARNESS ---
public class Main {
    public static void main(String[] args) {
        try {
            java.util.Scanner sc = new java.util.Scanner(System.in);
            java.lang.StringBuilder sb = new java.lang.StringBuilder();
            while (sc.hasNextLine()) {
                String line = sc.nextLine().trim();
                if (!line.isEmpty()) {
                    sb.append(line).append("\\n");
                }
            }
            String raw = sb.toString().trim();
            Solution sol = new Solution();
            java.lang.reflect.Method[] methods = Solution.class.getDeclaredMethods();
            if (methods.length > 0) {
                java.lang.reflect.Method m = methods[0];
                m.setAccessible(true);
                Class<?>[] paramTypes = m.getParameterTypes();
                Object[] invokeArgs = new Object[paramTypes.length];
                String[] lines = raw.isEmpty() ? new String[0] : raw.split("\\n");
                
                for (int i = 0; i < paramTypes.length; i++) {
                    String paramStr = (i < lines.length) ? lines[i].trim() : "";
                    Class<?> pType = paramTypes[i];
                    
                    if (pType == int.class || pType == Integer.class) {
                        invokeArgs[i] = paramStr.isEmpty() ? 0 : Integer.parseInt(paramStr);
                    } else if (pType == double.class || pType == Double.class) {
                        invokeArgs[i] = paramStr.isEmpty() ? 0.0 : Double.parseDouble(paramStr);
                    } else if (pType == boolean.class || pType == Boolean.class) {
                        invokeArgs[i] = Boolean.parseBoolean(paramStr);
                    } else if (pType == String.class) {
                        if (paramStr.startsWith("\\"") && paramStr.endsWith("\\"") && paramStr.length() >= 2) {
                            paramStr = paramStr.substring(1, paramStr.length() - 1);
                        }
                        invokeArgs[i] = paramStr;
                    } else if (pType == int[].class) {
                        String clean = paramStr.replaceAll("[\\\\[\\\\]\\\\s]", "");
                        if (clean.isEmpty()) {
                            invokeArgs[i] = new int[0];
                        } else {
                            String[] parts = clean.split(",");
                            int[] arr = new int[parts.length];
                            for (int k = 0; k < parts.length; k++) arr[k] = Integer.parseInt(parts[k].trim());
                            invokeArgs[i] = arr;
                        }
                    } else if (pType == char[].class) {
                        String clean = paramStr.replaceAll("[\\\\[\\\\]\\\\s\\"]", "");
                        String[] parts = clean.split(",");
                        char[] arr = new char[parts.length];
                        for (int k = 0; k < parts.length; k++) arr[k] = parts[k].isEmpty() ? ' ' : parts[k].charAt(0);
                        invokeArgs[i] = arr;
                    } else {
                        invokeArgs[i] = paramStr;
                    }
                }
                
                Object res = m.invoke(sol, invokeArgs);
                if (res != null) {
                    if (res instanceof int[]) {
                        int[] arr = (int[]) res;
                        System.out.print("[");
                        for (int k = 0; k < arr.length; k++) {
                            System.out.print(arr[k] + (k < arr.length - 1 ? ", " : ""));
                        }
                        System.out.println("]");
                    } else if (res instanceof char[]) {
                        char[] arr = (char[]) res;
                        System.out.print("[");
                        for (int k = 0; k < arr.length; k++) {
                            System.out.print("\\"" + arr[k] + "\\"" + (k < arr.length - 1 ? ", " : ""));
                        }
                        System.out.println("]");
                    } else if (res instanceof java.util.List) {
                        java.util.List<?> list = (java.util.List<?>) res;
                        System.out.print("[");
                        for (int k = 0; k < list.size(); k++) {
                            Object item = list.get(k);
                            if (item instanceof String) {
                                System.out.print("\\"" + item + "\\"" + (k < list.size() - 1 ? ", " : ""));
                            } else {
                                System.out.print(item + (k < list.size() - 1 ? ", " : ""));
                            }
                        }
                        System.out.println("]");
                    } else {
                        System.out.println(res);
                    }
                }
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }
}
''';
    }

    return code;
  }
}
