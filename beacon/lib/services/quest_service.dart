import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beacon/data/quest_model.dart';
import 'package:beacon/services/gemini_service.dart';

class QuestService {
  static final QuestService instance = QuestService._internal();
  QuestService._internal();

  static const String _questsKey = 'daily_quests';
  static const String _lastGeneratedKey = 'last_quest_generation';
  
  final List<String> _categories = [
    'Commuters',
    'Dorming',
    'Club',
    'Educational',
    'Major mix',
    'Social'
  ];

  /// Get quests - generates new ones if none exist or if it's a new day
  Future<List<Quest>> getQuests() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we need to generate new quests
    final lastGenerated = prefs.getString(_lastGeneratedKey);
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    if (lastGenerated == null || lastGenerated != today) {
      // Generate new quests for today
      return await _generateAndSaveQuests();
    }
    
    // Load existing quests
    final questsJson = prefs.getString(_questsKey);
    if (questsJson == null) {
      // No quests saved, generate new ones
      return await _generateAndSaveQuests();
    }
    
    // Parse saved quests
    try {
      final List<dynamic> questsList = jsonDecode(questsJson);
      return questsList.map((json) => Quest.fromJson(json)).toList();
    } catch (e) {
      // Error parsing, generate new quests
      return await _generateAndSaveQuests();
    }
  }

  /// Generate new quests and save them
  Future<List<Quest>> _generateAndSaveQuests() async {
    try {
      // Generate 3 quests
      final generatedQuests = await GeminiService.instance.generateQuests(
        category: _categories[0], // Use first category as default
        count: 3,
      );

      final List<Quest> quests = [];
      for (int i = 0; i < generatedQuests.length; i++) {
        final questData = generatedQuests[i];
        
        // Use the category from the generated quest if available, otherwise use a default
        final category = questData['category']?.toString() ?? 
                        _categories[i % _categories.length];
        
        // Map difficulty string to enum
        QuestDifficulty difficulty;
        switch (questData['difficulty']?.toString().toLowerCase()) {
          case 'easy':
            difficulty = QuestDifficulty.easy;
            break;
          case 'hard':
            difficulty = QuestDifficulty.hard;
            break;
          case 'epic':
            difficulty = QuestDifficulty.epic;
            break;
          default:
            difficulty = QuestDifficulty.medium;
        }

        // Get category icon
        String icon = _getCategoryIcon(category);

        quests.add(Quest(
          id: 'quest_$i',
          title: questData['title']?.toString() ?? 'Quest',
          description: questData['description']?.toString() ?? '',
          category: category,
          xpReward: questData['points'] ?? 20,
          currentProgress: 0,
          targetProgress: 1,
          icon: icon,
          isCompleted: false,
          difficulty: difficulty,
        ));
      }

      // Save quests to SharedPreferences
      await _saveQuests(quests);
      
      return quests;
    } catch (e) {
      rethrow;
    }
  }

  /// Save quests to SharedPreferences
  Future<void> _saveQuests(List<Quest> quests) async {
    final prefs = await SharedPreferences.getInstance();
    final questsJson = jsonEncode(quests.map((q) => q.toJson()).toList());
    await prefs.setString(_questsKey, questsJson);
    
    // Save today's date
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString(_lastGeneratedKey, today);
  }

  /// Update quest progress
  Future<void> updateQuestProgress(String questId, int progress) async {
    final quests = await getQuests();
    final questIndex = quests.indexWhere((q) => q.id == questId);
    
    if (questIndex != -1) {
      final quest = quests[questIndex];
      final updatedQuest = Quest(
        id: quest.id,
        title: quest.title,
        description: quest.description,
        category: quest.category,
        xpReward: quest.xpReward,
        currentProgress: progress,
        targetProgress: quest.targetProgress,
        icon: quest.icon,
        isCompleted: progress >= quest.targetProgress,
        difficulty: quest.difficulty,
      );
      
      quests[questIndex] = updatedQuest;
      await _saveQuests(quests);
    }
  }

  /// Force regenerate quests (useful for testing or manual refresh)
  Future<List<Quest>> regenerateQuests() async {
    return await _generateAndSaveQuests();
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'Commuters':
        return '🚌';
      case 'Dorming':
        return '🏠';
      case 'Club':
        return '🎭';
      case 'Educational':
        return '📚';
      case 'Major mix':
        return '🎓';
      case 'Social':
        return '🤝';
      default:
        return '⭐';
    }
  }
}
