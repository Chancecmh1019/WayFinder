# Learning Session State Management

This directory contains the state management implementation for learning sessions using Riverpod.

## Files

### learning_session_state.dart
Defines the `LearningSessionState` class that holds all state for a learning session:
- Queue of learning items (reviews + new words)
- Current item and question
- Progress tracking (completed count, total count)
- Session statistics
- Loading and error states
- Session metadata (ID, start/end times, active status)

### learning_session_notifier.dart
Implements `LearningSessionNotifier`, a Riverpod StateNotifier that manages learning session state:

**Key Methods:**
- `startSession({int? dailyGoal})` - Start a new learning session
- `getNextItem()` - Get the next item (prioritizes due reviews)
- `submitAnswer({required String userAnswer, required int quality})` - Submit answer and update progress
- `endSession()` - End the current session
- `pauseSession()` / `resumeSession()` - Pause and resume functionality
- `resetSession()` - Reset to initial state

**Features:**
- Automatic time tracking per item
- Statistics calculation (accuracy, time spent, question type distribution)
- Error handling with user-friendly messages
- Automatic progression to next item after answer submission

### learning_session_provider.dart
Defines all Riverpod providers for dependency injection:

**Main Providers:**
- `learningSessionProvider` - Main StateNotifier provider
- `quizEngineProvider` - Quiz engine service
- `sm2AlgorithmProvider` - SM-2 algorithm service
- Use case providers (start session, get next item, submit answer)

**Selector Providers:**
- `isSessionActiveProvider` - Check if session is active
- `currentLearningItemProvider` - Get current item
- `currentQuestionProvider` - Get current question
- `sessionProgressProvider` - Get progress percentage
- `sessionStatisticsProvider` - Get session statistics
- `isDailyGoalMetProvider` - Check if daily goal is met
- `remainingItemsCountProvider` - Get remaining items count

## Usage Example

```dart
// In your widget
class LearningScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(learningSessionProvider);
    final notifier = ref.read(learningSessionProvider.notifier);
    
    // Start a session
    if (!sessionState.isActive) {
      return ElevatedButton(
        onPressed: () => notifier.startSession(dailyGoal: 20),
        child: Text('Start Learning'),
      );
    }
    
    // Show current question
    if (sessionState.currentQuestion != null) {
      return QuestionWidget(
        question: sessionState.currentQuestion!,
        onSubmit: (answer) {
          notifier.submitAnswer(
            userAnswer: answer,
            quality: 4, // or calculate based on correctness
          );
        },
      );
    }
    
    // Show completion
    if (sessionState.isComplete) {
      return SessionCompleteWidget(
        statistics: sessionState.statistics,
      );
    }
    
    return CircularProgressIndicator();
  }
}
```

## Requirements Validated

This implementation validates the following requirements from the spec:

- **Requirement 6.1**: Display count of due reviews and available new words
- **Requirement 6.2**: Present due reviews before new words
- **Requirement 6.3**: Present new words up to daily goal after reviews
- **Requirement 6.5**: Allow users to continue learning beyond daily goal
- **Requirement 6.6**: Save progress and resume from same point when interrupted

## Architecture

The implementation follows Clean Architecture principles:
- **Presentation Layer**: StateNotifier and State classes
- **Domain Layer**: Use cases for business logic
- **Dependency Injection**: All dependencies injected via Riverpod providers

## Testing

Basic test structure is provided in `test/presentation/providers/learning_session_notifier_test.dart`.
Full unit tests should be implemented to cover:
- Session start/end lifecycle
- Item progression logic
- Answer submission and statistics updates
- Error handling
- Pause/resume functionality
