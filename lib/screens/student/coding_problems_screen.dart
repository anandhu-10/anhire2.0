import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/coding_problem_model.dart';
import '../../providers/coding_provider.dart';

class CodingProblemsScreen extends ConsumerStatefulWidget {
  const CodingProblemsScreen({super.key});

  @override
  ConsumerState<CodingProblemsScreen> createState() => _CodingProblemsScreenState();
}

class _CodingProblemsScreenState extends ConsumerState<CodingProblemsScreen> {
  String _selectedDifficulty = 'All';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'arrays',
    'strings',
    'math',
    'sorting',
    'hashing',
    'recursion',
    'dynamic programming',
    'graphs',
    'greedy',
    'two pointers',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compactBreakpoint;

    final problemsAsync = ref.watch(codingProblemsProvider);
    final submissionsAsync = ref.watch(userSubmissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coding Practice'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(codingProblemsProvider);
          ref.invalidate(userSubmissionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header & Search Bar
                  Text('Coding Practice', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Solve real-world algorithmic problems to prepare for technical interviews',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by problem title or category...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Difficulty Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Easy', 'Medium', 'Hard'].map((diff) {
                        final isSel = _selectedDifficulty == diff;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              diff,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: const Color(0xFF6750A4),
                            backgroundColor: const Color(0xFF2B2930),
                            side: BorderSide(
                              color: isSel ? const Color(0xFF6750A4) : const Color(0xFF3A383F),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (sel) {
                              if (sel) setState(() => _selectedDifficulty = diff);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSel = _selectedCategory.toLowerCase() == cat.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: FilterChip(
                            label: Text(
                              cat == 'All' ? 'All Categories' : cat.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: const Color(0xFF6750A4),
                            backgroundColor: const Color(0xFF2B2930),
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSel ? const Color(0xFF6750A4) : const Color(0xFF3A383F),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (sel) {
                              setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Content Body with Firestore State
                  problemsAsync.when(
                    data: (problems) {
                      final submissions = submissionsAsync.value ?? [];

                      // Calculate solved / attempted counts
                      int solvedCount = 0;
                      int attemptedCount = 0;

                      final Map<String, String> statusMap = {};
                      for (final p in problems) {
                        final pSubmissions = submissions.where((s) => s.problemId == p.id);
                        if (pSubmissions.any((s) => s.passed)) {
                          statusMap[p.id] = 'solved';
                          solvedCount++;
                        } else if (pSubmissions.isNotEmpty) {
                          statusMap[p.id] = 'attempted';
                          attemptedCount++;
                        } else {
                          statusMap[p.id] = 'unsolved';
                        }
                      }

                      // Apply Filters
                      final filtered = problems.where((p) {
                        final matchesDiff = _selectedDifficulty == 'All' ||
                            p.difficulty.toLowerCase() == _selectedDifficulty.toLowerCase();
                        final matchesCat = _selectedCategory == 'All' ||
                            p.category.toLowerCase() == _selectedCategory.toLowerCase();
                        final matchesSearch = _searchQuery.isEmpty ||
                            p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            p.category.toLowerCase().contains(_searchQuery.toLowerCase());
                        return matchesDiff && matchesCat && matchesSearch;
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Counter Header
                          Card(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatCount(context, '${problems.length}', 'Total'),
                                  const SizedBox(width: 8),
                                  _buildStatCount(context, '$solvedCount', 'Solved', Colors.green),
                                  const SizedBox(width: 8),
                                  _buildStatCount(context, '$attemptedCount', 'Attempted', Colors.orange),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            '${filtered.length} Problems Found',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          if (filtered.isEmpty) ...[
                            const SizedBox(height: 40),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text('No problems found', style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Try adjusting your search or category filters',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (isCompact) ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final problem = filtered[index];
                                return _buildProblemCard(
                                  context,
                                  problem,
                                  statusMap[problem.id] ?? 'unsolved',
                                );
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
                                mainAxisExtent: 95,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final problem = filtered[index];
                                return _buildProblemCard(
                                  context,
                                  problem,
                                  statusMap[problem.id] ?? 'unsolved',
                                );
                              },
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => _buildShimmerLoading(),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text('Error loading problems: $err'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCount(BuildContext context, String count, String label, [Color? color]) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildProblemCard(BuildContext context, CodingProblemModel problem, String status) {
    return Card(
      child: ListTile(
        onTap: () => context.go('/coding-playground/${problem.id}'),
        leading: _buildStatusIcon(status),
        title: Text(
          problem.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            problem.category.toUpperCase(),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyBadge(problem.difficulty),
            const SizedBox(width: 4),
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
        child: Icon(Icons.check_circle, color: Colors.green, size: 18),
      );
    } else if (status == 'attempted') {
      return const CircleAvatar(
        radius: 14,
        backgroundColor: Color(0xFFFFF3E0),
        child: Icon(Icons.circle, color: Colors.orange, size: 14),
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
    final dLower = difficulty.toLowerCase();
    if (dLower == 'medium') color = Colors.orange;
    if (dLower == 'hard') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(6, (idx) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),
      ),
    );
  }
}
