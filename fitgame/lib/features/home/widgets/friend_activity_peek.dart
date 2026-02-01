import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';

class FriendActivityPeek extends StatelessWidget {
  final VoidCallback? onTap;

  // Mock data - TODO: Replace with real data
  final List<_FriendActivity> _activities = const [
    _FriendActivity(
      name: 'Thomas D.',
      initial: 'T',
      workout: 'Push Day',
      timeAgo: 'il y a 2h',
      color: Color(0xFF6366F1),
    ),
    _FriendActivity(
      name: 'Julie M.',
      initial: 'J',
      workout: 'Leg Day',
      timeAgo: 'il y a 5h',
      color: Color(0xFFEC4899),
    ),
  ];

  const FriendActivityPeek({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            ..._activities.map((activity) => Padding(
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
