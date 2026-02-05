import 'dart:io';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for interacting with Apple HealthKit / Google Fit
class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();
  bool _isAuthorized = false;

  /// Data types we want to read from HealthKit
  static const List<HealthDataType> _readTypes = [
    // Sleep
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_IN_BED,
    // Activity
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    // Heart
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    // Workout
    HealthDataType.WORKOUT,
  ];

  /// Data types we can write to HealthKit
  static const List<HealthDataType> _writeTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  /// Check if HealthKit is available on this platform
  bool get isAvailable => Platform.isIOS || Platform.isAndroid;

  /// Check if we have authorization
  bool get isAuthorized => _isAuthorized;

  /// Request authorization to access health data
  Future<bool> requestAuthorization() async {
    if (!isAvailable) return false;

    try {
      // Request activity recognition permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.activityRecognition.request();
        if (!status.isGranted) return false;
      }

      // Configure health
      await _health.configure();

      // Build permissions list matching _readTypes length
      // READ_WRITE for types we can write, READ for others
      final permissions = _readTypes.map((type) {
        return _writeTypes.contains(type)
            ? HealthDataAccess.READ_WRITE
            : HealthDataAccess.READ;
      }).toList();

      // Request authorization
      final authorized = await _health.requestAuthorization(
        _readTypes,
        permissions: permissions,
      );

      _isAuthorized = authorized;
      return authorized;
    } catch (e) {
      print('Error requesting health authorization: $e');
      return false;
    }
  }

  /// Check current authorization status
  Future<bool> checkAuthorization() async {
    if (!isAvailable) return false;

    try {
      await _health.configure();
      final status = await _health.hasPermissions(_readTypes);
      _isAuthorized = status ?? false;
      return _isAuthorized;
    } catch (e) {
      print('Error checking health authorization: $e');
      return false;
    }
  }

  /// Fetch sleep data for a given date
  Future<SleepData?> getSleepData(DateTime date) async {
    if (!_isAuthorized) return null;

    try {
      // Get sleep data from the night before (8pm to 12pm next day)
      final startOfNight = DateTime(date.year, date.month, date.day - 1, 20, 0);
      final endOfMorning = DateTime(date.year, date.month, date.day, 12, 0);

      final sleepTypes = [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_IN_BED,
      ];

      final data = await _health.getHealthDataFromTypes(
        types: sleepTypes,
        startTime: startOfNight,
        endTime: endOfMorning,
      );

      if (data.isEmpty) return null;

      // Remove duplicate data points (same source at same time)
      final uniqueData = _health.removeDuplicates(data);

      // Find the main sleep session by looking for IN_BED segments
      // Take only the longest continuous sleep session to avoid counting naps twice
      final inBedSegments = uniqueData
          .where((p) => p.type == HealthDataType.SLEEP_IN_BED)
          .toList();

      DateTime? mainSleepStart;
      DateTime? mainSleepEnd;

      if (inBedSegments.isNotEmpty) {
        // Find the longest IN_BED segment (main sleep session)
        int maxDuration = 0;
        for (final segment in inBedSegments) {
          final duration = segment.dateTo.difference(segment.dateFrom).inMinutes;
          if (duration > maxDuration) {
            maxDuration = duration;
            mainSleepStart = segment.dateFrom;
            mainSleepEnd = segment.dateTo;
          }
        }
      } else {
        // No IN_BED data - use all sleep data
        mainSleepStart = startOfNight;
        mainSleepEnd = endOfMorning;
      }

      // Aggregate sleep phases only within the main sleep window
      int deepSleep = 0;
      int lightSleep = 0;
      int remSleep = 0;
      int awake = 0;
      int inBed = 0;

      // Track processed intervals to avoid double-counting overlapping segments
      final processedIntervals = <String, Set<int>>{};

      for (final point in uniqueData) {
        // Skip data outside main sleep session (if we have bounds)
        if (mainSleepStart != null && mainSleepEnd != null) {
          if (point.dateFrom.isBefore(mainSleepStart) ||
              point.dateTo.isAfter(mainSleepEnd.add(const Duration(minutes: 30)))) {
            continue;
          }
        }

        // Create a key for this segment type
        final typeKey = point.type.toString();
        processedIntervals[typeKey] ??= <int>{};

        // Calculate minutes, avoiding double-counting
        final startMinute = point.dateFrom.millisecondsSinceEpoch ~/ 60000;
        final endMinute = point.dateTo.millisecondsSinceEpoch ~/ 60000;

        int newMinutes = 0;
        for (int m = startMinute; m < endMinute; m++) {
          if (!processedIntervals[typeKey]!.contains(m)) {
            processedIntervals[typeKey]!.add(m);
            newMinutes++;
          }
        }

        switch (point.type) {
          case HealthDataType.SLEEP_DEEP:
            deepSleep += newMinutes;
            break;
          case HealthDataType.SLEEP_LIGHT:
            lightSleep += newMinutes;
            break;
          case HealthDataType.SLEEP_REM:
            remSleep += newMinutes;
            break;
          case HealthDataType.SLEEP_AWAKE:
            awake += newMinutes;
            break;
          case HealthDataType.SLEEP_IN_BED:
            inBed += newMinutes;
            break;
          case HealthDataType.SLEEP_ASLEEP:
            // Generic sleep - only count if no detailed phases
            if (deepSleep == 0 && remSleep == 0 && lightSleep == 0) {
              lightSleep += newMinutes;
            }
            break;
          default:
            break;
        }
      }

      // Total sleep is sum of actual sleep phases (not IN_BED which includes awake time)
      final totalSleep = deepSleep + lightSleep + remSleep;

      return SleepData(
        date: date,
        totalMinutes: totalSleep,
        deepMinutes: deepSleep,
        lightMinutes: lightSleep,
        remMinutes: remSleep,
        awakeMinutes: awake,
        inBedMinutes: inBed > 0 ? inBed : totalSleep + awake,
      );
    } catch (e) {
      print('Error fetching sleep data: $e');
      return null;
    }
  }

  /// Fetch activity data for a given date
  Future<ActivityData?> getActivityData(DateTime date) async {
    if (!_isAuthorized) return null;

    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Steps
      final steps = await _health.getTotalStepsInInterval(startOfDay, endOfDay);

      // Calories
      final activeCaloriesData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      final basalCaloriesData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BASAL_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      // Distance
      final distanceData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_WALKING_RUNNING],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      double activeCalories = 0;
      for (final point in activeCaloriesData) {
        // HealthKit returns energy in kJ, convert to kcal (1 kcal = 4.184 kJ)
        activeCalories += (point.value as NumericHealthValue).numericValue / 4.184;
      }

      double basalCalories = 0;
      for (final point in basalCaloriesData) {
        // HealthKit returns energy in kJ, convert to kcal (1 kcal = 4.184 kJ)
        basalCalories += (point.value as NumericHealthValue).numericValue / 4.184;
      }

      double distance = 0;
      for (final point in distanceData) {
        distance += (point.value as NumericHealthValue).numericValue;
      }

      return ActivityData(
        date: date,
        steps: steps ?? 0,
        activeCaloriesBurned: activeCalories.round(),
        basalCaloriesBurned: basalCalories.round(),
        distanceMeters: distance,
      );
    } catch (e) {
      print('Error fetching activity data: $e');
      return null;
    }
  }

  /// Fetch heart rate data for a given date
  Future<HeartData?> getHeartData(DateTime date) async {
    if (!_isAuthorized) return null;

    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Heart rate samples
      final hrData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      // Resting heart rate
      final restingHrData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.RESTING_HEART_RATE],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      // HRV
      final hrvData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      if (hrData.isEmpty) return null;

      // Calculate stats from HR data
      final hrValues = hrData
          .map((p) => (p.value as NumericHealthValue).numericValue)
          .toList();

      final avgHr = hrValues.reduce((a, b) => a + b) / hrValues.length;
      final minHr = hrValues.reduce((a, b) => a < b ? a : b);
      final maxHr = hrValues.reduce((a, b) => a > b ? a : b);

      // Get resting HR (most recent value)
      int? restingHr;
      if (restingHrData.isNotEmpty) {
        restingHr = (restingHrData.last.value as NumericHealthValue)
            .numericValue
            .round();
      }

      // Get HRV (most recent value)
      int? hrv;
      if (hrvData.isNotEmpty) {
        hrv = (hrvData.last.value as NumericHealthValue).numericValue.round();
      }

      return HeartData(
        date: date,
        averageHeartRate: avgHr.round(),
        minHeartRate: minHr.round(),
        maxHeartRate: maxHr.round(),
        restingHeartRate: restingHr,
        hrvMs: hrv,
      );
    } catch (e) {
      print('Error fetching heart data: $e');
      return null;
    }
  }

  /// Fetch all health data for a given date
  Future<HealthSnapshot?> getHealthSnapshot(DateTime date) async {
    if (!_isAuthorized) {
      final authorized = await checkAuthorization();
      if (!authorized) return null;
    }

    final results = await Future.wait([
      getSleepData(date),
      getActivityData(date),
      getHeartData(date),
    ]);

    return HealthSnapshot(
      date: date,
      sleep: results[0] as SleepData?,
      activity: results[1] as ActivityData?,
      heart: results[2] as HeartData?,
    );
  }

  /// Get calories burned for multiple days (for prediction)
  Future<List<ActivityData>> getCaloriesHistory({int days = 7}) async {
    if (!_isAuthorized) {
      final authorized = await checkAuthorization();
      if (!authorized) return [];
    }

    final results = <ActivityData>[];
    final now = DateTime.now();

    for (int i = 1; i <= days; i++) {
      final date = now.subtract(Duration(days: i));
      final activity = await getActivityData(date);
      if (activity != null) {
        results.add(activity);
      }
    }

    return results;
  }

  /// Predict end-of-day calories based on current burn rate and history
  Future<int?> predictDailyCalories() async {
    final history = await getCaloriesHistory(days: 7);
    if (history.isEmpty) return null;

    final now = DateTime.now();
    final currentHour = now.hour + (now.minute / 60);

    // Get today's current calories
    final today = await getActivityData(now);
    if (today == null) return null;

    // Calculate average ratio at current time from history
    // (what percentage of daily total was burned by this hour)
    double totalRatio = 0;
    int validDays = 0;

    for (final day in history) {
      if (day.totalCaloriesBurned > 0) {
        // Assume linear burn throughout day for simplicity
        // In reality could use hourly data if available
        totalRatio += currentHour / 24;
        validDays++;
      }
    }

    if (validDays == 0) return null;

    final avgRatio = totalRatio / validDays;
    if (avgRatio <= 0) return null;

    // Predict: current / ratio = predicted total
    final predicted = today.totalCaloriesBurned / avgRatio;
    return predicted.round();
  }

  /// Write a workout to HealthKit
  Future<bool> writeWorkout({
    required DateTime start,
    required DateTime end,
    required int caloriesBurned,
  }) async {
    if (!_isAuthorized) return false;

    try {
      return await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING,
        start: start,
        end: end,
        totalEnergyBurned: caloriesBurned,
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      );
    } catch (e) {
      print('Error writing workout: $e');
      return false;
    }
  }
}

