import 'dart:math';
import '../entities/entities.dart';

/// Quiz engine service for generating questions based on proficiency level
class QuizEngine {
  final Random _random;

  QuizEngine({Random? random}) : _random = random ?? Random();

  /// Generate a question based on word and proficiency level
  QuizQuestion generateQuestion({
    required VocabularyEntity word,
    required ProficiencyLevel proficiency,
    required List<VocabularyEntity> distractors,
  }) {
    // Map proficiency to question type
    final questionType = _getQuestionTypeForProficiency(proficiency);

    switch (questionType) {
      case QuestionType.multipleChoice:
        return _generateMultipleChoiceQuestion(word, distractors);
      case QuestionType.fillInBlank:
        return _generateFillInBlankQuestion(word);
      case QuestionType.spelling:
        return _generateSpellingQuestion(word);
      case QuestionType.sentenceCompletion:
        return _generateSentenceCompletionQuestion(word);
      case QuestionType.listening:
        // Listening is similar to spelling but with audio emphasis
        return _generateSpellingQuestion(word);
    }
  }

  /// Map proficiency level to appropriate question type
  QuestionType _getQuestionTypeForProficiency(ProficiencyLevel proficiency) {
    switch (proficiency) {
      case ProficiencyLevel.beginner:
      case ProficiencyLevel.learning:
        // Proficiency 0-1: Multiple choice
        return QuestionType.multipleChoice;
      case ProficiencyLevel.familiar:
      case ProficiencyLevel.proficient:
        // Proficiency 2-3: Fill in blank or listening
        return _random.nextBool()
            ? QuestionType.fillInBlank
            : QuestionType.listening;
      case ProficiencyLevel.mastered:
      case ProficiencyLevel.expert:
        // Proficiency 4-5: Spelling or sentence completion
        return _random.nextBool()
            ? QuestionType.spelling
            : QuestionType.sentenceCompletion;
    }
  }

  /// Generate multiple choice question
  MultipleChoiceQuestion _generateMultipleChoiceQuestion(
    VocabularyEntity word,
    List<VocabularyEntity> distractors,
  ) {
    // Create options: correct answer + 3 distractors
    final options = <String>[];
    final correctIndex = _random.nextInt(4); // Random position for correct answer

    // Add distractors
    final selectedDistractors = distractors.take(3).toList();
    int distractorIndex = 0;

    for (int i = 0; i < 4; i++) {
      if (i == correctIndex) {
        options.add(word.lemma);
      } else if (distractorIndex < selectedDistractors.length) {
        options.add(selectedDistractors[distractorIndex].lemma);
        distractorIndex++;
      } else {
        // Fallback if not enough distractors
        options.add('選項 ${i + 1}');
      }
    }

    // Create prompt based on definition
    final prompt = word.senses.isNotEmpty
        ? '選擇正確的單字: "${word.senses.first.zhDef}"'
        : '選擇正確的單字';

    return MultipleChoiceQuestion(
      word: word.lemma,
      type: QuestionType.multipleChoice,
      prompt: prompt,
      vocabularyEntity: word,
      options: options,
      correctIndex: correctIndex,
    );
  }

  /// Generate fill in the blank question
  FillInBlankQuestion _generateFillInBlankQuestion(VocabularyEntity word) {
    // Use an example sentence if available
    String sentenceWithBlank;
    final allExamples = [word].expand((s) => [s].expand((s) => s.senses.first.examples).toList()).toList();
    
    if (allExamples.isNotEmpty) {
      final example = allExamples[_random.nextInt(allExamples.length)].text;
      // Replace the word with blank
      sentenceWithBlank = example.replaceAll(
        RegExp(word.lemma, caseSensitive: false),
        '___',
      );
    } else {
      // Create a simple sentence if no examples
      sentenceWithBlank = 'The ___ is important.';
    }

    // Generate acceptable answers (include variations)
    final acceptableAnswers = [
      word.lemma,
      word.lemma.toLowerCase(),
      word.lemma.toUpperCase(),
    ];

    return FillInBlankQuestion(
      word: word.lemma,
      prompt: '填入正確的單字',
      vocabularyEntity: word,
      sentenceWithBlank: sentenceWithBlank,
      correctWord: word.lemma,
      acceptableAnswers: acceptableAnswers,
    );
  }

