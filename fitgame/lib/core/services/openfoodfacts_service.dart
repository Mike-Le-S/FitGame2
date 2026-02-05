import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';

  /// Search for a product by barcode
  static Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/product/$barcode'),
        headers: {
          'User-Agent': 'FitGame/1.0 (Flutter App)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 1 && data['product'] != null) {
          return _parseProduct(data['product']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('OpenFoodFacts error: $e');
      return null;
    }
  }

  /// Search products by name
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?search_terms=$query&page_size=20&json=1'),
        headers: {
          'User-Agent': 'FitGame/1.0 (Flutter App)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List? ?? [];

        return products
            .map((p) => _parseProduct(p))
            .where((p) => p != null)
            .cast<Map<String, dynamic>>()
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('OpenFoodFacts search error: $e');
      return [];
    }
  }

  static Map<String, dynamic>? _parseProduct(Map<String, dynamic> product) {
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    // Get values per 100g
    final calories = nutriments['energy-kcal_100g'] ??
                     nutriments['energy_100g']?.toDouble()?.div(4.184) ?? 0;
    final protein = nutriments['proteins_100g'] ?? 0;
    final carbs = nutriments['carbohydrates_100g'] ?? 0;
    final fat = nutriments['fat_100g'] ?? 0;

    final name = product['product_name'] ?? product['product_name_fr'];
    if (name == null || name.toString().isEmpty) return null;

    final calRounded = (calories is num) ? calories.round() : 0;
    final pRounded = (protein is num) ? protein.round() : 0;
    final cRounded = (carbs is num) ? carbs.round() : 0;
    final fRounded = (fat is num) ? fat.round() : 0;

    return {
      'name': name,
      'brand': product['brands'] ?? '',
      'barcode': product['code'] ?? '',
      'quantity': '100g',
      'cal': calRounded,
      'p': pRounded,
      'c': cRounded,
      'f': fRounded,
      'per_100g': {
        'cal': calRounded,
        'p': pRounded,
        'c': cRounded,
        'f': fRounded,
      },
      'image_url': product['image_url'] ?? product['image_front_url'],
    };
  }
}
