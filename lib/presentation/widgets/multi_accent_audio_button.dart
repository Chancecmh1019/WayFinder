import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../core/providers/tts_providers.dart';
import '../../data/services/edge_tts_service.dart';
import '../../data/services/flutter_tts_service.dart';
import '../../domain/entities/user_settings.dart';
import '../providers/settings_provider.dart';

/// 多國口音音訊按鈕
/// 
/// 支援多種英語口音（美國、英國、澳洲、菲律賓、南非）
/// 長按顯示口音選擇選單
class MultiAccentAudioButton extends ConsumerStatefulWidget {
  final String text;
  final double size;
  final bool showAccentSelector;

  const MultiAccentAudioButton({
    super.key,
    required this.text,
    this.size = 24,
    this.showAccentSelector = true,
  });

  @override
  ConsumerState<MultiAccentAudioButton> createState() => _MultiAccentAudioButtonState();
}

class _MultiAccentAudioButtonState extends ConsumerState<MultiAccentAudioButton> {
  bool _isPlaying = false;
  PronunciationType? _selectedAccent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferredAccent = ref.watch(settingsProvider.select((s) => s.settings.preferredPronunciation));
    final currentAccent = _selectedAccent ?? preferredAccent;

    return GestureDetector(
      onTap: () => _playAudio(currentAccent),
      onLongPress: widget.showAccentSelector ? () => _showAccentMenu(context, isDark) : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isPlaying
              ? (isDark ? AppTheme.gray700 : AppTheme.gray200)
              : (isDark ? AppTheme.gray800 : AppTheme.gray100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
              size: widget.size,
              color: isDark ? AppTheme.gray300 : AppTheme.gray700,
            ),
            if (widget.showAccentSelector) ...[
              const SizedBox(width: 4),
              Text(
                currentAccent.countryFlag,
                style: TextStyle(fontSize: widget.size * 0.6),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _playAudio(PronunciationType accent) async {
    if (_isPlaying) return;

    setState(() => _isPlaying = true);

    try {
      final ttsEngine = ref.read(ttsEngineTypeProvider);
      final ttsService = ref.read(activeTtsServiceProvider);

      bool success = false;

      if (ttsEngine == TtsEngineType.edgeTts && ttsService is EdgeTtsService) {
        success = await ttsService.speak(widget.text, pronunciationType: accent);
      } else if (ttsService is FlutterTtsService) {
        // Flutter TTS doesn't support multiple accents as well, but we can try
        final language = accent == PronunciationType.us ? 'en-US' : 'en-GB';
        await ttsService.setLanguage(language);
        success = await ttsService.speak(widget.text);
      }

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('播放失敗')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放錯誤: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  void _showAccentMenu(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '選擇口音',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.space16),
            ...PronunciationType.values.map((accent) {
              final isSelected = (_selectedAccent ?? ref.read(settingsProvider).settings.preferredPronunciation) == accent;
              return ListTile(
                leading: Text(
                  accent.countryFlag,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(accent.displayName),
                trailing: isSelected ? const Icon(Icons.check_circle) : null,
                onTap: () {
                  setState(() => _selectedAccent = accent);
                  Navigator.pop(context);
                  _playAudio(accent);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
