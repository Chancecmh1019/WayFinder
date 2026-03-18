import 'dart:math';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/quiz_skill.dart';
import '../../domain/entities/vocabulary_entity.dart';

/// 測驗引擎服務
/// 
/// 負責生成各種題型的測驗題目
class QuizEngineService {
  final Random _random = Random();

  /// 生成測驗題目
  /// 
  /// [words] 單字列表
  /// [skillType] 題型
  /// [count] 題目數量
  /// [allWords] 所有單字（用於生成干擾項）
  List<QuizQuestion> generateQuestions({
    required List<VocabularyEntity> words,
    required QuizSkillType skillType,
    required int count,
    required List<VocabularyEntity> allWords,
  }) {
    final questions = <QuizQuestion>[];
    final selectedWords = _selectWords(words, count);

    for (final word in selectedWords) {
      final question = _generateQuestion(
        word: word,
        skillType: skillType,
        allWords: allWords,
      );
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  /// 選擇單字
  List<VocabularyEntity> _selectWords(List<VocabularyEntity> words, int count) {
    if (words.length <= count) {
      return List.from(words)..shuffle(_random);
    }

    final selected = <VocabularyEntity>[];
    final available = List<VocabularyEntity>.from(words);

    while (selected.length < count && available.isNotEmpty) {
      final index = _random.nextInt(available.length);
      selected.add(available.removeAt(index));
    }

    return selected;
  }

  /// 生成單個題目
  QuizQuestion? _generateQuestion({
    required VocabularyEntity word,
    required QuizSkillType skillType,
    required List<VocabularyEntity> allWords,
  }) {
    switch (skillType) {
      case QuizSkillType.recognition:
        return _generateRecognitionQuestion(word, allWords);
      case QuizSkillType.reverse:
        return _generateReverseQuestion(word, allWords);
      case QuizSkillType.fillBlank:
        return _generateFillBlankQuestion(word);
      case QuizSkillType.spelling:
        return _generateSpellingQuestion(word);
      case QuizSkillType.distinction:
        return _generateDistinctionQuestion(word);
    }
  }

  /// 生成識別題（看英文選中文）
  QuizQuestion _generateRecognitionQuestion(
    VocabularyEntity word,
    List<VocabularyEntity> allWords,
  ) {
    final correctAnswer = word.senses.isNotEmpty 
        ? word.senses.first.zhDef 
        : '定義';

    final distractors = _generateDistractors(
      correct: correctAnswer,
      allWords: allWords,
      count: 3,
      extractor: (w) => w.senses.isNotEmpty ? w.senses.first.zhDef : null,
    );

    final options = [correctAnswer, ...distractors]..shuffle(_random);
    final correctIndex = options.indexOf(correctAnswer);

    return MultipleChoiceQuestion(
      word: word.lemma,
      type: QuestionType.multipleChoice,
      prompt: word.lemma,
      vocabularyEntity: word,
      options: options,
      correctIndex: correctIndex,
    );
  }

  /// 生成反向題（看中文選英文）
  QuizQuestion _generateReverseQuestion(
    VocabularyEntity word,
    List<VocabularyEntity> allWords,
  ) {
    final prompt = word.senses.isNotEmpty 
        ? word.senses.first.zhDef 
        : '定義';
    final correctAnswer = word.lemma;

    final distractors = _generateDistractors(
      correct: correctAnswer,
      allWords: allWords,
      count: 3,
      extractor: (w) => w.lemma,
    );

    final options = [correctAnswer, ...distractors]..shuffle(_random);
    final correctIndex = options.indexOf(correctAnswer);

    return MultipleChoiceQuestion(
      word: word.lemma,
      type: QuestionType.multipleChoice,
      prompt: prompt,
      vocabularyEntity: word,
      options: options,
      correctIndex: correctIndex,
    );
  }

  /// 生成填空題
  QuizQuestion? _generateFillBlankQuestion(VocabularyEntity word) {
    // 優先使用 generatedExample
    for (final sense in word.senses) {
      if (sense.generatedExample != null && sense.generatedExample!.isNotEmpty) {
        final example = sense.generatedExample!;
        
        // 將單字替換為空格（不區分大小寫）
        final blankedSentence = example.replaceAll(
          RegExp(word.lemma, caseSensitive: false),
          '______',
        );

        // 如果替換成功，返回題目
        if (blankedSentence != example) {
          return FillInBlankQuestion(
            word: word.lemma,
            prompt: '請填入適當的單字',
            vocabularyEntity: word,
            sentenceWithBlank: blankedSentence,
            correctWord: word.lemma,
            acceptableAnswers: [
              word.lemma,
              word.lemma.toLowerCase(),
              word.lemma.toUpperCase(),
            ],
          );
        }
      }
    }

    // 如果沒有 generatedExample，嘗試使用真實例句
    for (final sense in word.senses) {
      if (sense.examples.isNotEmpty) {
        final example = sense.examples.first.text;
        
        // 將單字替換為空格
        final blankedSentence = example.replaceAll(
          RegExp(word.lemma, caseSensitive: false),
          '______',
        );

        // 如果替換成功，返回題目
        if (blankedSentence != example) {
          return FillInBlankQuestion(
            word: word.lemma,
            prompt: '請填入適當的單字',
            vocabularyEntity: word,
            sentenceWithBlank: blankedSentence,
            correctWord: word.lemma,
            acceptableAnswers: [
              word.lemma,
              word.lemma.toLowerCase(),
              word.lemma.toUpperCase(),
            ],
          );
        }
      }
    }

    // 如果都沒有例句，改為生成識別題
    return _generateRecognitionQuestion(word, []);
  }

  /// 生成拼寫題
  QuizQuestion _generateSpellingQuestion(VocabularyEntity word) {
    final definition = word.senses.isNotEmpty 
        ? word.senses.first.zhDef 
        : '定義';

    // 音訊 URL 留空，讓 SpellingQuestion 使用 TTS 播放單字發音
    // TTS 會在 UI 層自動處理
    const String audioUrl = '';

    return SpellingQuestion(
      word: word.lemma,
      prompt: definition,
      vocabularyEntity: word,
      audioUrl: audioUrl,
      definition: definition,
    );
  }

  /// 生成辨析題
  QuizQuestion? _generateDistinctionQuestion(VocabularyEntity word) {
    // 找易混淆詞
    if (word.confusionNotes.isEmpty) {
      // 如果沒有易混淆詞，改為生成反向題
      return _generateReverseQuestion(word, []);
    }

    final confusionNote = word.confusionNotes.first;
    final confusedWord = confusionNote.confusedWith;

    final prompt = '「${word.lemma}」和「$confusedWord」的區別是什麼？';

    // 使用選擇題形式
    final options = [
      confusionNote.distinction,
      '它們的意思完全相同',
      '它們的詞性不同',
      '它們的發音不同',
    ]..shuffle(_random);

    final correctIndex = options.indexOf(confusionNote.distinction);

    return MultipleChoiceQuestion(
      word: word.lemma,
      type: QuestionType.multipleChoice,
      prompt: prompt,
      vocabularyEntity: word,
      options: options,
      correctIndex: correctIndex,
    );
  }

  /// 生成干擾項
  List<String> _generateDistractors({
    required String correct,
    required List<VocabularyEntity> allWords,
    required int count,
    required String? Function(VocabularyEntity) extractor,
  }) {
    final distractors = <String>[];
    final available = allWords
        .map(extractor)
        .where((s) => s != null && s != correct)
        .cast<String>()
        .toList()
      ..shuffle(_random);

    for (var i = 0; i < available.length && distractors.length < count; i++) {
      if (!distractors.contains(available[i])) {
        distractors.add(available[i]);
      }
    }

    // 如果不夠，補充通用干擾項
    while (distractors.length < count) {
      distractors.add('選項 ${distractors.length + 1}');
    }

    return distractors;
  }
}
