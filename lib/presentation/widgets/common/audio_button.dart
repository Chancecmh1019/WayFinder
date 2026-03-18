import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

class AudioButton extends ConsumerWidget {
  final String text;
  final double size;

  const AudioButton({super.key, required this.text, this.size = 24});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () async {
        final tts = ref.read(ttsServiceProvider);
        await tts.speak(text);
      },
      child: Container(
        width: size + 16,
        height: size + 16,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.gray850 : AppTheme.gray50,
          borderRadius: BorderRadius.circular((size + 16) / 2),
        ),
        child: Icon(
          Icons.volume_up_rounded,
          size: size * 0.75,
          color: isDark ? AppTheme.gray300 : AppTheme.gray600,
        ),
      ),
    );
  }
}
