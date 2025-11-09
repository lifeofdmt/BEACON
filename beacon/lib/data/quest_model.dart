import 'package:flutter/material.dart';

class Quest {
  final String id;
  final String title;
  final String description;
  final String category;
  final int xpReward;
  final int currentProgress;
  final int targetProgress;
  final String icon;
  final bool isCompleted;
  final QuestDifficulty difficulty;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.xpReward,
    required this.currentProgress,
    required this.targetProgress,
    required this.icon,
    this.isCompleted = false,
    required this.difficulty,
  });

  double get progressPercentage =>
      currentProgress / targetProgress.clamp(1, double.maxFinite);

  bool get isActive => currentProgress > 0 && !isCompleted;

  Quest copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? xpReward,
    int? currentProgress,
    int? targetProgress,
    String? icon,
    bool? isCompleted,
    QuestDifficulty? difficulty,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      xpReward: xpReward ?? this.xpReward,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
      icon: icon ?? this.icon,
      isCompleted: isCompleted ?? this.isCompleted,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'xpReward': xpReward,
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
      'icon': icon,
      'isCompleted': isCompleted,
      'difficulty': difficulty.name,
    };
  }

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      xpReward: json['xpReward'] as int,
      currentProgress: json['currentProgress'] as int,
      targetProgress: json['targetProgress'] as int,
      icon: json['icon'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      difficulty: QuestDifficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => QuestDifficulty.easy,
      ),
    );
  }
}

enum QuestDifficulty {
  easy,
  medium,
  hard,
  epic;

  String get displayName {
    switch (this) {
      case QuestDifficulty.easy:
        return 'Easy';
      case QuestDifficulty.medium:
        return 'Medium';
      case QuestDifficulty.hard:
        return 'Hard';
      case QuestDifficulty.epic:
        return 'Epic';
    }
  }

  Color get color {
    switch (this) {
      case QuestDifficulty.easy:
        return const Color(0xFF4CAF50);
      case QuestDifficulty.medium:
        return const Color(0xFFFF9800);
      case QuestDifficulty.hard:
        return const Color(0xFFF44336);
      case QuestDifficulty.epic:
        return const Color(0xFF9C27B0);
    }
  }
}
