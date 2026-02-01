import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/spacing.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';

/// Modèle pour une notification
class SocialNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String? userName;
  final DateTime timestamp;
  final bool isRead;

  const SocialNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.userName,
    required this.timestamp,
    this.isRead = false,
  });
}

enum NotificationType {
  respect,
  challenge,
  challengeComplete,
  pr,
  friendRequest,
  friendWorkout,
}

/// Sheet affichant les notifications sociales
class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const NotificationsSheet(),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  // Mock notifications data
  final List<SocialNotification> _notifications = [
    SocialNotification(
      id: '1',
      type: NotificationType.respect,
      title: 'Nouveau respect !',
      message: 'Thomas D. t\'a donné du respect pour ta séance Push Day',
      userName: 'Thomas D.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
    ),
    SocialNotification(
      id: '2',
      type: NotificationType.challenge,
      title: 'Défi mis à jour',
      message: 'Julie M. a atteint 95kg au bench ! Plus que 5kg pour terminer le défi.',
      userName: 'Julie M.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    SocialNotification(
      id: '3',
      type: NotificationType.pr,
      title: 'PR de ton ami !',
      message: 'Marc L. vient de battre son record aux tractions : 25kg !',
      userName: 'Marc L.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    SocialNotification(
      id: '4',
      type: NotificationType.challengeComplete,
      title: 'Défi terminé ! 🏆',
      message: 'Thomas D. a complété le défi "100kg au bench" en premier !',
      userName: 'Thomas D.',
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      isRead: true,
    ),
    SocialNotification(
      id: '5',
      type: NotificationType.respect,
      title: 'Respect x3',
      message: 'Julie, Marc et Sarah t\'ont donné du respect',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    SocialNotification(
      id: '6',
      type: NotificationType.friendWorkout,
      title: 'Séance terminée',
      message: 'Sarah K. vient de terminer une séance Full Body de 45 min',
      userName: 'Sarah K.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    SocialNotification(
      id: '7',
      type: NotificationType.friendRequest,
      title: 'Nouvelle demande d\'ami',
      message: 'Emma R. souhaite devenir ton ami',
      userName: 'Emma R.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.respect:
        return Icons.fitness_center_rounded;
      case NotificationType.challenge:
        return Icons.flag_rounded;
      case NotificationType.challengeComplete:
        return Icons.emoji_events_rounded;
      case NotificationType.pr:
        return Icons.trending_up_rounded;
      case NotificationType.friendRequest:
        return Icons.person_add_rounded;
      case NotificationType.friendWorkout:
        return Icons.directions_run_rounded;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.respect:
        return FGColors.accent;
      case NotificationType.challenge:
        return const Color(0xFF3498DB);
      case NotificationType.challengeComplete:
        return FGColors.warning;
      case NotificationType.pr:
        return FGColors.success;
      case NotificationType.friendRequest:
        return const Color(0xFF9B59B6);
      case NotificationType.friendWorkout:
        return FGColors.textSecondary;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return 'Il y a ${(diff.inDays / 7).floor()} sem';
  }

  void _markAllAsRead() {
    HapticFeedback.lightImpact();
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = SocialNotification(
          id: _notifications[i].id,
          type: _notifications[i].type,
          title: _notifications[i].title,
          message: _notifications[i].message,
          userName: _notifications[i].userName,
          timestamp: _notifications[i].timestamp,
          isRead: true,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Toutes les notifications marquées comme lues'),
        backgroundColor: FGColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: FGColors.glassSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: FGColors.glassBorder,
              width: 1,
            ),
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
                    color: FGColors.textSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Row(
                  children: [
                    Text(
                      'Notifications',
                      style: FGTypography.h3,
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: Spacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: FGColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.textOnAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (unreadCount > 0)
                      GestureDetector(
                        onTap: _markAllAsRead,
                        child: Text(
                          'Tout marquer lu',
                          style: FGTypography.caption.copyWith(
                            color: FGColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // List
              Expanded(
                child: _notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: Spacing.sm),
                            child: _buildNotificationCard(notification),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: FGColors.glassBorder,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: FGColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Aucune notification',
            style: FGTypography.body.copyWith(
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Tu seras notifié des activités de tes amis',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(SocialNotification notification) {
    final color = _getColorForType(notification.type);
    final icon = _getIconForType(notification.type);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Mark as read and handle tap
        setState(() {
          final index = _notifications.indexOf(notification);
          if (index != -1) {
            _notifications[index] = SocialNotification(
              id: notification.id,
              type: notification.type,
              title: notification.title,
              message: notification.message,
              userName: notification.userName,
              timestamp: notification.timestamp,
              isRead: true,
            );
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: notification.isRead
              ? FGColors.background.withValues(alpha: 0.5)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: notification.isRead
                ? FGColors.glassBorder
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: notification.isRead ? 0.1 : 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: notification.isRead
                    ? color.withValues(alpha: 0.6)
                    : color,
                size: 20,
              ),
            ),
            const SizedBox(width: Spacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: FGTypography.body.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: notification.isRead
                                ? FGColors.textSecondary
                                : FGColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    _formatTimeAgo(notification.timestamp),
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
