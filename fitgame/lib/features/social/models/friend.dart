/// Model for a friend in the social feature
class Friend {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final DateTime? lastActive;
  final int totalWorkouts;
  final int streak;

  const Friend({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    this.lastActive,
    required this.totalWorkouts,
    required this.streak,
  });

  String get lastActiveText {
    if (isOnline) return 'En ligne';
    if (lastActive == null) return '';

    final diff = DateTime.now().difference(lastActive!);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return 'Il y a ${(diff.inDays / 7).floor()}sem';
  }
}
