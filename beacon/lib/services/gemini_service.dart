import 'dart:convert';
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
      model: 'gemini-1.5-flash',
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

Examples of good responses:
🐺 Starlight Sentinel - A magnificent wolf with deep indigo fur that shimmers with countless stars, eyes glowing with cosmic energy and a celestial aura that leaves trails of stardust.
🐺 Crimson Shadowfang - A fierce wolf with crimson and black fur patterns, glowing red eyes, and dark smoke emanating from its paws as it moves through shadows.
🐺 Frost Wraith Alpha - A spectral wolf with ice-blue and white fur covered in crystalline frost patterns, leaving frozen pawprints and surrounded by swirling snowflakes.

Make it epic and legendary! Remember to START with the wolf emoji 🐺
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      
      if (text != null && text.isNotEmpty) {
        // Ensure it starts with wolf emoji
        if (!text.startsWith('🐺')) {
          return '🐺 $text';
        }
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
      
      // Parse the generated description: "🐺 Name - Description"
      String emoji = '🐺';
      String name = 'Rare Wolf';
      String details = description;
      
      // Extract emoji if present
      if (description.contains('🐺')) {
        emoji = '🐺';
        final withoutEmoji = description.replaceFirst('🐺', '').trim();
        
        // Split by " - " to separate name and description
        if (withoutEmoji.contains(' - ')) {
          final parts = withoutEmoji.split(' - ');
          name = parts[0].trim();
          details = parts.length > 1 ? parts[1].trim() : withoutEmoji;
        } else {
          name = withoutEmoji;
        }
      }

      return {
        'id': 'wolf_${DateTime.now().millisecondsSinceEpoch}',
        'name': name,
        'emoji': emoji,
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

  /// Generates new campus quests based on existing quest patterns from Quests.txt
  /// 
  /// This method uses Gemini AI trained on quest examples to generate contextual,
  /// campus-appropriate quests that encourage social interaction and exploration.
  /// 
  /// **Parameters:**
  /// - `category`: Quest category (e.g., 'Social', 'Educational', 'Commuters', 'Dorming', 'Club', 'Major mix')
  /// - `count`: Number of quests to generate (default: 5)
  /// 
  /// **Returns:** List of quest maps with structure:
  /// ```dart
  /// {
  ///   'title': 'Quest title',
  ///   'description': 'Quest description',
  ///   'category': 'Category name',
  ///   'difficulty': 'easy|medium|hard|epic',
  ///   'points': 10-50
  /// }
  /// ```
  /// 
  /// **Example usage:**
  /// ```dart
  /// final quests = await GeminiService.instance.generateQuests(
  ///   category: 'Social',
  ///   count: 3,
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> generateQuests({
    required String category,
    int count = 5,
  }) async {
    try {
      if (_model == null) await initialize();
      if (_model == null) return _getFallbackQuests(category);

      final trainingData = '''
Example quests from Quests.txt organized by category:

Commuters:
- Find 2 random commuters walking
- Tell 5 commuters which bus they take to go to lot 40
- Ask a commuter how long it takes them to get to SBU
- Ask a commuter how long they stay at campus
- Visit lot 40

Dorming:
- Find 2 random dormers sitting
- Visit at least 2 different dorming centers
- Ask a dormer what's the best spot to hangout in SBU
- Ask a dormer what's the best place to study
- Ask a dormer how is campus life after school hours

Club:
- Go to 3 different club meetings
- Go to a club meeting relating to your major
- Go to a club meeting not relating to your major
- Join at least one club
- Take a selfie with an advisory board member

Educational:
- Go to the tutoring center for any help
- Help someone with their homework
- Go to a professors office hours
- Form a study group
- Teach someone material from one of your classes like a professor would

Major mix:
- Find a CS major and ask them if Windows or Mac is better?
- Find a AMS major and tell them give their best interpretation of Taylor series
- Find a Chem major and ask what track they plan on going for
- Ask a business major what was their most difficult class
- Ask a English major if having an em dash in an essay complicates things

Social:
- Compliment 2 strangers on campus
- Participate in SBU's Hackathon
- Have a gym partner
- Host or participate in a volleyball match
- Take a funny selfie with a stranger
- Ask a stranger if they had a good day so far
''';

      final prompt = '''
You are a campus quest generator for Stony Brook University (SBU). Based on the training data above, generate $count NEW and CREATIVE quests for the "$category" category.

IMPORTANT GUIDELINES:
1. Follow the same style and structure as the training examples
2. Keep quests short, actionable, and campus-appropriate
3. Make them social, interactive, and encourage real human connections
4. Mix quantitative tasks (numbers) with qualitative interactions
5. Be specific to college campus life
6. Don't repeat the exact training examples - be creative!
7. Quests should be achievable in a single day on campus

$trainingData

Generate $count quests for category: "$category"

Format your response as a JSON array of objects with this structure:
[
  {
    "title": "Short quest title",
    "description": "Quest description",
    "category": "$category",
    "difficulty": "easy|medium|hard",
    "points": 10-50
  }
]

Respond ONLY with valid JSON, no other text.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      // Extract JSON from response (handle markdown code blocks)
      String jsonText = text;
      if (text.contains('```json')) {
        jsonText = text.split('```json')[1].split('```')[0].trim();
      } else if (text.contains('```')) {
        jsonText = text.split('```')[1].split('```')[0].trim();
      }

      // Parse JSON
      try {
        final decoded = jsonDecode(jsonText) as List<dynamic>;
        final quests = decoded.map((item) {
          final quest = item as Map<String, dynamic>;
          return {
            'title': quest['title']?.toString() ?? 'Generated Quest',
            'description': quest['description']?.toString() ?? '',
            'category': quest['category']?.toString() ?? category,
            'difficulty': quest['difficulty']?.toString() ?? 'medium',
            'points': quest['points'] ?? 20,
          };
        }).toList();
        
        if (quests.isNotEmpty) return quests;
      } catch (e) {
        debugPrint('Error parsing quest JSON: $e');
      }

      return _getFallbackQuests(category);
    } catch (e) {
      debugPrint('Error generating quests: $e');
      return _getFallbackQuests(category);
    }
  }

  /// Fallback quests in case generation fails
  List<Map<String, dynamic>> _getFallbackQuests(String category) {
    final fallbacks = <String, List<Map<String, dynamic>>>{
      'Commuters': [
        {
          'title': 'Bus Route Explorer',
          'description': 'Talk to 3 commuters about their favorite campus spots',
          'category': 'Commuters',
          'difficulty': 'easy',
          'points': 15,
        },
        {
          'title': 'Parking Lot Detective',
          'description': 'Find out which lot has the quickest campus access',
          'category': 'Commuters',
          'difficulty': 'medium',
          'points': 20,
        },
      ],
      'Social': [
        {
          'title': 'Campus Connector',
          'description': 'Make 2 new friends in different buildings',
          'category': 'Social',
          'difficulty': 'medium',
          'points': 25,
        },
        {
          'title': 'Positivity Spreader',
          'description': 'Give genuine compliments to 5 people',
          'category': 'Social',
          'difficulty': 'easy',
          'points': 15,
        },
      ],
      'Educational': [
        {
          'title': 'Knowledge Share',
          'description': 'Help a classmate understand a difficult concept',
          'category': 'Educational',
          'difficulty': 'medium',
          'points': 30,
        },
      ],
    };

    return fallbacks[category] ?? fallbacks['Social']!;
  }
}