  /// Generate spelling question
  SpellingQuestion _generateSpellingQuestion(VocabularyEntity word) {
    final definition = word.senses.isNotEmpty
        ? word.senses.first.zhDef
        : '請拼寫這個單字';

    return SpellingQuestion(
      word: word.lemma,
      prompt: '聽音拼字 (或根據定義拼寫)',
      vocabularyEntity: word,
      audioUrl: '', // Audio URL would be in sense data
      definition: definition,
    );
  }

  /// Generate sentence completion question
  SentenceCompletionQuestion _generateSentenceCompletionQuestion(
    VocabularyEntity word,
  ) {
    // Use an example sentence if available
    String sentenceStart = 'Please use the word';
    String sentenceEnd = 'in a sentence.';

    final allExamples = [word].expand((s) => [s].expand((s) => s.senses.first.examples).toList()).toList();
    if (allExamples.isNotEmpty) {
      final example = allExamples[_random.nextInt(allExamples.length)].text;
      final sentence = example;

      // Try to split the sentence around the word
      final wordIndex = sentence.toLowerCase().indexOf(word.lemma.toLowerCase());
      if (wordIndex != -1) {
        sentenceStart = sentence.substring(0, wordIndex).trim();
        final endIndex = wordIndex + word.lemma.length;
        sentenceEnd = endIndex < sentence.length
            ? sentence.substring(endIndex).trim()
            : '';
      }
    }

    // Generate acceptable completions
    final acceptableCompletions = [
      word.lemma,
      word.lemma.toLowerCase(),
    ];

    return SentenceCompletionQuestion(
      word: word.lemma,
      prompt: '用這個單字完成句子',
      vocabularyEntity: word,
      sentenceStart: sentenceStart,
      sentenceEnd: sentenceEnd,
      acceptableCompletions: acceptableCompletions,
    );
  }

  /// Generate distractors for multiple choice questions
  /// This is a placeholder - will be enhanced with Datamuse API integration
  List<VocabularyEntity> generateDistractors({
    required VocabularyEntity targetWord,
    required List<VocabularyEntity> vocabularyPool,
    required int count,
  }) {
    // Filter out the target word
    final candidates = vocabularyPool
        .where((word) => word.lemma != targetWord.lemma)
        .toList();

    if (candidates.isEmpty) {
      return [];
    }

    // Prioritize words with similar characteristics
    final similarWords = _findSimilarWords(targetWord, candidates);

    // Shuffle and take the requested count
    similarWords.shuffle(_random);
    return similarWords.take(count).toList();
  }

  /// Find words similar to the target word
  List<VocabularyEntity> _findSimilarWords(
    VocabularyEntity targetWord,
    List<VocabularyEntity> candidates,
  ) {
    final similar = <VocabularyEntity>[];

    // Priority 1: Same level
    final sameLevelWords = candidates
        .where((word) => word.level == targetWord.level)
        .toList();

    // Priority 2: Same part of speech
    final samePartOfSpeech = candidates.where((word) {
      return word.pos.any(
        (pos) => targetWord.pos.contains(pos),
      );
    }).toList();

    // Priority 3: Similar word length (±2 characters)
    final similarLength = candidates.where((word) {
      final lengthDiff = (word.lemma.length - targetWord.lemma.length).abs();
      return lengthDiff <= 2;
    }).toList();

    // Combine with priority
    similar.addAll(sameLevelWords);
    similar.addAll(samePartOfSpeech);
    similar.addAll(similarLength);

    // Remove duplicates
    final uniqueSimilar = similar.toSet().toList();

    // If still not enough, add random words
    if (uniqueSimilar.length < 10) {
      final remaining = candidates
          .where((word) => !uniqueSimilar.contains(word))
          .toList();
      remaining.shuffle(_random);
      uniqueSimilar.addAll(remaining.take(10 - uniqueSimilar.length));
    }

    return uniqueSimilar;
  }
}
