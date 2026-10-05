import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/gamification.dart';
import '../../models/gamification_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/medal_badge_widget.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final myUid = user?.uid ?? '';
    final myPointsAsync = ref.watch(userPointsProvider(myUid));
    final myProfile = ref.watch(profileProvider).value;
    final myName = myProfile?.fullName.isNotEmpty == true ? myProfile!.fullName : 'You';

    return Scaffold(
      backgroundColor: AppColors.bgRoot,
      appBar: AppBar(
        backgroundColor: AppColors.bgRoot,
        title: const Text('Leaderboard 🏆'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentPurpleLight,
          labelColor: AppColors.accentPurpleLight,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'All Time'),
            Tab(text: 'This Week'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab(context, isWeekly: false, myUid: myUid, myName: myName, myPoints: myPointsAsync.value),
          _buildLeaderboardTab(context, isWeekly: true, myUid: myUid, myName: myName, myPoints: myPointsAsync.value),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(
    BuildContext context, {
    required bool isWeekly,
    required String myUid,
    required String myName,
    required UserPoints? myPoints,
  }) {
    final leaderboardAsync = isWeekly
        ? ref.watch(weeklyLeaderboardProvider)
        : ref.watch(leaderboardProvider);

    return leaderboardAsync.when(
      data: (list) {
        // Fallback mock data if Firestore has 0 users
        final displayList = list.isNotEmpty
            ? list
            : [
                UserPoints(
                  uid: myUid.isNotEmpty ? myUid : 'user1',
                  totalPoints: myPoints?.totalPoints ?? 320,
                  weeklyPoints: myPoints?.weeklyPoints ?? 120,
                  weekStartDate: DateTime.now(),
                  codingPoints: 180,
                  aptitudePoints: 90,
                  interviewPoints: 40,
                  resumePoints: 10,
                  updatedAt: DateTime.now(),
                ),
                UserPoints(
                  uid: 'mock2',
                  totalPoints: 280,
                  weeklyPoints: 95,
                  weekStartDate: DateTime.now(),
                  codingPoints: 150,
                  aptitudePoints: 90,
                  interviewPoints: 40,
                  resumePoints: 0,
                  updatedAt: DateTime.now(),
                ),
                UserPoints(
                  uid: 'mock3',
                  totalPoints: 190,
                  weeklyPoints: 70,
                  weekStartDate: DateTime.now(),
                  codingPoints: 100,
                  aptitudePoints: 60,
                  interviewPoints: 30,
                  resumePoints: 0,
                  updatedAt: DateTime.now(),
                ),
              ];

        final currentPts = isWeekly ? (myPoints?.weeklyPoints ?? 0) : (myPoints?.totalPoints ?? 0);
        final currentTier = MedalTier.fromPoints(myPoints?.totalPoints ?? 0);
        final nextPts = currentTier.nextTierMinPoints;
        final nextLabel = currentTier.nextTierLabel;
        final ptsNeeded = (nextPts != null) ? (nextPts - (myPoints?.totalPoints ?? 0)).clamp(0, 9999) : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardWidthMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. PINNED MY RANK CARD
                  Card(
                    color: AppColors.bgSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.accentPurple, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.accentPurple,
                                child: Text(
                                  myName.isNotEmpty ? myName[0].toUpperCase() : 'Y',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          myName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        MedalBadgeWidget(tier: currentTier, isChip: true),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$currentPts ${isWeekly ? "pts this week" : "total points"}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.accentPurpleLight.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Rank #${_findUserRank(displayList, myUid, isWeekly)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (nextPts != null && nextLabel != null) ...[
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: ((myPoints?.totalPoints ?? 0) / nextPts).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: AppColors.bgInput,
                                valueColor: AlwaysStoppedAnimation<Color>(currentTier.color),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$ptsNeeded more points to $nextLabel',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. PODIUM TOP 3 SECTION
                  if (displayList.length >= 3) ...[
                    Text('Top Contenders 🏆', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildPodium(context, displayList, isWeekly),
                    const SizedBox(height: 24),
                  ],

                  // 3. FULL LEADERBOARD LIST
                  Text('Leaderboard Rankings', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Card(
                    color: AppColors.bgSurface,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayList.length > 3 ? displayList.length - 3 : displayList.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderSubtle),
                      itemBuilder: (context, index) {
                        final idx = displayList.length >= 3 ? index + 3 : index;
                        final userPoints = displayList[idx];
                        final rank = idx + 1;
                        final isMe = userPoints.uid == myUid;
                        final pts = isWeekly ? userPoints.weeklyPoints : userPoints.totalPoints;
                        final tier = MedalTier.fromPoints(userPoints.totalPoints);

                        return Container(
                          color: isMe ? AppColors.accentPurple.withValues(alpha: 0.2) : Colors.transparent,
                          child: ListTile(
                            onTap: () => _showPublicProfileModal(context, userPoints, rank, isMe ? myName : 'Candidate #$rank'),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '#$rank',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: rank <= 3 ? tier.color : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.bgSurfaceAlt,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: tier.color, width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        isMe ? (myName.isNotEmpty ? myName[0].toUpperCase() : 'Y') : 'C',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isMe ? '$myName (You)' : 'Candidate #$rank',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                MedalBadgeWidget(tier: tier, isChip: true),
                              ],
                            ),
                            trailing: Text(
                              '$pts pts',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textAccent,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentPurpleLight)),
      error: (err, stack) => Center(child: Text('Error loading leaderboard: $err', style: const TextStyle(color: AppColors.error))),
    );
  }

  Widget _buildPodium(BuildContext context, List<UserPoints> list, bool isWeekly) {
    final first = list[0];
    final second = list.length > 1 ? list[1] : list[0];
    final third = list.length > 2 ? list[2] : list[0];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // #2 Silver
        Expanded(child: _buildPodiumCard(context, second, 2, MedalTier.silver, isWeekly)),
        const SizedBox(width: 8),
        // #1 Gold (Center, Taller)
        Expanded(child: _buildPodiumCard(context, first, 1, MedalTier.gold, isWeekly, isCenter: true)),
        const SizedBox(width: 8),
        // #3 Bronze
        Expanded(child: _buildPodiumCard(context, third, 3, MedalTier.bronze, isWeekly)),
      ],
    );
  }

  Widget _buildPodiumCard(
    BuildContext context,
    UserPoints userPoints,
    int rank,
    MedalTier tier,
    bool isWeekly, {
    bool isCenter = false,
  }) {
    final pts = isWeekly ? userPoints.weeklyPoints : userPoints.totalPoints;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tier.color, width: isCenter ? 2.5 : 1.5),
        boxShadow: isCenter
            ? [
                BoxShadow(
                  color: tier.color.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: isCenter ? 22 : 18,
            backgroundColor: tier.color,
            child: Icon(tier.icon, color: tier.textColor, size: isCenter ? 24 : 18),
          ),
          const SizedBox(height: 8),
          Text(
            '#$rank',
            style: TextStyle(fontWeight: FontWeight.bold, color: tier.color, fontSize: isCenter ? 16 : 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Candidate #$rank',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          MedalBadgeWidget(tier: MedalTier.fromPoints(userPoints.totalPoints), isChip: true),
          const SizedBox(height: 8),
          Text(
            '$pts pts',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textAccent),
          ),
        ],
      ),
    );
  }

  int _findUserRank(List<UserPoints> list, String myUid, bool isWeekly) {
    if (myUid.isEmpty) return 1;
    final idx = list.indexWhere((u) => u.uid == myUid);
    return idx != -1 ? idx + 1 : 1;
  }

  void _showPublicProfileModal(BuildContext context, UserPoints points, int rank, String displayName) {
    final tier = MedalTier.fromPoints(points.totalPoints);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: tier.color,
                  child: Icon(tier.icon, color: tier.textColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          MedalBadgeWidget(tier: tier, isChip: true),
                          const SizedBox(width: 8),
                          Text('Rank #$rank', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: AppColors.borderSubtle),
            const Text('Points Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSourceStat('Coding', '${points.codingPoints}', Icons.code, AppColors.success),
                _buildSourceStat('Aptitude', '${points.aptitudePoints}', Icons.psychology, AppColors.warning),
                _buildSourceStat('Interview', '${points.interviewPoints}', Icons.video_call, AppColors.accentPurpleLight),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceStat(String label, String val, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}
