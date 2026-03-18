import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/services/quiz_engine_service.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/quiz_skill.dart';
import '../../domain/entities/vocabulary_entity.dart';
import 'vocab_providers.dart';
import 'learning_progress_providers.dart';

/// Quiz Engine Service Provider
final quizEngineServiceProvider = Provider<QuizEngineService>((ref) {
  return QuizEngineService();
});

/// Quiz History Box Provider
final quizHistoryBoxProvider = FutureProvider<Box<Map<dynamic, dynamic>>>((ref) async {
  return await Hive.openBox<Map<dynamic, dynamic>>('quiz_history');
});

/// Mistake Book Box Provider
final mistakeBookBoxProvider = FutureProvider<Box<Map<dynamic, dynamic>>>((ref) async {
  return await Hive.openBox<Map<dynamic, dynamic>>('mistake_book');
});

/// Quiz Skills Box Provider
final quizSkillsBoxProvider = FutureProvider<Box<Map<dynamic, dynamic>>>((ref) async {
  return await Hive.openBox<Map<dynamic, dynamic>>('quiz_skills');
});

/// Generate Quiz Questions Provider
final generateQuizQuestionsProvider = FutureProvider.family<List<QuizQuestion>, QuizConfig>(
  (ref, config) async {
    final quizEngine = ref.watch(quizEngineServiceProvider);
    final vocabDatabase = await ref.watch(vocabDatabaseProvider.future);
    
    // 獲取已學習的單字列表
    final learnedWords = await ref.watch(learnedWordsProvider(config.userId).future);
    
    // 如果沒有已學習的單字，返回空列表
    if (learnedWords.isEmpty) {
      return [];
    }
    
    // 獲取所有單字並轉換為 VocabularyEntity
    final allWords = vocabDatabase.words.map((word) {
      return VocabularyEntity(
        lemma: word.lemma,
        type: 'word',
        pos: word.senses.map((s) => s.pos).where((p) => p.isNotEmpty).toList(),
        level: word.level,
        inOfficialList: word.inOfficialList,
        antonyms: word.antonyms,
        senses: word.senses.map((s) => VocabSense(
          senseId: s.senseId,
          pos: s.pos,
          zhDef: s.zhDef,
          enDef: s.enDef,
          examples: s.examples.map((e) => ExamExample(
            text: e.text,
            source: SourceInfo(
              year: e.source.year,
              examType: e.source.examType,
              sectionType: e.source.sectionType,
            ),
          )).toList(),
          generatedExample: s.generatedExample,
        )).toList(),
        frequency: word.frequency != null ? FrequencyData(
          totalAppearances: word.frequency!.totalAppearances,
          testedCount: word.frequency!.testedCount,
          yearSpread: word.frequency!.yearSpread,
          years: word.frequency!.years,
          byRole: word.frequency!.byRole,
          bySection: word.frequency!.bySection,
          byExamType: word.frequency!.byExamType,
          activeTestedCount: word.frequency!.activeTestedCount,
          importanceScore: word.frequency!.importanceScore,
        ) : FrequencyData(
          totalAppearances: 0,
          testedCount: 0,
          yearSpread: 0,
          years: [],
          byRole: {},
          bySection: {},
          byExamType: {},
          activeTestedCount: 0,
          importanceScore: 0.0,
        ),
        rootInfo: word.rootInfo != null ? RootInfo(
          rootBreakdown: word.rootInfo!.rootBreakdown,
          memoryStrategy: word.rootInfo!.memoryStrategy,
        ) : null,
        synonyms: word.synonyms,
        derivedForms: word.derivedForms,
        confusionNotes: word.confusionNotes.map((c) => ConfusionNote(
          confusedWith: c.confusedWith,
          distinction: c.distinction,
          memoryTip: c.memoryTip,
        )).toList(),
      );
    }).toList();
    
    // 根據配置選擇單字
    List<VocabularyEntity> selectedWords;
    if (config.wordIds != null && config.wordIds!.isNotEmpty) {
      // 使用指定的單字
      selectedWords = allWords
          .where((w) => config.wordIds!.contains(w.lemma))
          .toList();
    } else {
      // 只從已學習的單字中選擇
      selectedWords = allWords
          .where((w) => learnedWords.contains(w.lemma))
          .toList();
      
      // 打亂順序並限制數量
      selectedWords.shuffle();
      selectedWords = selectedWords.take(config.questionCount * 2).toList();
    }
    
    // 如果沒有足夠的單字，返回空列表
    if (selectedWords.isEmpty) {
      return [];
    }
    
    // 生成題目
    final questions = <QuizQuestion>[];
    for (final skillType in config.skillTypes) {
      final skillQuestions = quizEngine.generateQuestions(
        words: selectedWords,
        skillType: skillType,
        count: (config.questionCount / config.skillTypes.length).ceil(),
        allWords: allWords,
      );
      questions.addAll(skillQuestions);
    }
    
    // 打亂題目順序
    questions.shuffle();
    
    // 限制題目數量
    return questions.take(config.questionCount).toList();
  },
);

