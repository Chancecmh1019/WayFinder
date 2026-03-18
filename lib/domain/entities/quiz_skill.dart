import 'package:equatable/equatable.dart';

/// 測驗技能類型
enum QuizSkillType {
  recognition,    // 識別（選擇題）
  reverse,        // 反向（中翻英）
  fillBlank,      // 填空
  spelling,       // 拼寫
  distinction,    // 辨析
}

/// 測驗技能進度
/// 
/// 追蹤每種題型的學習進度和掌握度
class QuizSkill extends Equatable {
  final QuizSkillType type;
  final int totalAttempts;      // 總嘗試次數
  final int correctAttempts;    // 正確次數
  final int consecutiveCorrect; // 連續正確次數
  final DateTime? lastPracticed; // 最後練習時間
  final double masteryLevel;    // 掌握度 (0.0 - 1.0)

  const QuizSkill({
    required this.type,
    this.totalAttempts = 0,
    this.correctAttempts = 0,
    this.consecutiveCorrect = 0,
    this.lastPracticed,
    this.masteryLevel = 0.0,
  });

  /// 準確率
  double get accuracy => totalAttempts > 0 
      ? correctAttempts / totalAttempts 
      : 0.0;

  /// 是否已掌握（準確率 >= 80% 且至少嘗試 10 次）
  bool get isMastered => accuracy >= 0.8 && totalAttempts >= 10;

  /// 技能名稱（繁體中文）
  String get nameZh {
    switch (type) {
      case QuizSkillType.recognition:
        return '識別';
      case QuizSkillType.reverse:
        return '反向';
      case QuizSkillType.fillBlank:
        return '填空';
      case QuizSkillType.spelling:
        return '拼寫';
      case QuizSkillType.distinction:
        return '辨析';
    }
  }

  /// 技能名稱（英文）
  String get nameEn {
    switch (type) {
      case QuizSkillType.recognition:
        return 'Recognition';
      case QuizSkillType.reverse:
        return 'Reverse';
      case QuizSkillType.fillBlank:
        return 'Fill Blank';
      case QuizSkillType.spelling:
        return 'Spelling';
      case QuizSkillType.distinction:
        return 'Distinction';
    }
  }

  /// 技能描述
  String get description {
    switch (type) {
      case QuizSkillType.recognition:
        return '看英文選中文';
      case QuizSkillType.reverse:
        return '看中文選英文';
      case QuizSkillType.fillBlank:
        return '根據例句填空';
      case QuizSkillType.spelling:
        return '聽音拼寫單字';
      case QuizSkillType.distinction:
        return '辨析易混淆詞';
    }
  }

  /// 記錄答題結果
  QuizSkill recordAttempt({required bool isCorrect}) {
    return QuizSkill(
      type: type,
      totalAttempts: totalAttempts + 1,
      correctAttempts: correctAttempts + (isCorrect ? 1 : 0),
      consecutiveCorrect: isCorrect ? consecutiveCorrect + 1 : 0,
      lastPracticed: DateTime.now(),
      masteryLevel: _calculateMasteryLevel(
        totalAttempts + 1,
        correctAttempts + (isCorrect ? 1 : 0),
        isCorrect ? consecutiveCorrect + 1 : 0,
      ),
    );
  }

  /// 計算掌握度
  double _calculateMasteryLevel(int total, int correct, int consecutive) {
    if (total == 0) return 0.0;
    
    // 基礎準確率 (60%)
    final baseAccuracy = correct / total;
    
    // 連續正確獎勵 (30%)
    final consecutiveBonus = (consecutive / 10).clamp(0.0, 1.0);
    
    // 練習量獎勵 (10%)
    final practiceBonus = (total / 50).clamp(0.0, 1.0);
    
    return (baseAccuracy * 0.6 + consecutiveBonus * 0.3 + practiceBonus * 0.1)
        .clamp(0.0, 1.0);
  }

  QuizSkill copyWith({
    QuizSkillType? type,
    int? totalAttempts,
    int? correctAttempts,
    int? consecutiveCorrect,
    DateTime? lastPracticed,
    double? masteryLevel,
  }) {
    return QuizSkill(
      type: type ?? this.type,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      correctAttempts: correctAttempts ?? this.correctAttempts,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      masteryLevel: masteryLevel ?? this.masteryLevel,
    );
  }

  @override
  List<Object?> get props => [
        type,
        totalAttempts,
        correctAttempts,
        consecutiveCorrect,
        lastPracticed,
        masteryLevel,
      ];
}
