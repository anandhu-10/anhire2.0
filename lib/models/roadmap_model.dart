import 'package:cloud_firestore/cloud_firestore.dart';

class RoadmapTask {
  final String text;
  final bool completed;

  RoadmapTask({
    required this.text,
    this.completed = false,
  });

  factory RoadmapTask.fromMap(Map<String, dynamic> map) {
    return RoadmapTask(
      text: map['text'] as String? ?? '',
      completed: map['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'completed': completed,
    };
  }

  RoadmapTask copyWith({String? text, bool? completed}) {
    return RoadmapTask(
      text: text ?? this.text,
      completed: completed ?? this.completed,
    );
  }
}

class RoadmapWeek {
  final int weekNumber;
  final String focus;
  final List<String> topics;
  final List<RoadmapTask> tasks;

  RoadmapWeek({
    required this.weekNumber,
    required this.focus,
    required this.topics,
    required this.tasks,
  });

  int get completedTasksCount => tasks.where((t) => t.completed).length;
  int get totalTasksCount => tasks.length;
  double get progressPercentage =>
      totalTasksCount == 0 ? 0.0 : (completedTasksCount / totalTasksCount);

  factory RoadmapWeek.fromMap(Map<String, dynamic> map) {
    final rawTopics = map['topics'] as List<dynamic>? ?? [];
    final rawTasks = map['tasks'] as List<dynamic>? ?? [];

    return RoadmapWeek(
      weekNumber: (map['weekNumber'] as num?)?.toInt() ?? 1,
      focus: map['focus'] as String? ?? 'Placement Preparation',
      topics: rawTopics.map((e) => e.toString()).toList(),
      tasks: rawTasks.map((e) {
        if (e is Map) {
          return RoadmapTask.fromMap(Map<String, dynamic>.from(e));
        } else if (e is String) {
          return RoadmapTask(text: e, completed: false);
        }
        return RoadmapTask(text: e.toString(), completed: false);
      }).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'focus': focus,
      'topics': topics,
      'tasks': tasks.map((t) => t.toMap()).toList(),
    };
  }

  RoadmapWeek copyWith({
    int? weekNumber,
    String? focus,
    List<String>? topics,
    List<RoadmapTask>? tasks,
  }) {
    return RoadmapWeek(
      weekNumber: weekNumber ?? this.weekNumber,
      focus: focus ?? this.focus,
      topics: topics ?? this.topics,
      tasks: tasks ?? this.tasks,
    );
  }
}

class Roadmap {
  final String uid;
  final String role;
  final String companies;
  final List<RoadmapWeek> weeks;
  final double overallProgress;
  final DateTime createdAt;
  final DateTime updatedAt;

  Roadmap({
    required this.uid,
    required this.role,
    required this.companies,
    required this.weeks,
    required this.overallProgress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Roadmap.fromFirestore(Map<String, dynamic> data, String uid) {
    final rawWeeks = data['weeks'] as List<dynamic>? ?? [];
    final weeksList = rawWeeks
        .map((e) => RoadmapWeek.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    int totalTasks = 0;
    int completedTasks = 0;
    for (var w in weeksList) {
      totalTasks += w.totalTasksCount;
      completedTasks += w.completedTasksCount;
    }
    final calcProgress = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks);

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Roadmap(
      uid: uid,
      role: data['role'] as String? ?? 'Software Engineer',
      companies: data['companies'] as String? ?? 'Target Tech Companies',
      weeks: weeksList,
      overallProgress: (data['overallProgress'] as num?)?.toDouble() ?? calcProgress,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    int totalTasks = 0;
    int completedTasks = 0;
    for (var w in weeks) {
      totalTasks += w.totalTasksCount;
      completedTasks += w.completedTasksCount;
    }
    final calcProgress = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks);

    return {
      'uid': uid,
      'role': role,
      'companies': companies,
      'weeks': weeks.map((w) => w.toMap()).toList(),
      'overallProgress': calcProgress,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Roadmap copyWith({
    String? uid,
    String? role,
    String? companies,
    List<RoadmapWeek>? weeks,
    double? overallProgress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Roadmap(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      companies: companies ?? this.companies,
      weeks: weeks ?? this.weeks,
      overallProgress: overallProgress ?? this.overallProgress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
