import 'package:flutter/material.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';
import '../../core/constants/spacing.dart';
import '../../shared/widgets/fg_glass_card.dart';
import 'create/create_choice_screen.dart';
import 'tracking/active_workout_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Mock data
  final bool hasActiveProgram = true;
  final String programName = 'Push Pull Legs';
  final int currentWeek = 3;
  final int totalWeeks = 8;
  final String nextSessionName = 'Pull Day';
  final String nextSessionMuscles = 'Dos • Biceps';
  final int nextSessionExercises = 5;

  final List<Map<String, dynamic>> recentSessions = [
    {
      'name': 'Push Day',
      'date': 'Aujourd\'hui',
      'volume': '4,200 kg',
      'isToday': true,
    },
    {
      'name': 'Leg Day',
      'date': 'Hier',
      'volume': '6,800 kg',
      'isToday': false,
    },
    {
      'name': 'Pull Day',
      'date': 'Lun',
      'volume': '3,600 kg',
      'isToday': false,
    },
  ];

  final List<Map<String, dynamic>> savedPrograms = [
    {
      'name': 'Push Pull Legs',
      'weeks': 8,
      'currentWeek': 3,
      'isActive': true,
    },
    {
      'name': 'Full Body 3x',
      'weeks': 12,
      'currentWeek': 0,
      'isActive': false,
    },
    {
      'name': 'Upper Lower',
      'weeks': 6,
      'currentWeek': 4,
      'isActive': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.08, end: 0.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          _buildMeshGradient(),
          SafeArea(
            child: hasActiveProgram ? _buildMainContent() : _buildEmptyState(),
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
            // Subtle bottom-left glow
            Positioned(
              bottom: 200,
              left: -100,
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
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => _openCreateFlow(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: FGColors.glassSurface,
                borderRadius: BorderRadius.circular(Spacing.sm),
                border: Border.all(color: FGColors.glassBorder),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: FGColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateFlow() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CreateChoiceScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Spacing.md),

                  // === NEXT SESSION CARD (HERO) ===
                  _buildNextSessionCard(),
                  const SizedBox(height: Spacing.lg),

                  // === PROGRAM PROGRESS CARD ===
                  _buildProgramCard(),
                  const SizedBox(height: Spacing.xxl),

                  // === RECENT ACTIVITY ===
                  _buildRecentActivity(),
                  const SizedBox(height: Spacing.xxl),

                  // === QUICK ACTIONS ===
                  _buildQuickActions(),
                  const SizedBox(height: Spacing.xl),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startWorkout() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ActiveWorkoutScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildNextSessionCard() {
    return GestureDetector(
      onTap: _startWorkout,
      child: FGGlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FGColors.accent.withValues(alpha: 0.12),
                    FGColors.accent.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm,
                      vertical: Spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: FGColors.accent,
                      borderRadius: BorderRadius.circular(Spacing.xs),
                    ),
                    child: Text(
                      'PROCHAINE',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textOnAccent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$nextSessionExercises exercices',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextSessionName,
                          style: FGTypography.h1.copyWith(fontSize: 32),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          nextSessionMuscles,
                          style: FGTypography.body.copyWith(
                            color: FGColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          FGColors.accent.withValues(alpha: 0.3),
                          FGColors.accent.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(Spacing.md),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: FGColors.accent,
                      size: 28,
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

  Widget _buildProgramCard() {
    final progress = currentWeek / totalWeeks;

    return GestureDetector(
      onTap: () => _showProgramSheet(),
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.lg),
          border: Border.all(color: FGColors.glassBorder),
        ),
        child: Row(
          children: [
            // Progress ring
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                children: [
                  // Track
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 4,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        FGColors.glassBorder,
                      ),
                    ),
                  ),
                  // Progress
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation(
                        FGColors.accent,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Percentage
                  Center(
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: FGTypography.caption.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    programName,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Semaine $currentWeek sur $totalWeeks',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: FGColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Spacing.xs),
          child: Text(
            'RÉCENT',
            style: FGTypography.caption.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: FGColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        ...recentSessions.map((session) => _buildRecentItem(session)),
      ],
    );
  }

  Widget _buildRecentItem(Map<String, dynamic> session) {
    final isToday = session['isToday'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.md,
          ),
          decoration: BoxDecoration(
            color: isToday
                ? FGColors.success.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(Spacing.md),
            border: isToday
                ? Border.all(color: FGColors.success.withValues(alpha: 0.2))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isToday
                      ? FGColors.success.withValues(alpha: 0.2)
                      : FGColors.glassBorder,
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: isToday ? FGColors.success : FGColors.textSecondary,
                  size: 16,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  session['name'] as String,
                  style: FGTypography.body.copyWith(
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                    color: isToday ? FGColors.textPrimary : FGColors.textSecondary,
                  ),
                ),
              ),
              Text(
                session['volume'] as String,
                style: FGTypography.caption.copyWith(
                  color: FGColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Text(
                session['date'] as String,
                style: FGTypography.caption.copyWith(
                  color: isToday ? FGColors.success : FGColors.textSecondary,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.edit_outlined,
            label: 'Modifier',
            onTap: () {},
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _buildActionButton(
            icon: Icons.history_rounded,
            label: 'Historique',
            onTap: () {},
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_rounded,
            label: 'Séance libre',
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        decoration: BoxDecoration(
          color: FGColors.glassSurface.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(color: FGColors.glassBorder),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: FGColors.textSecondary,
              size: 20,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              label,
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === EMPTY STATE ===
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            'Prêt à\ncommencer ?',
            textAlign: TextAlign.center,
            style: FGTypography.h1.copyWith(fontSize: 42, height: 1.1),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Choisis ton programme ou crée une séance',
            textAlign: TextAlign.center,
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const Spacer(),
          _buildEmptyOption(
            icon: Icons.auto_awesome_rounded,
            title: 'Programme guidé',
            subtitle: 'Un plan sur plusieurs semaines',
            isPrimary: true,
            onTap: () => _showProgramSheet(),
          ),
          const SizedBox(height: Spacing.md),
          _buildEmptyOption(
            icon: Icons.bolt_rounded,
            title: 'Séance libre',
            subtitle: 'Crée ton entraînement',
            isPrimary: false,
            onTap: () {},
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildEmptyOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FGColors.accent.withValues(alpha: 0.15),
                    FGColors.accent.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: isPrimary ? null : FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.lg),
          border: Border.all(
            color: isPrimary
                ? FGColors.accent.withValues(alpha: 0.3)
                : FGColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPrimary
                    ? FGColors.accent.withValues(alpha: 0.2)
                    : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.md),
              ),
              child: Icon(
                icon,
                color: isPrimary ? FGColors.accent : FGColors.textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isPrimary ? FGColors.accent : FGColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: isPrimary ? FGColors.accent : FGColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // === BOTTOM SHEET ===
  void _showProgramSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: FGColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: FGColors.glassBorder),
          ),
          child: Column(
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

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Row(
                  children: [
                    Text('Mes programmes', style: FGTypography.h2),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: FGColors.glassBorder,
                          borderRadius: BorderRadius.circular(Spacing.sm),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: FGColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  children: [
                    ...savedPrograms.map(
                      (program) => Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: _buildProgramListItem(program),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    _buildNewProgramButton(),
                    const SizedBox(height: Spacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramListItem(Map<String, dynamic> program) {
    final isActive = program['isActive'] as bool;
    final currentW = program['currentWeek'] as int;
    final totalW = program['weeks'] as int;
    final hasProgress = currentW > 0;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        // TODO: Switch program
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: isActive
              ? FGColors.success.withValues(alpha: 0.08)
              : FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.lg),
          border: Border.all(
            color: isActive
                ? FGColors.success.withValues(alpha: 0.3)
                : FGColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? FGColors.success.withValues(alpha: 0.2)
                    : FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: Icon(
                isActive ? Icons.play_arrow_rounded : Icons.calendar_month_outlined,
                color: isActive ? FGColors.success : FGColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        program['name'] as String,
                        style: FGTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: Spacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: FGColors.success,
                            borderRadius: BorderRadius.circular(Spacing.xs),
                          ),
                          child: Text(
                            'ACTIF',
                            style: FGTypography.caption.copyWith(
                              fontSize: 9,
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    hasProgress
                        ? 'Semaine $currentW/$totalW'
                        : '$totalW semaines',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isActive)
              const Icon(
                Icons.chevron_right_rounded,
                color: FGColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewProgramButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        // TODO: Create new program
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          border: Border.all(
            color: FGColors.glassBorder,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(Spacing.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_rounded,
              color: FGColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              'Nouveau programme',
              style: FGTypography.body.copyWith(
                color: FGColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
