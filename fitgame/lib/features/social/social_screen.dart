import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';
import '../../core/constants/spacing.dart';
import 'models/activity.dart';
import 'models/challenge.dart';
import 'models/friend.dart';
import 'widgets/activity_card.dart';
import 'widgets/challenge_card.dart';
import 'sheets/activity_detail_sheet.dart';
import 'sheets/challenge_detail_sheet.dart';
import 'sheets/create_challenge_sheet.dart';
import 'sheets/notifications_sheet.dart';

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

  // ============ MOCK DATA ============

  final List<Activity> _activities = [
    Activity(
      id: '1',
      userName: 'Thomas D.',
      userAvatarUrl: '',
      workoutName: 'Push Day',
      muscles: 'Pectoraux • Épaules • Triceps',
      durationMinutes: 58,
      volumeKg: 4850,
      exerciseCount: 6,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      topExercises: const [
        ExerciseSummary(name: 'Développé couché', shortName: 'Bench', weightKg: 100, reps: 6),
        ExerciseSummary(name: 'Développé incliné', shortName: 'Incliné', weightKg: 80, reps: 8),
        ExerciseSummary(name: 'Dips lestés', shortName: 'Dips', weightKg: 20, reps: 10),
      ],
      pr: const PersonalRecord(exerciseName: 'Développé couché', value: 100, gain: 5),
      respectCount: 24,
      hasGivenRespect: false,
      respectGivers: ['Mike', 'Julie', 'Marc', 'Sarah'],
    ),
    Activity(
      id: '2',
      userName: 'Julie M.',
      userAvatarUrl: '',
      workoutName: 'Leg Day',
      muscles: 'Quadriceps • Ischio • Fessiers',
      durationMinutes: 72,
      volumeKg: 8200,
      exerciseCount: 8,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      topExercises: const [
        ExerciseSummary(name: 'Squat', shortName: 'Squat', weightKg: 120, reps: 5),
        ExerciseSummary(name: 'Leg Press', shortName: 'Presse', weightKg: 280, reps: 10),
        ExerciseSummary(name: 'Romanian DL', shortName: 'RDL', weightKg: 80, reps: 8),
      ],
      pr: null,
      respectCount: 18,
      hasGivenRespect: true,
      respectGivers: ['Thomas', 'Mike', 'Léo'],
    ),
    Activity(
      id: '3',
      userName: 'Marc L.',
      userAvatarUrl: '',
      workoutName: 'Pull Day',
      muscles: 'Dos • Biceps • Trapèzes',
      durationMinutes: 65,
      volumeKg: 5600,
      exerciseCount: 7,
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      topExercises: const [
        ExerciseSummary(name: 'Tractions lestées', shortName: 'Tractions', weightKg: 25, reps: 8),
        ExerciseSummary(name: 'Rowing barre', shortName: 'Rowing', weightKg: 90, reps: 8),
        ExerciseSummary(name: 'Curl barre', shortName: 'Curl', weightKg: 40, reps: 10),
      ],
      pr: const PersonalRecord(exerciseName: 'Tractions lestées', value: 25, gain: 2.5),
      respectCount: 31,
      hasGivenRespect: false,
      respectGivers: ['Julie', 'Thomas', 'Sarah', 'Emma'],
    ),
    Activity(
      id: '4',
      userName: 'Sarah K.',
      userAvatarUrl: '',
      workoutName: 'Full Body',
      muscles: 'Tout le corps',
      durationMinutes: 45,
      volumeKg: 3200,
      exerciseCount: 5,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      topExercises: const [
        ExerciseSummary(name: 'Soulevé de terre', shortName: 'Deadlift', weightKg: 100, reps: 5),
        ExerciseSummary(name: 'Développé militaire', shortName: 'OHP', weightKg: 40, reps: 8),
        ExerciseSummary(name: 'Fentes', shortName: 'Fentes', weightKg: 30, reps: 12),
      ],
      pr: null,
      respectCount: 12,
      hasGivenRespect: false,
      respectGivers: ['Mike', 'Thomas'],
    ),
  ];

  final List<Challenge> _challenges = [
    Challenge(
      id: '1',
      title: '100kg au bench',
      exerciseName: 'Développé couché',
      type: ChallengeType.weight,
      targetValue: 100,
      unit: 'kg',
      deadline: DateTime.now().add(const Duration(days: 3)),
      status: ChallengeStatus.active,
      creatorId: 'mike',
      creatorName: 'Mike',
      participants: const [
        ChallengeParticipant(id: '1', name: 'Thomas', avatarUrl: '', currentValue: 100, hasCompleted: true),
        ChallengeParticipant(id: '2', name: 'Julie', avatarUrl: '', currentValue: 95, hasCompleted: false),
        ChallengeParticipant(id: '3', name: 'Mike', avatarUrl: '', currentValue: 90, hasCompleted: false),
        ChallengeParticipant(id: '4', name: 'Marc', avatarUrl: '', currentValue: 85, hasCompleted: false),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Challenge(
      id: '2',
      title: '20 tractions strictes',
      exerciseName: 'Tractions',
      type: ChallengeType.reps,
      targetValue: 20,
      unit: 'reps',
      deadline: DateTime.now().add(const Duration(days: 14)),
      status: ChallengeStatus.active,
      creatorId: 'marc',
      creatorName: 'Marc',
      participants: const [
        ChallengeParticipant(id: '1', name: 'Marc', avatarUrl: '', currentValue: 18, hasCompleted: false),
        ChallengeParticipant(id: '2', name: 'Thomas', avatarUrl: '', currentValue: 15, hasCompleted: false),
        ChallengeParticipant(id: '3', name: 'Mike', avatarUrl: '', currentValue: 12, hasCompleted: false),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Challenge(
      id: '3',
      title: '200kg au squat',
      exerciseName: 'Squat',
      type: ChallengeType.weight,
      targetValue: 200,
      unit: 'kg',
      deadline: null,
      status: ChallengeStatus.active,
      creatorId: 'julie',
      creatorName: 'Julie',
      participants: const [
        ChallengeParticipant(id: '1', name: 'Julie', avatarUrl: '', currentValue: 140, hasCompleted: false),
        ChallengeParticipant(id: '2', name: 'Thomas', avatarUrl: '', currentValue: 160, hasCompleted: false),
        ChallengeParticipant(id: '3', name: 'Marc', avatarUrl: '', currentValue: 150, hasCompleted: false),
        ChallengeParticipant(id: '4', name: 'Mike', avatarUrl: '', currentValue: 130, hasCompleted: false),
        ChallengeParticipant(id: '5', name: 'Sarah', avatarUrl: '', currentValue: 100, hasCompleted: false),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  final List<Friend> _friends = const [
    Friend(id: '1', name: 'Thomas D.', avatarUrl: '', isOnline: true, totalWorkouts: 245, streak: 12),
    Friend(id: '2', name: 'Julie M.', avatarUrl: '', isOnline: true, totalWorkouts: 189, streak: 8),
    Friend(id: '3', name: 'Marc L.', avatarUrl: '', isOnline: false, lastActive: null, totalWorkouts: 312, streak: 24),
    Friend(id: '4', name: 'Sarah K.', avatarUrl: '', isOnline: false, lastActive: null, totalWorkouts: 156, streak: 5),
    Friend(id: '5', name: 'Emma R.', avatarUrl: '', isOnline: false, lastActive: null, totalWorkouts: 78, streak: 3),
  ];

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onRespect(String activityId) {
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
          respectCount: activity.respectCount + 1,
          hasGivenRespect: true,
          respectGivers: ['Toi', ...activity.respectGivers],
        );
      }
    });
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

  void _participateInChallenge(Challenge challenge) {
    HapticFeedback.mediumImpact();
    // Check if already participating
    final isParticipating = challenge.participants.any((p) => p.name == 'Mike');
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

    setState(() {
      final index = _challenges.indexWhere((c) => c.id == challenge.id);
      if (index != -1) {
        final updatedParticipants = [
          ...challenge.participants,
          const ChallengeParticipant(
            id: 'mike',
            name: 'Mike',
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

  void _createChallenge(Map<String, dynamic> data) {
    HapticFeedback.mediumImpact();
    final friendIds = data['friendIds'] as List<String>;
    final title = data['title'] as String? ?? 'Nouveau défi';
    final exerciseName = data['exercise'] as String? ?? 'Exercice';
    final targetValue = data['target'] as double? ?? 100;
    final unit = data['unit'] as String? ?? 'kg';

    // Create participants from invited friends
    final participants = <ChallengeParticipant>[
      const ChallengeParticipant(
        id: 'mike',
        name: 'Mike',
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      exerciseName: exerciseName,
      type: ChallengeType.weight,
      targetValue: targetValue,
      unit: unit,
      deadline: DateTime.now().add(const Duration(days: 30)),
      status: ChallengeStatus.active,
      creatorId: 'mike',
      creatorName: 'Mike',
      participants: participants,
      createdAt: DateTime.now(),
    );

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
          _buildMeshGradient(),
          SafeArea(
            child: Column(
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

  Widget _buildMeshGradient() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Container(color: FGColors.background),
            Positioned(
              top: -50,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      FGColors.accent.withValues(alpha: _pulseAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 150,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6B5BFF)
                          .withValues(alpha: _pulseAnimation.value * 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
