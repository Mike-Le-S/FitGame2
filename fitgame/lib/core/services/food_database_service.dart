import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Service for searching the bilingual food database (CIQUAL + USDA).
///
/// Loads 10,000+ foods with complete nutritional data from assets.
/// Supports search in French AND English.
class FoodDatabaseService {
  static FoodDatabaseService? _instance;
  static FoodDatabaseService get instance => _instance ??= FoodDatabaseService._();

  FoodDatabaseService._();

  List<Map<String, dynamic>>? _foods;
  Map<String, List<Map<String, dynamic>>>? _byCategory;
  bool _isLoading = false;
  int _ciqualCount = 0;
  int _usdaCount = 0;

  /// Whether the database is loaded and ready
  bool get isLoaded => _foods != null;

  /// Total number of foods in the database
  int get foodCount => _foods?.length ?? 0;

  /// French foods count (CIQUAL)
  int get frenchFoodCount => _ciqualCount;

  /// English foods count (USDA)
  int get englishFoodCount => _usdaCount;

  /// All available categories
  List<String> get categories {
    if (_byCategory == null) return [];
    final cats = _byCategory!.keys.toList();
    cats.sort();
    return cats;
  }

  /// Load the database from assets (lazy, called once)
  Future<void> load() async {
    if (_foods != null || _isLoading) return;

    _isLoading = true;
    try {
      final jsonString = await rootBundle.loadString('assets/data/food_database.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;

      _foods = List<Map<String, dynamic>>.from(
        (data['foods'] as List).map((f) => Map<String, dynamic>.from(f as Map)),
      );

      _ciqualCount = data['ciqual_count'] as int? ?? 0;
      _usdaCount = data['usda_count'] as int? ?? 0;

      // Build category index
      _byCategory = {};
      for (final food in _foods!) {
        final category = food['category'] as String? ?? 'Autre';
        _byCategory!.putIfAbsent(category, () => []).add(food);
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Search foods by name in BOTH French and English (case-insensitive)
  Future<List<Map<String, dynamic>>> search(String query, {int limit = 50}) async {
    await load();
    if (_foods == null || query.isEmpty) return [];

    final queryLower = query.toLowerCase().trim();
    final words = queryLower.split(RegExp(r'\s+'));

    // Score-based search
    final scored = <MapEntry<Map<String, dynamic>, int>>[];

    for (final food in _foods!) {
      // Search in both French and English names
      final nameFr = (food['name_fr'] as String? ?? '').toLowerCase();
      final nameEn = (food['name_en'] as String? ?? '').toLowerCase();
      final name = (food['name'] as String? ?? '').toLowerCase();

      int score = 0;

      // Check French name first (priority for French users)
      score = _scoreMatch(nameFr, queryLower, words, bonus: 10);

      // Also check English name
      final enScore = _scoreMatch(nameEn, queryLower, words);
      if (enScore > score) score = enScore;

      // Fallback to 'name' field
      if (score == 0 && name.isNotEmpty) {
        score = _scoreMatch(name, queryLower, words);
      }

      if (score > 0) {
        scored.add(MapEntry(food, score));
      }
    }

    // Sort by score descending
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.take(limit).map((e) => e.key).toList();
  }

  int _scoreMatch(String name, String query, List<String> words, {int bonus = 0}) {
    if (name.isEmpty) return 0;

    // Normalize: remove accents for comparison
    final nameNorm = _normalize(name);
    final queryNorm = _normalize(query);
    final wordsNorm = words.map(_normalize).toList();

    // 1. Exact match = highest score
    if (nameNorm == queryNorm) {
      return 10000 + bonus;
    }

    // 2. Name starts with exact query (e.g., "huile d'olive" matches "Huile d'olive vierge")
    if (nameNorm.startsWith(queryNorm)) {
      // Shorter names score higher (more specific)
      return 5000 + (200 - name.length).clamp(0, 100) + bonus;
    }

    // 3. Query is contained as a whole phrase
    if (nameNorm.contains(queryNorm)) {
      // Position matters: earlier = better
      final pos = nameNorm.indexOf(queryNorm);
      final posBonus = (100 - pos).clamp(0, 100);
      // Shorter names score higher
      final lengthBonus = (100 - name.length).clamp(0, 50);
      return 2000 + posBonus + lengthBonus + bonus;
    }

    // 4. All words present (in any order)
    if (wordsNorm.every((w) => nameNorm.contains(w))) {
      // Check if words appear in order
      bool inOrder = true;
      int lastIndex = -1;
      for (final w in wordsNorm) {
        final idx = nameNorm.indexOf(w, lastIndex + 1);
        if (idx <= lastIndex) {
          inOrder = false;
          break;
        }
        lastIndex = idx;
      }
      final orderBonus = inOrder ? 200 : 0;
      final lengthBonus = (100 - name.length).clamp(0, 50);
      return 500 + orderBonus + lengthBonus + bonus;
    }

    // 5. Most words present
    final matchCount = wordsNorm.where((w) => nameNorm.contains(w)).length;
    if (matchCount > 0) {
      final ratio = matchCount / wordsNorm.length;
      return (ratio * 200).round() + bonus;
    }

    return 0;
  }

  /// Normalize string: lowercase and remove accents
  String _normalize(String s) {
    const accents = 'àáâãäåèéêëìíîïòóôõöùúûüýÿñç';
    const normal = 'aaaaaaeeeeiiiiooooouuuuyync';
    var result = s.toLowerCase();
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], normal[i]);
    }
    return result;
  }

  /// Get foods by category
  Future<List<Map<String, dynamic>>> getByCategory(String category, {int limit = 50}) async {
    await load();
    final foods = _byCategory?[category] ?? [];
    return foods.take(limit).toList();
  }

  /// Get a food by its USDA ID
  Future<Map<String, dynamic>?> getById(String id) async {
    await load();
    return _foods?.firstWhere(
      (f) => f['id'] == id,
      orElse: () => <String, dynamic>{},
    );
  }

  /// Convert USDA food format to app's food format
  static Map<String, dynamic> toAppFormat(Map<String, dynamic> usdaFood) {
    final nutrients = usdaFood['nutrients'] as Map<String, dynamic>? ?? {};

    return {
      'name': usdaFood['name'] ?? 'Aliment',
      'quantity': usdaFood['serving'] ?? '100g',
      'cal': (nutrients['energy_kcal'] as num?)?.round() ?? 0,
      'protein': (nutrients['protein_g'] as num?)?.round() ?? 0,
      'carbs': (nutrients['carbs_g'] as num?)?.round() ?? 0,
      'fat': (nutrients['fat_g'] as num?)?.round() ?? 0,
      'fiber': (nutrients['fiber_g'] as num?)?.round() ?? 0,
      'sugar': (nutrients['sugar_g'] as num?)?.round() ?? 0,
      'sodium': (nutrients['sodium_mg'] as num?)?.round() ?? 0,
      // Extended nutrients
      'sat_fat': nutrients['sat_fat_g'],
      'mono_fat': nutrients['mono_fat_g'],
      'poly_fat': nutrients['poly_fat_g'],
      'trans_fat': nutrients['trans_fat_g'],
      'cholesterol': nutrients['cholesterol_mg'],
      'potassium': nutrients['potassium_mg'],
      'calcium': nutrients['calcium_mg'],
      'iron': nutrients['iron_mg'],
      'magnesium': nutrients['magnesium_mg'],
      'zinc': nutrients['zinc_mg'],
      'phosphorus': nutrients['phosphorus_mg'],
      'selenium': nutrients['selenium_ug'],
      'vit_a': nutrients['vit_a_ug'],
      'vit_c': nutrients['vit_c_mg'],
      'vit_d': nutrients['vit_d_ug'],
      'vit_e': nutrients['vit_e_mg'],
      'vit_k': nutrients['vit_k_ug'],
      'vit_b1': nutrients['vit_b1_mg'],
      'vit_b2': nutrients['vit_b2_mg'],
      'vit_b3': nutrients['vit_b3_mg'],
      'vit_b6': nutrients['vit_b6_mg'],
      'vit_b12': nutrients['vit_b12_ug'],
      'folate': nutrients['folate_ug'],
      // Metadata
      'source': 'usda',
      'usda_id': usdaFood['id'],
      'category': usdaFood['category'],
    };
  }
}