/// Sleep data model
class SleepData {
  final DateTime date;
  final int totalMinutes;
  final int deepMinutes;
  final int lightMinutes;
  final int remMinutes;
  final int awakeMinutes;
  final int inBedMinutes;

  SleepData({
    required this.date,
    required this.totalMinutes,
    required this.deepMinutes,
    required this.lightMinutes,
    required this.remMinutes,
    required this.awakeMinutes,
    required this.inBedMinutes,
  });

  /// Calculate sleep score (0-100)
  int get score {
    if (totalMinutes == 0) return 0;

    // Ideal values
    const idealTotalMinutes = 7.5 * 60; // 7.5 hours
    const idealDeepPercent = 0.15; // 15-20%
    const idealRemPercent = 0.20; // 20-25%

    // Score components
    final durationScore = (totalMinutes / idealTotalMinutes).clamp(0.0, 1.0);
    final deepPercent = deepMinutes / totalMinutes;
    final remPercent = remMinutes / totalMinutes;

    final deepScore = (deepPercent / idealDeepPercent).clamp(0.0, 1.0);
    final remScore = (remPercent / idealRemPercent).clamp(0.0, 1.0);

    // Weighted average
    final score = (durationScore * 0.5 + deepScore * 0.25 + remScore * 0.25) * 100;
    return score.round().clamp(0, 100);
  }
}

