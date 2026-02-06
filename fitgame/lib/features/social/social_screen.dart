import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/supabase_service.dart';
import 'models/activity.dart';
import 'models/challenge.dart';
import 'models/friend.dart';
import 'widgets/activity_card.dart';
import 'widgets/challenge_card.dart';
import 'sheets/activity_detail_sheet.dart';
import 'sheets/challenge_detail_sheet.dart';
import 'sheets/create_challenge_sheet.dart';
import 'sheets/notifications_sheet.dart';
import '../../shared/widgets/fg_mesh_gradient.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _selectedTab = 0; // 0 = Feed, 1 = Défis

  // Data from Supabase
  List<Activity> _activities = [];
  List<Challenge> _challenges = [];
  List<Friend> _friends = [];
  int _unreadNotifications = 0;
  bool _isLoading = true;

  // Current user info
  String _currentUserId = '';
  String _currentUserName = 'Toi';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.05, end: 0.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadSocialData();
  }

  Future<void> _loadSocialData() async {
    try {
      // Load current user info
      final userId = SupabaseService.currentUser?.id ?? '';
      final profile = await SupabaseService.getCurrentProfile();
      final userName = profile?['full_name'] ?? 'Toi';

      // Load activity feed from Supabase
      final activityData = await SupabaseService.getActivityFeed();
      final friendsData = await SupabaseService.getFriends();
      final unreadCount = await SupabaseService.getUnreadNotificationsCount();

      if (mounted) {
        setState(() {
          // Set current user info
          _currentUserId = userId;
          _currentUserName = userName;

          // Convert Supabase data to Activity models
          _activities = activityData.map((data) {
            final user = data['user'] as Map<String, dynamic>?;
            final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

            return Activity(
              id: data['id'] ?? '',
              userName: user?['full_name'] ?? 'Utilisateur',
              userAvatarUrl: user?['avatar_url'] ?? '',
              workoutName: data['title'] ?? '',
              muscles: metadata['muscles'] ?? '',
              durationMinutes: metadata['duration_minutes'] ?? 0,
              volumeKg: (metadata['volume_kg'] ?? 0).toDouble(),
              exerciseCount: metadata['exercise_count'] ?? 0,
              timestamp: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
              topExercises: [],
              respectCount: 0,
              hasGivenRespect: false,
              respectGivers: [],
            );
          }).toList();

          // Convert friends data
          _friends = friendsData.map((data) {
            final friend = data['friend'] as Map<String, dynamic>?;
            return Friend(
              id: friend?['id'] ?? '',
              name: friend?['full_name'] ?? 'Ami',
              avatarUrl: friend?['avatar_url'] ?? '',
              isOnline: false,
              streak: friend?['current_streak'] ?? 0,
              totalWorkouts: friend?['total_sessions'] ?? 0,
              lastActive: DateTime.now(),
            );
          }).toList();

          _unreadNotifications = unreadCount;
          _isLoading = false;
        });

        // Fetch which activities I've respected (after setState)
        final activityIds = _activities.map((a) => a.id).where((id) => id.isNotEmpty).toList();
        if (activityIds.isNotEmpty) {
          try {
            final myRespects = await SupabaseService.getMyRespects(activityIds);
            if (mounted) {
              setState(() {
                _activities = _activities.map((a) {
                  final respectedData = activityData.firstWhere(
                    (d) => d['id'] == a.id,
                    orElse: () => <String, dynamic>{},
                  );
                  return Activity(
                    id: a.id,
                    userName: a.userName,
                    userAvatarUrl: a.userAvatarUrl,
                    workoutName: a.workoutName,
                    muscles: a.muscles,
                    durationMinutes: a.durationMinutes,
                    volumeKg: a.volumeKg,
                    exerciseCount: a.exerciseCount,
                    timestamp: a.timestamp,
                    topExercises: a.topExercises,
                    respectCount: respectedData['respect_count'] as int? ?? 0,
                    hasGivenRespect: myRespects.contains(a.id),
                    respectGivers: a.respectGivers,
                  );
                }).toList();
              });
            }
          } catch (e) {
            debugPrint('Error fetching respects: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onRespect(String activityId) async {
    try {
      final result = await SupabaseService.toggleRespect(activityId);
      final newCount = result['respect_count'] as int? ?? 0;
      final action = result['action'] as String? ?? 'added';

      setState(() {
        final index = _activities.indexWhere((a) => a.id == activityId);
        if (index != -1) {
          final activity = _activities[index];
          _activities[index] = Activity(
            id: activity.id,
            userName: activity.userName,
            userAvatarUrl: activity.userAvatarUrl,
            workoutName: activity.workoutName,
            muscles: activity.muscles,
            durationMinutes: activity.durationMinutes,
            volumeKg: activity.volumeKg,
            exerciseCount: activity.exerciseCount,
            timestamp: activity.timestamp,
            topExercises: activity.topExercises,
            pr: activity.pr,
            respectCount: newCount,
            hasGivenRespect: action == 'added',
            respectGivers: activity.respectGivers,
          );
        }
      });
    } catch (e) {
      debugPrint('Error toggling respect: $e');
    }
  }

  void _openActivityDetail(Activity activity) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ActivityDetailSheet(
        activity: activity,
        onRespect: () => _onRespect(activity.id),
      ),
    );
  }

  void _openChallengeDetail(Challenge challenge) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ChallengeDetailSheet(
        challenge: challenge,
        onParticipate: () {
          _participateInChallenge(challenge);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _participateInChallenge(Challenge challenge) async {
    HapticFeedback.mediumImpact();
    // Check if already participating
    final isParticipating = challenge.participants.any((p) => p.id == _currentUserId);
    if (isParticipating) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tu participes déjà à ce défi !'),
          backgroundColor: FGColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      // Save to Supabase
      await SupabaseService.joinChallenge(challenge.id);

      if (mounted) {
        setState(() {
          final index = _challenges.indexWhere((c) => c.id == challenge.id);
          if (index != -1) {
            final updatedParticipants = [
              ...challenge.participants,
              ChallengeParticipant(
                id: _currentUserId,
                name: _currentUserName,
                avatarUrl: '',
                currentValue: 0,
                hasCompleted: false,
              ),
            ];
            _challenges[index] = Challenge(
              id: challenge.id,
              title: challenge.title,
              exerciseName: challenge.exerciseName,
              type: challenge.type,
              targetValue: challenge.targetValue,
              unit: challenge.unit,
              deadline: challenge.deadline,
              status: challenge.status,
              creatorId: challenge.creatorId,
              creatorName: challenge.creatorName,
              participants: updatedParticipants,
              createdAt: challenge.createdAt,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tu participes maintenant au défi "${challenge.title}" !'),
            backgroundColor: FGColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error joining challenge: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de l\'inscription au défi'),
            backgroundColor: FGColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _createChallenge(Map<String, dynamic> data) async {
    HapticFeedback.mediumImpact();
    final friendIds = data['friendIds'] as List<String>;
    final title = data['title'] as String? ?? 'Nouveau défi';
    final exerciseName = data['exercise'] as String? ?? 'Exercice';
    final targetValue = data['target'] as double? ?? 100;
    final unit = data['unit'] as String? ?? 'kg';

    try {
      // Save to Supabase
      final response = await SupabaseService.createChallenge(
        title: title,
        exerciseName: exerciseName,
        type: 'weight',
        targetValue: targetValue,
        unit: unit,
        deadline: DateTime.now().add(const Duration(days: 30)),
        participantIds: friendIds,
      );

      // Create local Challenge object from response
      final participants = <ChallengeParticipant>[
        ChallengeParticipant(
          id: _currentUserId,
          name: _currentUserName,
          avatarUrl: '',
          currentValue: 0,
          hasCompleted: false,
        ),
        ...friendIds.map((id) {
          final friend = _friends.firstWhere((f) => f.id == id);
          return ChallengeParticipant(
            id: friend.id,
            name: friend.name,
            avatarUrl: friend.avatarUrl,
            currentValue: 0,
            hasCompleted: false,
          );
        }),
      ];

      final newChallenge = Challenge(
        id: response['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        exerciseName: exerciseName,
        type: ChallengeType.weight,
        targetValue: targetValue,
        unit: unit,
        deadline: DateTime.now().add(const Duration(days: 30)),
        status: ChallengeStatus.active,
        creatorId: _currentUserId,
        creatorName: _currentUserName,
        participants: participants,
        createdAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _challenges.insert(0, newChallenge);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Défi "$title" créé ! ${friendIds.length} ami(s) invité(s)'),
            backgroundColor: FGColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating challenge: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la création du défi'),
            backgroundColor: FGColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _openCreateChallenge() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreateChallengeSheet(
        friends: _friends,
        onCreate: (data) {
          _createChallenge(data);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      floatingActionButton: _selectedTab == 1
          ? FloatingActionButton(
              onPressed: _openCreateChallenge,
              backgroundColor: FGColors.accent,
              child: const Icon(Icons.add, color: FGColors.textOnAccent),
            )
          : null,
      body: Stack(
        children: [
          FGMeshGradient.social(animation: _pulseAnimation),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: FGColors.accent,
                      strokeWidth: 2,
                    ),
                  )
                : Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: _buildHeader(),
                ),

                // Segmented Control
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: _buildSegmentedControl(),
                ),
                const SizedBox(height: Spacing.lg),

                // Content
                Expanded(
                  child: _selectedTab == 0 ? _buildFeed() : _buildChallenges(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOCIAL',
                style: FGTypography.caption.copyWith(
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                  color: FGColors.textSecondary,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ta communauté',
                  style: FGTypography.h1.copyWith(fontSize: 32),
                ),
              ),
            ],
          ),
        ),
        // Notifications bell
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            NotificationsSheet.show(context);
          },
          child: Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: FGColors.glassSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: FGColors.glassBorder,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: FGColors.textPrimary,
                  size: 24,
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: FGColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
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
          Expanded(child: _buildSegmentButton('FEED', 0)),
          Expanded(child: _buildSegmentButton('DÉFIS', 1)),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        decoration: BoxDecoration(
          color: isSelected ? FGColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: FGTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: isSelected ? FGColors.textOnAccent : FGColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeed() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: ActivityCard(
            activity: activity,
            onTap: () => _openActivityDetail(activity),
            onRespect: () => _onRespect(activity.id),
          ),
        );
      },
    );
  }

  Widget _buildChallenges() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      itemCount: _challenges.length,
      itemBuilder: (context, index) {
        final challenge = _challenges[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: ChallengeCard(
            challenge: challenge,
            onTap: () => _openChallengeDetail(challenge),
            onParticipate: () => _participateInChallenge(challenge),
          ),
        );
      },
    );
  }
}
