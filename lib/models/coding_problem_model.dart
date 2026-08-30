class TestCase {
  final String input;
  final String output;

  TestCase({
    required this.input,
    required this.output,
  });

  factory TestCase.fromMap(Map<String, dynamic> map) {
    return TestCase(
      input: map['input']?.toString() ?? '',
      output: map['output']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'input': input,
      'output': output,
    };
  }
}

class CodingProblemModel {
  final String id;
  final String title;
  final String difficulty; // easy, medium, hard
  final String category;
  final String description;
  final List<String> constraints;
  final String sampleInput;
  final String sampleOutput;
  final List<TestCase> testCases;
  final Map<String, String> starterCode;
  final int timeLimit;
  final int memoryLimit;

  CodingProblemModel({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.category,
    required this.description,
    required this.constraints,
    required this.sampleInput,
    required this.sampleOutput,
    required this.testCases,
    required this.starterCode,
    required this.timeLimit,
    required this.memoryLimit,
  });

  factory CodingProblemModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final testCasesRaw = map['testCases'] as List<dynamic>? ?? [];
    final starterCodeRaw = map['starterCode'] as Map<String, dynamic>? ?? {};

    return CodingProblemModel(
      id: docId ?? map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Problem',
      difficulty: map['difficulty']?.toString() ?? 'easy',
      category: map['category']?.toString() ?? 'arrays',
      description: map['description']?.toString() ?? '',
      constraints: (map['constraints'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sampleInput: map['sampleInput']?.toString() ?? '',
      sampleOutput: map['sampleOutput']?.toString() ?? '',
      testCases: testCasesRaw
          .map((e) => TestCase.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      starterCode: starterCodeRaw.map((k, v) => MapEntry(k, v.toString())),
      timeLimit: (map['timeLimit'] as num?)?.toInt() ?? 5,
      memoryLimit: (map['memoryLimit'] as num?)?.toInt() ?? 256,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty,
      'category': category,
      'description': description,
      'constraints': constraints,
      'sampleInput': sampleInput,
      'sampleOutput': sampleOutput,
      'testCases': testCases.map((e) => e.toMap()).toList(),
      'starterCode': starterCode,
      'timeLimit': timeLimit,
      'memoryLimit': memoryLimit,
    };
  }
}
