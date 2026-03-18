# FSRS Algorithm Implementation

## Overview

This directory contains the implementation of the FSRS (Free Spaced Repetition Scheduler) algorithm, a modern spaced repetition system that improves upon the traditional SM-2 algorithm.

## What is FSRS?

FSRS is a spaced repetition algorithm developed by Jarrett Ye that uses machine learning to optimize review scheduling. It achieves better retention rates with fewer reviews compared to SM-2.

### Key Improvements over SM-2

1. **More Parameters**: Uses 19 weight parameters (vs SM-2's 3)
2. **Better Accuracy**: Optimized through machine learning on real user data
3. **Flexible Ratings**: 4 rating levels (Again, Hard, Good, Easy)
4. **Dynamic Difficulty**: Adjusts difficulty based on actual performance
5. **State Tracking**: Tracks card states (New, Learning, Review, Relearning)

## Algorithm Components

### 1. Card States

- **New**: Card has never been studied
- **Learning**: Card is being learned (short intervals, minutes)
- **Review**: Card is in review phase (long intervals, days/months/years)
- **Relearning**: Card was forgotten and is being relearned

### 2. Rating Levels

- **Again (1)**: Forgot the card completely
- **Hard (2)**: Remembered with significant difficulty
- **Good (3)**: Remembered correctly
- **Easy (4)**: Remembered very easily

### 3. Key Metrics

#### Stability (S)
- Represents how long the memory will last
- Measured in days
- Higher stability = longer intervals

#### Difficulty (D)
- Represents how hard the card is to remember
- Range: 1-10
- Higher difficulty = shorter intervals

#### Retrievability (R)
- Probability of successfully recalling the card
- Range: 0-1
- Calculated based on elapsed time and stability

## Algorithm Flow

### New Card

```
User sees card for first time
↓
User rates: Again/Hard/Good/Easy
↓
Card moves to Learning or Review state
↓
Next review scheduled based on rating
```

### Learning Card

```
Card in Learning state (short intervals)
↓
User rates: Again/Hard/Good/Easy
↓
- Again/Hard: Stay in Learning, reset progress
- Good/Easy: Move to Review state
↓
Next review scheduled
```

### Review Card

```
Card in Review state (long intervals)
↓
User rates: Again/Hard/Good/Easy
↓
- Again: Move to Relearning state
- Hard/Good/Easy: Stay in Review, adjust interval
↓
Next review scheduled
```

## Scheduling Formula

### Initial Stability (for new cards)

```
S₀ = w[rating]
```

Where `w` is the weight parameter array.

### Next Stability (for reviews)

For "Again" rating:
```
S' = w[11] × D^(-w[12]) × (S^w[13] - 1) × e^(w[14] × (1 - R))
```

For other ratings:
```
S' = S × (e^w[8] × (11 - D) × S^(-w[9]) × (e^((1-R) × w[10]) - 1) × HP × EB + 1)
```

Where:
- `S` = current stability
- `D` = difficulty
- `R` = retrievability
- `HP` = hard penalty (w[15] if Hard, else 1)
- `EB` = easy bonus (w[16] if Easy, else 1)

### Next Difficulty

```
D' = D - w[6] × (rating - 3)
D' = w[7] × w[4] + (1 - w[7]) × D'  // Mean reversion
D' = constrain(D', 1, 10)  // Keep in valid range
```

### Next Interval

```
I = S × request_retention
I = constrain(I, 1, maximum_interval)
```

## Parameters

### Default Parameters (w[0] to w[18])

```dart
[
  0.4072,  // w[0]: Initial stability for Again
  1.1829,  // w[1]: Initial stability for Hard
  3.1262,  // w[2]: Initial stability for Good
  15.4722, // w[3]: Initial stability for Easy
  7.2102,  // w[4]: Initial difficulty
  0.5316,  // w[5]: Difficulty decrease per rating
  1.0651,  // w[6]: Difficulty adjustment factor
  0.0234,  // w[7]: Mean reversion weight
  1.616,   // w[8]: Stability growth factor
  0.1544,  // w[9]: Stability decay factor
  1.0824,  // w[10]: Retrievability factor
  1.9813,  // w[11]: Again stability factor
  0.0953,  // w[12]: Again difficulty factor
  0.2975,  // w[13]: Again stability power
  2.2042,  // w[14]: Again retrievability factor
  0.2407,  // w[15]: Hard penalty
  2.9466,  // w[16]: Easy bonus
  0.5034,  // w[17]: (unused)
  0.6567,  // w[18]: (unused)
]
```

### Other Parameters

- **request_retention**: Target retention rate (default: 0.9 = 90%)
- **maximum_interval**: Maximum interval in days (default: 36500 = 100 years)
- **again_minutes**: Minutes to wait after "Again" (default: 1)
- **hard_minutes**: Minutes to wait after "Hard" (default: 5)
- **good_minutes**: Minutes to wait after "Good" (default: 10)

## Usage Example

```dart
// Create algorithm instance
final algorithm = FSRSAlgorithm();

// Create a new card
final card = FSRSCard.newCard();

// Get scheduling info for all ratings
final schedulingInfo = algorithm.schedule(card, Rating.good);

// Preview intervals
print('Again: ${schedulingInfo.again.scheduledDays} days');
print('Hard: ${schedulingInfo.hard.scheduledDays} days');
print('Good: ${schedulingInfo.good.scheduledDays} days');
print('Easy: ${schedulingInfo.easy.scheduledDays} days');

// Apply a rating
final nextCard = algorithm.next(card, Rating.good);

// Check next review
print('Next review: ${nextCard.due}');
print('State: ${nextCard.state}');
print('Stability: ${nextCard.stability}');
print('Difficulty: ${nextCard.difficulty}');
```

## Integration with WayFinder

### Multi-Sense Support

Each sense of a word has its own FSRS card:

```dart
// Word: "advanced"
// Sense 1: "先進的" -> FSRSCard 1
// Sense 2: "高級的" -> FSRSCard 2
```

### Progressive Unlocking

Senses unlock progressively:

1. Primary sense is always unlocked
2. Secondary senses unlock when primary reaches Review state
3. Tertiary senses unlock when all previous senses reach Review state

### Daily Limits

- New cards per day: 20 (configurable)
- Review cards per day: 100 (configurable)

### Priority Queue

Cards are prioritized for review:

1. Review cards (oldest first)
2. Learning/Relearning cards
3. New cards

## Performance Characteristics

### Time Complexity

- `schedule()`: O(1) - constant time
- `next()`: O(1) - constant time

### Space Complexity

- Per card: ~100 bytes
- 10,000 cards: ~1 MB

### Accuracy

- Retention rate: ~90% (with default parameters)
- Optimal review count: ~30% fewer reviews than SM-2

## References

1. [FSRS GitHub Repository](https://github.com/open-spaced-repetition/fsrs4anki)
2. [FSRS Algorithm Explanation](https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm)
3. [ts-fsrs Implementation](https://github.com/open-spaced-repetition/ts-fsrs)
4. [FSRS vs SM-2 Comparison](https://github.com/open-spaced-repetition/fsrs4anki/wiki/Comparison-between-FSRS-and-SM-2)

## License

This implementation is based on the open-source FSRS algorithm (MIT License).
