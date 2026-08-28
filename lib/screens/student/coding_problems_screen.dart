import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';

class CodingProblem {
  final String id;
  final String title;
  final String difficulty; // Easy, Medium, Hard
  final String category;
  final String status; // solved, attempted, unsolved

  CodingProblem({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.category,
    required this.status,
  });
}

class CodingProblemsScreen extends StatefulWidget {
  const CodingProblemsScreen({Key? key}) : super(key: key);

  @override
  State<CodingProblemsScreen> createState() => _CodingProblemsScreenState();
}

class _CodingProblemsScreenState extends State<CodingProblemsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<CodingProblem> _allProblems = [
    CodingProblem(id: 'two-sum', title: 'Two Sum', difficulty: 'Easy', category: 'Arrays & Hashing', status: 'unsolved'),
    CodingProblem(id: 'valid-anagram', title: 'Valid Anagram', difficulty: 'Easy', category: 'Arrays & Hashing', status: 'unsolved'),
    CodingProblem(id: 'reverse-linked-list', title: 'Reverse Linked List', difficulty: 'Easy', category: 'Linked List', status: 'unsolved'),
    CodingProblem(id: 'three-sum', title: '3Sum', difficulty: 'Medium', category: 'Two Pointers', status: 'unsolved'),
    CodingProblem(id: 'container-water', title: 'Container With Most Water', difficulty: 'Medium', category: 'Two Pointers', status: 'unsolved'),
    CodingProblem(id: 'longest-substring', title: 'Longest Substring Without Repeating Characters', difficulty: 'Medium', category: 'Sliding Window', status: 'unsolved'),
    CodingProblem(id: 'merge-k-lists', title: 'Merge k Sorted Lists', difficulty: 'Hard', category: 'Linked List', status: 'unsolved'),
    CodingProblem(id: 'trapping-rain-water', title: 'Trapping Rain Water', difficulty: 'Hard', category: 'Two Pointers', status: 'unsolved'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compactBreakpoint;

    final filteredProblems = _allProblems.where((p) {
      final matchesFilter = _selectedFilter == 'All' || p.difficulty.toLowerCase() == _selectedFilter.toLowerCase();
      final matchesSearch = p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coding Practice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Search
                Text('Coding Problems', style: theme.textTheme.headlineLarge),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Search problem or category...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),

                // Horizontally Scrollable Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Easy', 'Medium', 'Hard'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (sel) {
                            if (sel) setState(() => _selectedFilter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Problem Count Header
                Text(
                  '${filteredProblems.length} Problems Found',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Problem Cards List (1 column on Compact, 2 columns on Medium/Expanded)
                if (isCompact) ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredProblems.length,
                    itemBuilder: (context, index) {
                      return _buildProblemTile(context, filteredProblems[index]);
                    },
                  ),
                ] else ...[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 90,
                    ),
                    itemCount: filteredProblems.length,
                    itemBuilder: (context, index) {
                      return _buildProblemTile(context, filteredProblems[index]);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProblemTile(BuildContext context, CodingProblem problem) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        minVerticalPadding: 16,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () => context.go('/coding-playground/${problem.id}'),
        leading: _buildStatusIcon(problem.status),
        title: Text(
          problem.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(problem.category, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyBadge(problem.difficulty),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'solved') {
      return const CircleAvatar(
        radius: 14,
        backgroundColor: Color(0xFFE8F5E9),
        child: Icon(Icons.check, color: Colors.green, size: 16),
      );
    } else if (status == 'attempted') {
      return const CircleAvatar(
        radius: 14,
        backgroundColor: Color(0xFFFFF3E0),
        child: Icon(Icons.schedule, color: Colors.orange, size: 16),
      );
    }
    return const CircleAvatar(
      radius: 14,
      backgroundColor: Color(0xFFF5F5F5),
      child: Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 16),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color = Colors.green;
    if (difficulty == 'Medium') color = Colors.orange;
    if (difficulty == 'Hard') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        difficulty,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