/// Save Quiz Result Provider
final saveQuizResultProvider = FutureProvider.family<void, QuizResult>(
  (ref, result) async {
    final historyBox = await ref.watch(quizHistoryBoxProvider.future);
    final mistakeBox = await ref.watch(mistakeBookBoxProvider.future);
    final skillsBox = await ref.watch(quizSkillsBoxProvider.future);
    
    // 保存測驗歷史
    final historyKey = DateTime.now().millisecondsSinceEpoch.toString();
    await historyBox.put(historyKey, {
      'userId': result.userId,
      'timestamp': DateTime.now().toIso8601String(),
      'totalQuestions': result.totalQuestions,
      'correctCount': result.correctCount,
      'skillTypes': result.skillTypes.map((t) => t.name).toList(),
      'duration': result.duration.inSeconds,
    });
    
    // 保存錯題
    for (final mistake in result.mistakes) {
      final mistakeKey = '${mistake.word}_${DateTime.now().millisecondsSinceEpoch}';
      await mistakeBox.put(mistakeKey, {
        'word': mistake.word,
        'question': mistake.question,
        'userAnswer': mistake.userAnswer,
        'correctAnswer': mistake.correctAnswer,
        'skillType': mistake.skillType.name,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    
    // 更新技能進度
    for (final skillType in result.skillTypes) {
      final skillKey = '${result.userId}_${skillType.name}';
      final existingData = skillsBox.get(skillKey);
      
      QuizSkill skill;
      if (existingData != null) {
        skill = QuizSkill(
          type: skillType,
          totalAttempts: existingData['totalAttempts'] as int? ?? 0,
          correctAttempts: existingData['correctAttempts'] as int? ?? 0,
          consecutiveCorrect: existingData['consecutiveCorrect'] as int? ?? 0,
          lastPracticed: existingData['lastPracticed'] != null
              ? DateTime.parse(existingData['lastPracticed'] as String)
              : null,
          masteryLevel: existingData['masteryLevel'] as double? ?? 0.0,
        );
      } else {
        skill = QuizSkill(type: skillType);
      }
      
      // 計算該技能的正確率
      final skillQuestions = result.questions
          .where((q) => _getSkillTypeForQuestion(q) == skillType)
          .length;
      final skillCorrect = result.questions
          .where((q) => _getSkillTypeForQuestion(q) == skillType)
          .where((q) => result.results[result.questions.indexOf(q)] == true)
          .length;
      
      // 更新技能
      for (var i = 0; i < skillQuestions; i++) {
        final isCorrect = i < skillCorrect;
        skill = skill.recordAttempt(isCorrect: isCorrect);
      }
      
      await skillsBox.put(skillKey, {
        'totalAttempts': skill.totalAttempts,
        'correctAttempts': skill.correctAttempts,
        'consecutiveCorrect': skill.consecutiveCorrect,
        'lastPracticed': skill.lastPracticed?.toIso8601String(),
        'masteryLevel': skill.masteryLevel,
      });
    }
    
    // 本地儲存，無需同步到 Firebase
  },
);

/// Get Quiz Skills Provider
final getQuizSkillsProvider = FutureProvider.family<List<QuizSkill>, String>(
  (ref, userId) async {
    final skillsBox = await ref.watch(quizSkillsBoxProvider.future);
    
    final skills = <QuizSkill>[];
    for (final skillType in QuizSkillType.values) {
      final skillKey = '${userId}_${skillType.name}';
      final data = skillsBox.get(skillKey);
      
      if (data != null) {
        skills.add(QuizSkill(
          type: skillType,
          totalAttempts: data['totalAttempts'] as int? ?? 0,
          correctAttempts: data['correctAttempts'] as int? ?? 0,
          consecutiveCorrect: data['consecutiveCorrect'] as int? ?? 0,
          lastPracticed: data['lastPracticed'] != null
              ? DateTime.parse(data['lastPracticed'] as String)
              : null,
          masteryLevel: data['masteryLevel'] as double? ?? 0.0,
        ));
      } else {
        skills.add(QuizSkill(type: skillType));
      }
    }
    
    return skills;
  },
);

/// Get Mistake Book Provider
final getMistakeBookProvider = FutureProvider.family<List<MistakeEntry>, String>(
  (ref, userId) async {
    final mistakeBox = await ref.watch(mistakeBookBoxProvider.future);
    
    final mistakes = <MistakeEntry>[];
    for (final key in mistakeBox.keys) {
      final data = mistakeBox.get(key);
      if (data != null) {
        mistakes.add(MistakeEntry(
          word: data['word'] as String,
          question: data['question'] as String,
          userAnswer: data['userAnswer'] as String,
          correctAnswer: data['correctAnswer'] as String,
          skillType: QuizSkillType.values.firstWhere(
            (t) => t.name == data['skillType'],
            orElse: () => QuizSkillType.recognition,
          ),
          timestamp: DateTime.parse(data['timestamp'] as String),
        ));
      }
    }
    
    // 按時間倒序排列
    mistakes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return mistakes;
  },
);

/// Get Quiz History Provider
final getQuizHistoryProvider = FutureProvider.family<List<QuizHistoryEntry>, String>(
  (ref, userId) async {
    final historyBox = await ref.watch(quizHistoryBoxProvider.future);
    
    final history = <QuizHistoryEntry>[];
    for (final key in historyBox.keys) {
      final data = historyBox.get(key);
      if (data != null && data['userId'] == userId) {
        history.add(QuizHistoryEntry(
          timestamp: DateTime.parse(data['timestamp'] as String),
          totalQuestions: data['totalQuestions'] as int,
          correctCount: data['correctCount'] as int,
          skillTypes: (data['skillTypes'] as List<dynamic>)
              .map((t) => QuizSkillType.values.firstWhere(
                    (type) => type.name == t,
                    orElse: () => QuizSkillType.recognition,
                  ))
              .toList(),
          duration: Duration(seconds: data['duration'] as int),
        ));
      }
    }
    
    // 按時間倒序排列
    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return history;
  },
);

/// Clear Mistake Book Provider
final clearMistakeBookProvider = FutureProvider.family<void, String>(
  (ref, userId) async {
    final mistakeBox = await ref.watch(mistakeBookBoxProvider.future);
    await mistakeBox.clear();
  },
);

// Helper function to determine skill type from question
QuizSkillType _getSkillTypeForQuestion(QuizQuestion question) {
  if (question is SpellingQuestion) {
    return QuizSkillType.spelling;
  } else if (question is FillInBlankQuestion) {
    return QuizSkillType.fillBlank;
  } else if (question is MultipleChoiceQuestion) {
    // 根據 prompt 判斷是識別還是反向
    if (question.prompt == question.word) {
      return QuizSkillType.recognition;
    } else {
      return QuizSkillType.reverse;
    }
  }
  return QuizSkillType.recognition;
}

/// Quiz Configuration
class QuizConfig {
  final String userId;
  final List<QuizSkillType> skillTypes;
  final int questionCount;
  final List<String>? wordIds;

  QuizConfig({
    required this.userId,
    required this.skillTypes,
    required this.questionCount,
    this.wordIds,
  });
}

/// Quiz Result
class QuizResult {
  final String userId;
  final List<QuizQuestion> questions;
  final Map<int, String> answers;
  final Map<int, bool> results;
  final List<QuizSkillType> skillTypes;
  final Duration duration;

  QuizResult({
    required this.userId,
    required this.questions,
    required this.answers,
    required this.results,
    required this.skillTypes,
    required this.duration,
  });

  int get totalQuestions => questions.length;
  int get correctCount => results.values.where((r) => r).length;
  double get accuracy => totalQuestions > 0 ? correctCount / totalQuestions : 0.0;

  List<MistakeEntry> get mistakes {
    final mistakes = <MistakeEntry>[];
    for (var i = 0; i < questions.length; i++) {
      if (results[i] == false) {
        final question = questions[i];
        mistakes.add(MistakeEntry(
          word: question.word,
          question: question.prompt,
          userAnswer: answers[i] ?? '未作答',
          correctAnswer: question.getCorrectAnswer(),
          skillType: _getSkillTypeForQuestion(question),
          timestamp: DateTime.now(),
        ));
      }
    }
    return mistakes;
  }
}

/// Mistake Entry
class MistakeEntry {
  final String word;
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final QuizSkillType skillType;
  final DateTime timestamp;

  MistakeEntry({
    required this.word,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.skillType,
    required this.timestamp,
  });
}

/// Quiz History Entry
class QuizHistoryEntry {
  final DateTime timestamp;
  final int totalQuestions;
  final int correctCount;
  final List<QuizSkillType> skillTypes;
  final Duration duration;

  QuizHistoryEntry({
    required this.timestamp,
    required this.totalQuestions,
    required this.correctCount,
    required this.skillTypes,
    required this.duration,
  });

  double get accuracy => totalQuestions > 0 ? correctCount / totalQuestions : 0.0;
  int get percentage => (accuracy * 100).round();
}
