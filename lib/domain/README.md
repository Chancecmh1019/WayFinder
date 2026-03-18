# Domain Layer

This directory contains the core business logic of the WayFinder application, following Clean Architecture principles.

## Structure

### Entities (`entities/`)
Core business objects that represent the fundamental concepts of the application:

- **VocabularyEntity**: Represents a word with definitions, examples, phonetics, and CEFR level
- **LearningProgressEntity**: Tracks SM-2 algorithm parameters and learning progress for each word
- **ReviewHistory**: Records individual review sessions
- **User**: Represents an authenticated user
- **UserSettings**: User preferences and configuration
- **SessionStatistics**: Statistics for learning sessions

### Repositories (`repositories/`)
Interfaces that define contracts for data operations (implemented in the data layer):

- **AuthRepository**: Authentication operations (Google Sign-In, sign out)
- **VocabularyRepository**: Vocabulary data access (search, filter, retrieve)
- **ReviewSchedulerRepository**: Review scheduling and progress tracking
- **SyncRepository**: Cloud synchronization operations

### Services (`services/`)
Domain services that implement business logic:

- **SM2Algorithm**: Implementation of the SuperMemo 2 spaced repetition algorithm
  - Calculates optimal review intervals based on recall quality
  - Manages ease factors and repetition counts
  - Handles edge cases (quality < 3, EF < 1.3)

### Use Cases (`usecases/`)
Application-specific business rules that orchestrate the flow of data:

- **SignInWithGoogleUseCase**: Handles Google authentication flow
- **StartLearningSessionUseCase**: Initializes a learning session with due reviews and new words
- **GetNextItemUseCase**: Retrieves the next item to study (prioritizes reviews over new words)
- **SubmitAnswerUseCase**: Records answers and updates learning progress

## Key Principles

1. **Independence**: The domain layer has no dependencies on external frameworks or libraries
2. **Testability**: All business logic can be tested without UI or database
3. **Reusability**: Domain entities and logic can be reused across different platforms
4. **Clarity**: Clear separation between entities, repositories, services, and use cases

## SM-2 Algorithm

The SM-2 (SuperMemo 2) algorithm is the core of the spaced repetition system:

### Formula
- **Ease Factor**: EF' = EF + (0.1 - (5-q) × (0.08 + (5-q) × 0.02))
- **Interval**: 
  - First repetition: 1 day
  - Second repetition: 6 days
  - Subsequent: I(n) = I(n-1) × EF

### Quality Scale (0-5)
- 5: Perfect response
- 4: Correct after hesitation
- 3: Correct with difficulty
- 2: Incorrect but easy to recall
- 1: Incorrect but remembered
- 0: Complete blackout

### Edge Cases
- If EF < 1.3, set EF = 1.3
- If quality < 3, reset to interval 1 without changing EF

## Usage Example

```dart
// Initialize SM-2 algorithm
final sm2 = SM2Algorithm();

// Calculate next review
final result = sm2.calculate(
  currentInterval: 6,
  repetitions: 2,
  easeFactor: 2.5,
  quality: 4,
);

print('Next review in ${result.newInterval} days');
print('New ease factor: ${result.newEaseFactor}');

// Use case example
final signInUseCase = SignInWithGoogleUseCase(authRepository);
final result = await signInUseCase.call();

result.fold(
  (failure) => print('Error: $failure'),
  (user) => print('Signed in: ${user.email}'),
);
```

## Testing

All domain layer components should be thoroughly tested:

- **Unit tests**: Test individual methods and edge cases
- **Property-based tests**: Test universal properties (e.g., SM-2 algorithm correctness)
- **Integration tests**: Test use case flows

See the tasks.md file for specific testing requirements.
