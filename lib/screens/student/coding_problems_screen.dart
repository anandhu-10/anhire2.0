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
  ConsumerState<CodingProblemsScreen> createState() =>
      _CodingProblemsScreenState();
}

class _CodingProblemsScreenState extends ConsumerState<CodingProblemsScreen> {
  String _selectedDifficulty = 'All';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All'; // 'All', 'Solved', 'Unsolved'
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
      backgroundColor: AppColors.bgRoot,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: const Text(
          'Coding Practice Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.accentPurple,
        onRefresh: () async {
          ref.invalidate(codingProblemsProvider);
          ref.invalidate(userSubmissionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  Text(
                    'Algorithmic Practice Playground',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Master essential Data Structures & Algorithms patterns asked by top tech companies',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  TextField(
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          'Search by problem title, category, or difficulty...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderSubtle,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.accentPurple,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips: Difficulty & Status
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Difficulty Filter Chips
                      ...['All', 'Easy', 'Medium', 'Hard'].map((diff) {
                        final isSel = _selectedDifficulty == diff;
                        return ChoiceChip(
                          label: Text(
                            diff,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSel
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.accentPurple,
                          backgroundColor: AppColors.bgCard,
                          side: BorderSide(
                            color: isSel
                                ? AppColors.accentPurple
                                : AppColors.borderSubtle,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (sel) {
                            if (sel) setState(() => _selectedDifficulty = diff);
                          },
                        );
                      }),

                      const SizedBox(width: 8),

                      // Status Filter Chips (All, Solved, Unsolved)
                      ...['All', 'Solved', 'Unsolved'].map((st) {
                        final isSel = _selectedStatus == st;
                        return ChoiceChip(
                          avatar: st == 'Solved'
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.green,
                                )
                              : (st == 'Unsolved'
                                    ? const Icon(
                                        Icons.radio_button_unchecked,
                                        size: 14,
                                        color: AppColors.textMuted,
                                      )
                                    : null),
                          label: Text(
                            st == 'All' ? 'All Status' : st,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSel
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.bgSurfaceAlt,
                          backgroundColor: AppColors.bgCard,
                          side: BorderSide(
                            color: isSel
                                ? AppColors.accentPurpleLight
                                : AppColors.borderSubtle,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (sel) {
                            if (sel) setState(() => _selectedStatus = st);
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Chips (Horizontal Scroll)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSel =
                            _selectedCategory.toLowerCase() ==
                            cat.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: FilterChip(
                            label: Text(
                              cat == 'All' ? 'ALL TOPICS' : cat.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSel
                                    ? Colors.white
                                    : AppColors.textMuted,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: AppColors.accentPurple,
                            backgroundColor: AppColors.bgCard,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSel
                                  ? AppColors.accentPurple
                                  : AppColors.borderSubtle,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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

                  // Problem List Content with Stream State
                  problemsAsync.when(
                    data: (problems) {
                      final submissions = submissionsAsync.value ?? [];

                      // Calculate solved and attempted status map
                      int solvedCount = 0;
                      int attemptedCount = 0;

                      int easyTotal = 0;
                      int easySolved = 0;
                      int medTotal = 0;
                      int medSolved = 0;
                      int hardTotal = 0;
                      int hardSolved = 0;

                      final Map<String, String> statusMap = {};
                      for (final p in problems) {
                        final diff = p.difficulty.toLowerCase();
                        if (diff == 'hard') {
                          hardTotal++;
                        } else if (diff == 'medium') {
                          medTotal++;
                        } else {
                          easyTotal++;
                        }

                        final pSubmissions = submissions.where(
                          (s) => s.problemId == p.id,
                        );
                        if (pSubmissions.any((s) => s.passed)) {
                          statusMap[p.id] = 'solved';
                          solvedCount++;
                          if (diff == 'hard') {
                            hardSolved++;
                          } else if (diff == 'medium') {
                            medSolved++;
                          } else {
                            easySolved++;
                          }
                        } else if (pSubmissions.isNotEmpty) {
                          statusMap[p.id] = 'attempted';
                          attemptedCount++;
                        } else {
                          statusMap[p.id] = 'unsolved';
                        }
                      }

                      // Apply Filters
                      final filtered = problems.where((p) {
                        final matchesDiff =
                            _selectedDifficulty == 'All' ||
                            p.difficulty.toLowerCase() ==
                                _selectedDifficulty.toLowerCase();
                        final matchesCat =
                            _selectedCategory == 'All' ||
                            p.category.toLowerCase() ==
                                _selectedCategory.toLowerCase();
                        final status = statusMap[p.id] ?? 'unsolved';
                        final matchesStatus =
                            _selectedStatus == 'All' ||
                            (_selectedStatus == 'Solved' &&
                                status == 'solved') ||
                            (_selectedStatus == 'Unsolved' &&
                                status != 'solved');
                        final matchesSearch =
                            _searchQuery.isEmpty ||
                            p.title.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            p.category.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            );
                        return matchesDiff &&
                            matchesCat &&
                            matchesStatus &&
                            matchesSearch;
                      }).toList();

                      final completionPercent = problems.isEmpty
                          ? 0.0
                          : (solvedCount / problems.length);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress & Analytics Dashboard Card
                          _buildProgressAnalyticsCard(
                            totalProblems: problems.length,
                            solvedCount: solvedCount,
                            attemptedCount: attemptedCount,
                            completionPercent: completionPercent,
                            easySolved: easySolved,
                            easyTotal: easyTotal,
                            medSolved: medSolved,
                            medTotal: medTotal,
                            hardSolved: hardSolved,
                            hardTotal: hardTotal,
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filtered.length} Challenges Available',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (_selectedDifficulty != 'All' ||
                                  _selectedCategory != 'All' ||
                                  _selectedStatus != 'All' ||
                                  _searchQuery.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDifficulty = 'All';
                                      _selectedCategory = 'All';
                                      _selectedStatus = 'All';
                                      _searchQuery = '';
                                    });
                                  },
                                  child: const Text(
                                    'Reset Filters',
                                    style: TextStyle(
                                      color: AppColors.accentPurpleLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (filtered.isEmpty) ...[
                            const SizedBox(height: 40),
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 56,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No matching coding problems found',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Try adjusting your search criteria or resetting the difficulty and topic filters.',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (isCompact) ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
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
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    mainAxisExtent: 110,
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
                        child: Text(
                          'Error loading problems: $err',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
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

  // --- PROGRESS & ANALYTICS CARD ---
  Widget _buildProgressAnalyticsCard({
    required int totalProblems,
    required int solvedCount,
    required int attemptedCount,
    required double completionPercent,
    required int easySolved,
    required int easyTotal,
    required int medSolved,
    required int medTotal,
    required int hardSolved,
    required int hardTotal,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.code,
                    color: AppColors.accentPurpleLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Practice Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Text(
                '$solvedCount of $totalProblems Solved (${(completionPercent * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(
                  color: AppColors.accentPurpleLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completionPercent,
              minHeight: 8,
              backgroundColor: AppColors.bgCard,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentPurple,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Difficulty Breakdown Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildDifficultyProgressPill(
                'Easy',
                easySolved,
                easyTotal,
                Colors.green,
              ),
              _buildDifficultyProgressPill(
                'Medium',
                medSolved,
                medTotal,
                Colors.orange,
              ),
              _buildDifficultyProgressPill(
                'Hard',
                hardSolved,
                hardTotal,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyProgressPill(
    String label,
    int solved,
    int total,
    Color color,
  ) {
    final pct = total == 0 ? 0.0 : (solved / total);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: $solved / $total',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: AppColors.bgSurfaceAlt,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- PROBLEM CARD ---
  Widget _buildProblemCard(
    BuildContext context,
    CodingProblemModel problem,
    String status,
  ) {
    final isSolved = status == 'solved';
    final isAttempted = status == 'attempted';

    return InkWell(
      onTap: () => context.go('/coding-playground/${problem.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSolved
                ? Colors.green.withValues(alpha: 0.4)
                : (isAttempted
                      ? Colors.orange.withValues(alpha: 0.4)
                      : AppColors.borderSubtle),
            width: isSolved || isAttempted ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Status Icon Avatar
            _buildStatusIcon(status),
            const SizedBox(width: 12),

            // Problem Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    problem.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          problem.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Supported Languages Indicator
                      const Text(
                        'Python • Java',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Difficulty Chip & Action Arrow
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildDifficultyBadge(problem.difficulty),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      isSolved ? 'Review' : 'Solve',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSolved
                            ? Colors.green
                            : AppColors.accentPurpleLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'solved') {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
      );
    } else if (status == 'attempted') {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.pending, color: Colors.orange, size: 20),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.radio_button_unchecked,
        color: AppColors.textMuted,
        size: 18,
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color = Colors.green;
    final dLower = difficulty.toLowerCase();
    if (dLower == 'medium') color = Colors.orange;
    if (dLower == 'hard') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.bgCard,
      highlightColor: AppColors.bgSurfaceAlt,
      child: Column(
        children: List.generate(6, (idx) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 90,
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
