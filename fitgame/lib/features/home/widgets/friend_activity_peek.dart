import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';

class FriendActivityPeek extends StatelessWidget {
  final VoidCallback? onTap;
  final List<Map<String, dynamic>> activities;

  const FriendActivityPeek({
    super.key,
    this.onTap,
    this.activities = const [],
  });

  static String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    final friendActivities = activities.map((a) {
      final name = (a['user']?['full_name'] ?? 'Ami').toString();
      return _FriendActivity(
        name: name,
        initial: name.isNotEmpty ? name[0].toUpperCase() : '?',
        workout: (a['title'] ?? '').toString(),
        timeAgo: _formatTimeAgo(
          DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now(),
        ),
        color: FGColors.accent,
      );
    }).take(3).toList();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: FGGlassCard(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Text(
                  '👥',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'ACTIVITÉ',
                  style: FGTypography.caption.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: FGColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'VOIR',
                  style: FGTypography.caption.copyWith(
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: FGColors.accent,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: FGColors.accent,
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),

            // Activity list
            ...friendActivities.map((activity) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: _buildActivityRow(activity),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(_FriendActivity activity) {
    return Row(
      children: [
        // Mini avatar
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activity.color.withValues(alpha: 0.2),
            border: Border.all(
              color: activity.color.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              activity.initial,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: activity.color,
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),

        // Name and workout
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.name,
                style: FGTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: FGColors.textPrimary,
                ),
              ),
              Text(
                activity.workout,
                style: FGTypography.caption.copyWith(
                  fontSize: 11,
                  color: FGColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Time ago
        Text(
          activity.timeAgo,
          style: FGTypography.caption.copyWith(
            fontSize: 10,
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FriendActivity {
  final String name;
  final String initial;
  final String workout;
  final String timeAgo;
  final Color color;

  const _FriendActivity({
    required this.name,
    required this.initial,
    required this.workout,
    required this.timeAgo,
    required this.color,
  });
}