/// Activity data model
class ActivityData {
  final DateTime date;
  final int steps;
  final int activeCaloriesBurned;
  final int basalCaloriesBurned;
  final double distanceMeters;

  ActivityData({
    required this.date,
    required this.steps,
    required this.activeCaloriesBurned,
    required this.basalCaloriesBurned,
    required this.distanceMeters,
  });

  int get totalCaloriesBurned => activeCaloriesBurned + basalCaloriesBurned;
  double get distanceKm => distanceMeters / 1000;

  /// Calculate activity score (0-100)
  int get score {
    const stepsGoal = 10000;
    const caloriesGoal = 500; // Active calories goal

    final stepsScore = (steps / stepsGoal).clamp(0.0, 1.0);
    final caloriesScore = (activeCaloriesBurned / caloriesGoal).clamp(0.0, 1.0);

    final score = (stepsScore * 0.6 + caloriesScore * 0.4) * 100;
    return score.round().clamp(0, 100);
  }
}

/// Heart data model
class HeartData {
  final DateTime date;
  final int averageHeartRate;
  final int minHeartRate;
  final int maxHeartRate;
  final int? restingHeartRate;
  final int? hrvMs;

  HeartData({
    required this.date,
    required this.averageHeartRate,
    required this.minHeartRate,
    required this.maxHeartRate,
    this.restingHeartRate,
    this.hrvMs,
  });

