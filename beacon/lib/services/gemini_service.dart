import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  GenerativeModel? _model;

  String? get _apiKey =>  "AIzaSyCGsmVzvojSoSsDNxDpAAyCX2DvdbC8oas";

  Future<void> initialize() async {
    final key = _apiKey;
    if (key == null || key.isEmpty) {
      debugPrint('GEMINI_API_KEY not set.');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: key,
    );
  }

  /// Generates a rare wolf emoji/skin description based on gaming themes
  Future<String> generateWolfSkinDescription() async {
    try {
      if (_model == null) await initialize();
      if (_model == null) {
        return '🐺 Epic Silver Wolf - A majestic wolf with shimmering silver fur and piercing blue eyes.';
      }

      // Generate wolf skin description with gaming/fantasy theme
      final prompt = '''
Generate a detailed description for a RARE and EPIC wolf character companion skin for a mobile gaming app that:
1. Is visually striking and feels valuable/prestigious
2. Has unique color variations (not just gray/white - think mystical, elemental, or legendary themes)
3. Includes special effects or patterns (e.g., glowing auras, magical runes, elemental powers, cosmic themes)
4. Has a creative and memorable name
5. Feels like a rare collectible reward
6. The wolves should have distinct personalities reflected in their appearance

Format your response EXACTLY as:
🐺 [Creative Name] - [Detailed visual description in 1-2 sentences, including colors, patterns, and special features]

Examples of good names: "Starlight Sentinel", "Crimson Shadowfang", "Celestial Guardian", "Frost Wraith Alpha"

Make it epic and legendary!
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      
      if (text != null && text.isNotEmpty) {
        return text;
      }
      
      return '🐺 Mystic Wolf - A legendary wolf with ethereal silver-blue fur and glowing amber eyes.';
    } catch (e) {
      debugPrint('Error generating wolf skin: $e');
      return '🐺 Legendary Wolf - A powerful wolf with midnight black fur streaked with gold, radiating mystical energy.';
    }
  }

  /// Generates a custom wolf emoji based on user's quest completion
  Future<Map<String, dynamic>> generateCustomWolfSkin({
    required int questsCompleted,
    required int userLevel,
  }) async {
    try {
      if (_model == null) await initialize();

      final description = await generateWolfSkinDescription();
      
      // Parse the generated description
      final parts = description.split(' - ');
      final name = parts.isNotEmpty ? parts[0].replaceAll('🐺', '').trim() : 'Rare Wolf';
      final details = parts.length > 1 ? parts[1] : description;

      return {
        'id': 'wolf_${DateTime.now().millisecondsSinceEpoch}',
        'name': name,
        'emoji': '🐺',
        'description': details,
        'rarity': 'Epic',
        'unlockedAt': DateTime.now().toIso8601String(),
        'questsCompleted': questsCompleted,
        'userLevel': userLevel,
      };
    } catch (e) {
      debugPrint('Error generating custom wolf skin: $e');
      return {
        'id': 'wolf_default',
        'name': 'Mystic Wolf',
        'emoji': '🐺',
        'description': 'A legendary wolf companion with shimmering fur and ancient power.',
        'rarity': 'Epic',
        'unlockedAt': DateTime.now().toIso8601String(),
        'questsCompleted': questsCompleted,
        'userLevel': userLevel,
      };
    }
  }
}
