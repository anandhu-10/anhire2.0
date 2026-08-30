class AptitudeProblemModel {
  final String id;
  final String category; // quantitative, logical, verbal
  final int year;
  final String company;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final String difficulty; // easy, medium, hard

  AptitudeProblemModel({
    required this.id,
    required this.category,
    required this.year,
    required this.company,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.difficulty,
  });

  factory AptitudeProblemModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final optsRaw = map['options'] as List<dynamic>? ?? [];
    return AptitudeProblemModel(
      id: docId ?? map['id']?.toString() ?? '',
      category: map['category']?.toString().toLowerCase() ?? 'quantitative',
      year: (map['year'] as num?)?.toInt() ?? 2024,
      company: map['company']?.toString() ?? 'TCS',
      questionText: map['questionText']?.toString() ?? '',
      options: optsRaw.map((e) => e.toString()).toList(),
      correctOptionIndex: (map['correctOptionIndex'] as num?)?.toInt() ?? 0,
      explanation: map['explanation']?.toString() ?? '',
      difficulty: map['difficulty']?.toString().toLowerCase() ?? 'easy',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'year': year,
      'company': company,
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      'difficulty': difficulty,
    };
  }
}
