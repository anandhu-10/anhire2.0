import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compactBreakpoint;

    final problemsAsync = ref.watch(codingProblemsProvider);
    final submissionsAsync = ref.watch(userSubmissionsProvider);

    return Scaffold(
      backgroundColor: context.appRootBg,
      appBar: AppBar(
        title: Text(
          'Coding Practice Hub',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(codingProblemsProvider);
          ref.invalidate(userSubmissionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
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
                    style: GoogleFonts.inter(
                      fontSize: isCompact ? 22 : 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Master essential Data Structures & Algorithms patterns asked by top tech recruiters',
                    style: GoogleFonts.inter(
                      color: context.appTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  TextField(
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    style: GoogleFonts.inter(
                      color: context.appTextPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Search by problem title, category, or algorithm pattern...',
                      hintStyle: GoogleFonts.inter(
                        color: context.appTextMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: context.appTextMuted,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: context.appTextMuted,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: context.appSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.appBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.appBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
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
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSel
                                  ? (isDark ? Colors.white : AppColors.primary)
                                  : context.appTextSecondary,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.primary.withValues(
                            alpha: isDark ? 0.25 : 0.12,
                          ),
                          backgroundColor: context.appSurface,
                          side: BorderSide(
                            color: isSel
                                ? AppColors.primary
                                : context.appBorder,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: AppColors.success,
                                )
                              : (st == 'Unsolved'
                                    ? Icon(
                                        Icons.radio_button_unchecked,
                                        size: 14,
                                        color: context.appTextMuted,
                                      )
                                    : null),
                          label: Text(
                            st == 'All' ? 'All Status' : st,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSel
                                  ? (isDark ? Colors.white : AppColors.primary)
                                  : context.appTextSecondary,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.primary.withValues(
                            alpha: isDark ? 0.25 : 0.12,
                          ),
                          backgroundColor: context.appSurface,
                          side: BorderSide(
                            color: isSel
                                ? AppColors.primary
                                : context.appBorder,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSel
                                    ? Colors.white
                                    : context.appTextSecondary,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            backgroundColor: context.appSurface,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSel
                                  ? AppColors.primary
                                  : context.appBorder,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                            context: context,
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
                                style: GoogleFonts.inter(
                                  color: context.appTextPrimary,
                                  fontWeight: FontWeight.w700,
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
                                  child: Text(
                                    'Reset Filters',
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
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
                                    Icons.search_off_rounded,
                                    size: 52,
                                    color: context.appTextMuted,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No matching coding problems found',
                                    style: GoogleFonts.inter(
                                      color: context.appTextPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Try adjusting your search criteria or resetting the difficulty and topic filters.',
                                    style: GoogleFonts.inter(
                                      color: context.appTextSecondary,
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
                    loading: () => _buildShimmerLoading(context),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Error loading problems: $err',
                          style: GoogleFonts.inter(color: AppColors.error),
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
    required BuildContext context,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.2 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Practice Progress',
                    style: GoogleFonts.inter(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.2 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$solvedCount of $totalProblems Solved (${(completionPercent * 100).toStringAsFixed(1)}%)',
                  style: GoogleFonts.inter(
                    color: isDark ? AppColors.accent : AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completionPercent,
              minHeight: 8,
              backgroundColor: context.appSurfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
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
                context,
                'Easy',
                easySolved,
                easyTotal,
                AppColors.success,
              ),
              _buildDifficultyProgressPill(
                context,
                'Medium',
                medSolved,
                medTotal,
                AppColors.warning,
              ),
              _buildDifficultyProgressPill(
                context,
                'Hard',
                hardSolved,
                hardTotal,
                AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyProgressPill(
    BuildContext context,
    String label,
    int solved,
    int total,
    Color color,
  ) {
    final pct = total == 0 ? 0.0 : (solved / total);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
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
                style: GoogleFonts.inter(
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w700,
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
                    backgroundColor: context.appSurface,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color borderColor = context.appBorder;
    if (isSolved) {
      borderColor = AppColors.success.withValues(alpha: 0.5);
    } else if (isAttempted) {
      borderColor = AppColors.warning.withValues(alpha: 0.5);
    }

    return InkWell(
      onTap: () => context.go('/coding-playground/${problem.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isSolved || isAttempted ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status Icon Avatar
            _buildStatusIcon(context, status),
            const SizedBox(width: 14),

            // Problem Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    problem.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: context.appTextPrimary,
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
                          color: context.appSurfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          problem.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: context.appTextSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Supported Languages Indicator
                      Text(
                        'Python • Java',
                        style: GoogleFonts.inter(
                          color: context.appTextMuted,
                          fontSize: 11,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSolved ? 'Review' : 'Solve',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isSolved ? AppColors.success : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: isSolved ? AppColors.success : AppColors.primary,
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

  Widget _buildStatusIcon(BuildContext context, String status) {
    if (status == 'solved') {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 20,
        ),
      );
    } else if (status == 'attempted') {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.pending_rounded,
          color: AppColors.warning,
          size: 20,
        ),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.radio_button_unchecked,
        color: context.appTextMuted,
        size: 18,
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color = AppColors.success;
    final dLower = difficulty.toLowerCase();
    if (dLower == 'medium') color = AppColors.warning;
    if (dLower == 'hard') color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF15151E) : const Color(0xFFE5E4EF),
      highlightColor: isDark
          ? const Color(0xFF1B1B27)
          : const Color(0xFFF7F7FC),
      child: Column(
        children: List.generate(6, (idx) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          );
        }),
      ),
    );
  }
}