  /// Calculate heart score (0-100)
  int get score {
    // Ideal resting HR: 50-70 bpm
    // Ideal HRV: 40-100 ms

    int score = 70; // Base score

    // Resting HR bonus/penalty
    if (restingHeartRate != null) {
      if (restingHeartRate! < 50) {
        score += 15; // Athlete level
      } else if (restingHeartRate! <= 60) {
        score += 10; // Excellent
      } else if (restingHeartRate! <= 70) {
        score += 5; // Good
      } else if (restingHeartRate! > 80) {
        score -= 10; // Needs improvement
      }
    }

    // HRV bonus/penalty
    if (hrvMs != null) {
      if (hrvMs! >= 60) {
        score += 15; // Excellent recovery
      } else if (hrvMs! >= 40) {
        score += 5; // Good
      } else if (hrvMs! < 30) {
        score -= 10; // Low, stressed
      }
    }

    return score.clamp(0, 100);
  }
}

/// Combined health snapshot for a day
class HealthSnapshot {
  final DateTime date;
  final SleepData? sleep;
  final ActivityData? activity;
  final HeartData? heart;

  HealthSnapshot({
    required this.date,
    this.sleep,
    this.activity,
    this.heart,
  });

  /// Overall health score (0-100)
  int get overallScore {
    final scores = <int>[];

    if (sleep != null) scores.add(sleep!.score);
    if (activity != null) scores.add(activity!.score);
    if (heart != null) scores.add(heart!.score);

    if (scores.isEmpty) return 0;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  bool get hasData => sleep != null || activity != null || heart != null;
}
