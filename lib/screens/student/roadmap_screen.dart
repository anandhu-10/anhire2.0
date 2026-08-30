import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';

class WeekModule {
  final String weekTitle;
  final String description;
  final List<String> topics;
  final List<Map<String, dynamic>> tasks;

  WeekModule({
    required this.weekTitle,
    required this.description,
    required this.topics,
    required this.tasks,
  });
}

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({Key? key}) : super(key: key);

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final List<WeekModule> _roadmap = [
    WeekModule(
      weekTitle: 'Week 1: Data Structures Foundation',
      description: 'Arrays, Strings, HashMaps O(1) Lookups & Two Pointer patterns.',
      topics: ['Arrays', 'Two Pointers', 'Sliding Window', 'HashMaps'],
      tasks: [
        {'title': 'Solve Two Sum & Valid Anagram', 'completed': true},
        {'title': 'Complete 3Sum & Container With Most Water', 'completed': true},
        {'title': 'Review Time & Space Complexities O(N)', 'completed': true},
        {'title': 'Attempt 1 Aptitude Quantitative Assessment', 'completed': false},
      ],
    ),
    WeekModule(
      weekTitle: 'Week 2: Advanced Data Structures',
      description: 'Linked Lists, Stacks, Queues, Binary Trees & BFS/DFS.',
      topics: ['Linked List', 'Stack', 'Trees', 'BFS/DFS'],
      tasks: [
        {'title': 'Reverse Linked List & Merge K Lists', 'completed': true},
        {'title': 'Invert Binary Tree & Max Depth', 'completed': false},
        {'title': 'Take Mock Technical Interview Round 1', 'completed': false},
      ],
    ),
    WeekModule(
      weekTitle: 'Week 3: System Design & Databases',
      description: 'REST APIs, Database Normalization, SQL & Caching (Redis).',
      topics: ['System Design', 'SQL', 'DBMS', 'Caching'],
      tasks: [
        {'title': 'Learn SQL Joins & Indexing', 'completed': false},
        {'title': 'Design URL Shortener System Architecture', 'completed': false},
        {'title': 'Update Resume ATS Keywords', 'completed': false},
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Placement Roadmap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.autorenew),
            tooltip: 'Regenerate Roadmap',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Roadmap regenerated based on target role!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardWidthMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Learning Roadmap', style: theme.textTheme.headlineLarge),
                          const SizedBox(height: 4),
                          Text('Tailored timeline for Software Engineer @ Target Companies', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Regenerate'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Timeline List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _roadmap.length,
                  itemBuilder: (context, index) {
                    final module = _roadmap[index];
                    final completedCount = module.tasks.where((t) => t['completed'] == true).length;
                    final totalCount = module.tasks.length;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        initiallyExpanded: index == 0,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            'W${index + 1}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          ),
                        ),
                        title: Text(
                          module.weekTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('$completedCount/$totalCount tasks completed', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(module.description, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: module.topics.map((t) {
                                    return Chip(
                                      label: Text(t, style: const TextStyle(fontSize: 11, color: Colors.white)),
                                      backgroundColor: const Color(0xFF2B2930),
                                      side: const BorderSide(color: Color(0xFF3A383F), width: 1),
                                    );
                                  }).toList(),
                                ),
                                const Divider(height: 24),
                                ...List.generate(module.tasks.length, (taskIdx) {
                                  final task = module.tasks[taskIdx];
                                  final isDone = task['completed'] as bool;

                                  return CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: theme.colorScheme.primary,
                                    value: isDone,
                                    title: Text(
                                      task['title'],
                                      style: TextStyle(
                                        decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                        color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        task['completed'] = val ?? false;
                                      });
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
