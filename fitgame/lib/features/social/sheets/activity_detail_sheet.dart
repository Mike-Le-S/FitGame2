import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../models/activity.dart';
import '../widgets/pr_badge.dart';
import '../widgets/respect_button.dart';

/// Bottom sheet showing full activity details
class ActivityDetailSheet extends StatelessWidget {
  const ActivityDetailSheet({
    super.key,
    required this.activity,
    required this.onRespect,
  });

  final Activity activity;
  final VoidCallback onRespect;

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    return 'il y a ${(diff.inDays / 7).floor()}sem';
  }

  String _formatVolume(double volumeKg) {
    if (volumeKg >= 1000) {
      return '${(volumeKg / 1000).toStringAsFixed(1)}t';
    }
    return '${volumeKg.toStringAsFixed(0)}kg';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: FGColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: Spacing.lg),

                  // PR Badge
                  if (activity.pr != null) ...[
                    PRBadge(pr: activity.pr!),
                    const SizedBox(height: Spacing.lg),
                  ],

                  // Stats Grid
                  _buildStatsGrid(),
                  const SizedBox(height: Spacing.lg),

                  // All Exercises
                  _buildExercisesSection(),
                  const SizedBox(height: Spacing.lg),

                  // Respect Section
                  _buildRespectSection(),
                  const SizedBox(height: Spacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                FGColors.accent,
                FGColors.accent.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipOval(
            child: activity.userAvatarUrl.isNotEmpty
                ? Image.network(
                    activity.userAvatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildInitials(),
                  )
                : _buildInitials(),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.userName,
                style: FGTypography.h3.copyWith(
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                activity.workoutName,
                style: FGTypography.body.copyWith(
                  color: FGColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTimeAgo(activity.timestamp),
                style: FGTypography.caption.copyWith(
                  color: FGColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitials() {
    final initials = activity.userName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    return Center(
      child: Text(
        initials,
        style: FGTypography.h3.copyWith(
          color: FGColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FGColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatItem('Durée', '${activity.durationMinutes} min', Icons.timer_outlined)),
              Expanded(child: _buildStatItem('Volume', _formatVolume(activity.volumeKg), Icons.fitness_center)),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(child: _buildStatItem('Exercices', '${activity.exerciseCount}', Icons.format_list_numbered)),
              Expanded(child: _buildStatItem('Muscles', activity.muscles.split(' • ').length.toString(), Icons.accessibility_new)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: FGColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: FGColors.accent,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: FGTypography.body.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExercisesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXERCICES',
          style: FGTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.md),
        ...activity.topExercises.map((exercise) => Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: _buildExerciseRow(exercise),
        )),
      ],
    );
  }

  Widget _buildExerciseRow(ExerciseSummary exercise) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FGColors.glassBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              exercise.name,
              style: FGTypography.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            exercise.display,
            style: FGTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: FGColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRespectSection() {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FGColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fitness_center,
                size: 20,
                color: FGColors.accent,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '${activity.respectCount} respect',
                style: FGTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              RespectButton(
                count: activity.respectCount,
                hasGivenRespect: activity.hasGivenRespect,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onRespect();
                },
              ),
            ],
          ),
          if (activity.respectGivers.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              activity.respectGivers.take(3).join(', ') +
                  (activity.respectGivers.length > 3
                      ? ' et ${activity.respectGivers.length - 3} autres'
                      : ''),
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
