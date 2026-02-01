import 'package:flutter/material.dart';

/// Timing options for supplement intake
enum SupplementTiming {
  morning('Matin'),
  preWorkout('Pré-workout'),
  postWorkout('Post-workout'),
  evening('Soir'),
  withMeal('Avec repas');

  final String label;
  const SupplementTiming(this.label);
}

/// A single food entry with nutritional information
class FoodEntry {
  final String id;
  final String name;
  final String quantity;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String unit;

  const FoodEntry({
    required this.id,
    required this.name,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.unit,
  });

  FoodEntry copyWith({
    String? id,
    String? name,
    String? quantity,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    String? unit,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      unit: unit ?? this.unit,
    );
  }
}

/// A meal plan with foods and their totals
class MealPlan {
  final String name;
  final IconData icon;
  final List<FoodEntry> foods;

  const MealPlan({
    required this.name,
    required this.icon,
    this.foods = const [],
  });

  int get totalCalories => foods.fold(0, (sum, f) => sum + f.calories);
  int get totalProtein => foods.fold(0, (sum, f) => sum + f.protein);
  int get totalCarbs => foods.fold(0, (sum, f) => sum + f.carbs);
  int get totalFat => foods.fold(0, (sum, f) => sum + f.fat);

  MealPlan copyWith({
    String? name,
    IconData? icon,
    List<FoodEntry>? foods,
  }) {
    return MealPlan(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      foods: foods ?? this.foods,
    );
  }

  MealPlan addFood(FoodEntry food) {
    return copyWith(foods: [...foods, food]);
  }

  MealPlan removeFood(String foodId) {
    return copyWith(foods: foods.where((f) => f.id != foodId).toList());
  }
}

/// A supplement entry with dosage, timing, and notification settings
class SupplementEntry {
  final String id;
  final String name;
  final IconData icon;
  final String dosage;
  final SupplementTiming timing;
  final bool notificationsEnabled;
  final TimeOfDay? reminderTime;

  const SupplementEntry({
    required this.id,
    required this.name,
    required this.icon,
    required this.dosage,
    required this.timing,
    this.notificationsEnabled = false,
    this.reminderTime,
  });

  SupplementEntry copyWith({
    String? id,
    String? name,
    IconData? icon,
    String? dosage,
    SupplementTiming? timing,
    bool? notificationsEnabled,
    TimeOfDay? reminderTime,
  }) {
    return SupplementEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      dosage: dosage ?? this.dosage,
      timing: timing ?? this.timing,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

/// Supplement catalog with default values
class SupplementCatalog {
  static const List<Map<String, dynamic>> supplements = [
    {
      'id': 'creatine',
      'name': 'Créatine',
      'icon': Icons.science_rounded,
      'dosage': '5g',
      'timing': SupplementTiming.postWorkout,
    },
    {
      'id': 'whey',
      'name': 'Whey Protein',
      'icon': Icons.local_drink_rounded,
      'dosage': '30g',
      'timing': SupplementTiming.postWorkout,
    },
    {
      'id': 'bcaa',
      'name': 'BCAA',
      'icon': Icons.bubble_chart_rounded,
      'dosage': '5g',
      'timing': SupplementTiming.preWorkout,
    },
    {
      'id': 'multivitamins',
      'name': 'Multivitamines',
      'icon': Icons.medication_rounded,
      'dosage': '1 capsule',
      'timing': SupplementTiming.morning,
    },
    {
      'id': 'omega3',
      'name': 'Oméga-3',
      'icon': Icons.water_drop_rounded,
      'dosage': '2 capsules',
      'timing': SupplementTiming.withMeal,
    },
    {
      'id': 'vitamin_d',
      'name': 'Vitamine D',
      'icon': Icons.wb_sunny_rounded,
      'dosage': '2000 IU',
      'timing': SupplementTiming.morning,
    },
    {
      'id': 'zinc',
      'name': 'Zinc',
      'icon': Icons.shield_rounded,
      'dosage': '25mg',
      'timing': SupplementTiming.evening,
    },
    {
      'id': 'magnesium',
      'name': 'Magnésium',
      'icon': Icons.flash_on_rounded,
      'dosage': '400mg',
      'timing': SupplementTiming.evening,
    },
  ];

  static SupplementEntry fromCatalogId(String id) {
    final data = supplements.firstWhere((s) => s['id'] == id);
    return SupplementEntry(
      id: data['id'] as String,
      name: data['name'] as String,
      icon: data['icon'] as IconData,
      dosage: data['dosage'] as String,
      timing: data['timing'] as SupplementTiming,
    );
  }
}
