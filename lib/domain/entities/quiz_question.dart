import 'vocabulary_entity.dart';

/// Types of quiz questions
enum QuestionType {
  multipleChoice, // 選擇題
  fillInBlank, // 填空題
  spelling, // 拼字題
  sentenceCompletion, // 句子完成
  listening; // 聽力題

  String get displayName {
    switch (this) {
      case QuestionType.multipleChoice:
        return '選擇題';
      case QuestionType.fillInBlank:
        return '填空題';
      case QuestionType.spelling:
        return '拼字題';
      case QuestionType.sentenceCompletion:
        return '句子完成';
      case QuestionType.listening:
        return '聽力題';
    }
  }
}

/// Abstract base class for all quiz questions
abstract class QuizQuestion {
  final String word;
  final QuestionType type;
  final String prompt;
  final VocabularyEntity vocabularyEntity;

  const QuizQuestion({
    required this.word,
    required this.type,
    required this.prompt,
    required this.vocabularyEntity,
  });

  /// Check if the user's answer is correct
  bool checkAnswer(String userAnswer);

  /// Get the correct answer
  String getCorrectAnswer();

  /// Get explanation for the answer
  String getExplanation();
}
/// Multiple choice question with 4 options
class MultipleChoiceQuestion extends QuizQuestion {
  final List<String> options;
  final int correctIndex;

  const MultipleChoiceQuestion({
    required super.word,
    required super.type,
    required super.prompt,
    required super.vocabularyEntity,
    required this.options,
    required this.correctIndex,
  });

  @override
  bool checkAnswer(String userAnswer) {
    // Check if the answer matches the correct option
    final trimmedAnswer = userAnswer.trim().toLowerCase();
    final correctAnswer = options[correctIndex].trim().toLowerCase();
    return trimmedAnswer == correctAnswer;
  }

  @override
  String getCorrectAnswer() {
    return options[correctIndex];
  }

  @override
  String getExplanation() {
    // Get the first definition as explanation
    if (vocabularyEntity.senses.isNotEmpty) {
      final definition = vocabularyEntity.senses.first;
      return '${definition.pos}: ${definition.zhDef}';
    }
    return '正確答案是: ${getCorrectAnswer()}';
  }
}

/// Fill in the blank question
class FillInBlankQuestion extends QuizQuestion {
  final String sentenceWithBlank;
  final String correctWord;
  final List<String> acceptableAnswers; // Include variations

  const FillInBlankQuestion({
    required super.word,
    required super.prompt,
    required super.vocabularyEntity,
    required this.sentenceWithBlank,
    required this.correctWord,
    required this.acceptableAnswers,
  }) : super(type: QuestionType.fillInBlank);

  @override
  bool checkAnswer(String userAnswer) {
    final trimmedAnswer = userAnswer.trim().toLowerCase();
    // Check against all acceptable answers
    return acceptableAnswers.any(
      (acceptable) => acceptable.toLowerCase() == trimmedAnswer,
    );
  }

  @override
  String getCorrectAnswer() {
    return correctWord;
  }

  @override
  String getExplanation() {
    // Show the complete sentence with the correct word
    final completeSentence = sentenceWithBlank.replaceAll('___', correctWord);
    return '完整句子: $completeSentence';
  }
}

/// Spelling question - user must type the word correctly
class SpellingQuestion extends QuizQuestion {
  final String audioUrl;
  final String definition;

  const SpellingQuestion({
    required super.word,
    required super.prompt,
    required super.vocabularyEntity,
    required this.audioUrl,
    required this.definition,
  }) : super(type: QuestionType.spelling);

  @override
  bool checkAnswer(String userAnswer) {
    // Exact match required for spelling
    return userAnswer.trim().toLowerCase() == word.toLowerCase();
  }

  @override
  String getCorrectAnswer() {
    return word;
  }

  @override
  String getExplanation() {
    return '正確拼寫: $word\n定義: $definition';
  }
}

/// Sentence completion question - complete a sentence using the word
class SentenceCompletionQuestion extends QuizQuestion {
  final String sentenceStart;
  final String sentenceEnd;
  final List<String> acceptableCompletions;

  const SentenceCompletionQuestion({
    required super.word,
    required super.prompt,
    required super.vocabularyEntity,
    required this.sentenceStart,
    required this.sentenceEnd,
    required this.acceptableCompletions,
  }) : super(type: QuestionType.sentenceCompletion);

  @override
  bool checkAnswer(String userAnswer) {
    final trimmedAnswer = userAnswer.trim().toLowerCase();
    // Check if the answer contains the target word or acceptable variations
    return acceptableCompletions.any(
      (acceptable) => trimmedAnswer.contains(acceptable.toLowerCase()),
    );
  }

  @override
  String getCorrectAnswer() {
    // Return the first acceptable completion as the primary answer
    return acceptableCompletions.isNotEmpty
        ? acceptableCompletions.first
        : word;
  }

  @override
  String getExplanation() {
    final exampleCompletion = '$sentenceStart ${getCorrectAnswer()} $sentenceEnd';
    return '範例句子: $exampleCompletion';
  }
}
