import '../../data/models/fsrs_card_model.dart';
import '../../data/models/vocab_models_enhanced.dart';
import '../services/fsrs_algorithm.dart';

/// Use case for managing sense unlocking
/// 
/// This implements the progressive unlocking system where:
/// 1. The primary sense is unlocked by default
/// 2. Secondary senses unlock when the primary sense reaches Review state
/// 3. Tertiary senses unlock when all previous senses reach Review state
class SenseUnlockUseCase {
  /// Determine which senses should be unlocked for a word
  /// 
  /// [entry]: The vocabulary entry
  /// [existingCards]: Existing FSRS cards for this word's senses
  /// 
  /// Returns: List of sense IDs that should be unlocked
  List<String> determineUnlockedSenses(
    VocabEntryModel entry,
    List<FSRSCardModel> existingCards,
  ) {
    if (entry.senses.isEmpty) return [];

    final unlockedSenses = <String>[];
    
    // Primary sense (first sense) is always unlocked
    unlockedSenses.add(entry.senses[0].senseId);

    // Check if we should unlock additional senses
    for (int i = 1; i < entry.senses.length; i++) {
      if (_shouldUnlockSense(i, entry.senses, existingCards)) {
        unlockedSenses.add(entry.senses[i].senseId);
      } else {
        // Stop at the first sense that shouldn't be unlocked
        break;
      }
    }

    return unlockedSenses;
  }

  /// Check if a sense at the given index should be unlocked
  bool _shouldUnlockSense(
    int senseIndex,
    List<VocabSenseModel> senses,
    List<FSRSCardModel> existingCards,
  ) {
    // Check if all previous senses have reached Review state
    for (int i = 0; i < senseIndex; i++) {
      final previousSenseId = senses[i].senseId;
      final card = existingCards.firstWhere(
        (c) => c.senseId == previousSenseId,
        orElse: () => FSRSCardModel.newCard(
          userId: '',
          lemma: '',
          senseId: previousSenseId,
          isUnlocked: false,
        ),
      );

      // If any previous sense is not in Review state, don't unlock
      if (card.state != CardState.review.index) {
        return false;
      }
    }

    return true;
  }

  /// Identify the primary sense (most important sense)
  /// 
  /// The primary sense is determined by:
  /// 1. First sense with exam examples
  /// 2. If no examples, the first sense
  String identifyPrimarySense(VocabEntryModel entry) {
    if (entry.senses.isEmpty) {
      throw ArgumentError('Entry has no senses');
    }

    // Find first sense with exam examples
    for (final sense in entry.senses) {
      if (sense.examples.isNotEmpty) {
        return sense.senseId;
      }
    }

    // Default to first sense
    return entry.senses[0].senseId;
  }

  /// Check if a new sense should be automatically unlocked
  /// 
  /// This is called after each review to check if progress has been made
  /// that warrants unlocking the next sense.
  bool shouldAutoUnlock(
    VocabEntryModel entry,
    List<FSRSCardModel> cards,
    String justReviewedSenseId,
  ) {
    final justReviewedCard = cards.firstWhere(
      (c) => c.senseId == justReviewedSenseId,
      orElse: () => FSRSCardModel.newCard(
        userId: '',
        lemma: '',
        senseId: justReviewedSenseId,
        isUnlocked: false,
      ),
    );

    // Only unlock if the just-reviewed card reached Review state
    if (justReviewedCard.state != CardState.review.index) {
      return false;
    }

    // Find the index of the just-reviewed sense
    final senseIndex = entry.senses.indexWhere(
      (s) => s.senseId == justReviewedSenseId,
    );

    if (senseIndex == -1 || senseIndex >= entry.senses.length - 1) {
      // Not found or it's the last sense
      return false;
    }

    // Check if the next sense is already unlocked
    final nextSenseId = entry.senses[senseIndex + 1].senseId;
    final nextCard = cards.firstWhere(
      (c) => c.senseId == nextSenseId,
      orElse: () => FSRSCardModel.newCard(
        userId: '',
        lemma: '',
        senseId: nextSenseId,
        isUnlocked: false,
      ),
    );

    // Unlock if not already unlocked
    return !nextCard.isUnlocked;
  }

  /// Get unlock progress for a word
  /// 
  /// Returns a map with:
  /// - totalSenses: Total number of senses
  /// - unlockedSenses: Number of unlocked senses
  /// - masteredSenses: Number of senses in Review state
  /// - progress: Unlock progress (0.0 to 1.0)
  Map<String, dynamic> getUnlockProgress(
    VocabEntryModel entry,
    List<FSRSCardModel> cards,
  ) {
    final totalSenses = entry.senses.length;
    final unlockedSenses = cards.where((c) => c.isUnlocked).length;
    final masteredSenses = cards.where((c) => c.isReview).length;

    return {
      'totalSenses': totalSenses,
      'unlockedSenses': unlockedSenses,
      'masteredSenses': masteredSenses,
      'progress': totalSenses > 0 ? unlockedSenses / totalSenses : 0.0,
      'masteryProgress': totalSenses > 0 ? masteredSenses / totalSenses : 0.0,
    };
  }

  /// Get the next sense to unlock
  /// 
  /// Returns null if all senses are unlocked or if conditions aren't met
  String? getNextSenseToUnlock(
    VocabEntryModel entry,
    List<FSRSCardModel> cards,
  ) {
    final unlockedSenseIds = determineUnlockedSenses(entry, cards);
    
    if (unlockedSenseIds.length >= entry.senses.length) {
      // All senses are unlocked
      return null;
    }

    // Return the next sense that should be unlocked
    return entry.senses[unlockedSenseIds.length].senseId;
  }

  /// Get unlock hint message for UI
  /// 
  /// Returns a user-friendly message explaining unlock conditions
  String getUnlockHint(
    VocabEntryModel entry,
    List<FSRSCardModel> cards,
  ) {
    final nextSenseId = getNextSenseToUnlock(entry, cards);
    
    if (nextSenseId == null) {
      return '所有義項已解鎖';
    }

    final senseIndex = entry.senses.indexWhere((s) => s.senseId == nextSenseId);
    
    if (senseIndex == 1) {
      return '熟練掌握主要義項後，將解鎖第二個義項';
    } else {
      return '熟練掌握前 $senseIndex 個義項後，將解鎖下一個義項';
    }
  }
}
