import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/entities.dart';
import '../../../core/providers/audio_providers.dart';
import '../../theme/app_theme.dart';

/// Word Card - 極簡單字卡片
/// 
/// 設計要點：
/// - 卡片使用 pureWhite/gray900 背景
/// - 圓角 radiusLarge (16px)
/// - 陰影 cardShadow
/// - 單字使用 displaySmall (32px, bold, -0.6 字距)
/// - 音標使用 bodyMedium (15px, gray700)
/// - 音訊按鈕圓形 radiusRound，48px 大小
class WordCard extends ConsumerWidget {
  final VocabularyEntity vocabularyEntity;

  const WordCard({
    super.key,
    required this.vocabularyEntity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final word = vocabularyEntity.lemma;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Word display
          Text(
            word,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.space12),
          
          // Phonetic notation
          if (vocabularyEntity.confusionNotes.map((n) => n.confusedWith).join(", ").isNotEmpty)
            Text(
              vocabularyEntity.confusionNotes.map((n) => n.confusedWith).join(", "),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.gray300 : AppTheme.gray700,
                  ),
              textAlign: TextAlign.center,
            ),
          
          const SizedBox(height: AppTheme.space20),
          
          // Audio button
          _buildAudioButton(context, ref, isDark),
        ],
      ),
    );
  }

  /// Build circular audio button
  Widget _buildAudioButton(BuildContext context, WidgetRef ref, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _playAudio(ref),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray800 : AppTheme.gray100,
            shape: BoxShape.circle,
            boxShadow: AppTheme.subtleShadow,
          ),
          child: Icon(
            Icons.volume_up,
            size: 24,
            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
          ),
        ),
      ),
    );
  }

  /// Play word pronunciation
  void _playAudio(WidgetRef ref) {
    final audioService = ref.read(audioServiceProvider);
    audioService.playPronunciation(word: vocabularyEntity.lemma);
  }
}
