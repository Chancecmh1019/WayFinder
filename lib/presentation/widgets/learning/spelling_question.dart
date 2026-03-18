import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/entities.dart';
import '../../../core/providers/audio_providers.dart';
import '../../theme/app_theme.dart';

/// Spelling Question Widget - 拼字題 UI
/// 
/// 設計要點：
/// - 字母卡片輸入
/// - 音訊播放按鈕
/// - 顯示定義作為提示
/// - 極簡設計
class SpellingQuestionWidget extends ConsumerStatefulWidget {
  final SpellingQuestion question;
  final Function(String) onSubmit;

  const SpellingQuestionWidget({
    super.key,
    required this.question,
    required this.onSubmit,
  });

  @override
  ConsumerState<SpellingQuestionWidget> createState() =>
      _SpellingQuestionWidgetState();
}

class _SpellingQuestionWidgetState
    extends ConsumerState<SpellingQuestionWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-play audio when question loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playAudio();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Audio play button
        _buildAudioButton(context),
        
        const SizedBox(height: AppTheme.space24),
        
        // VocabSense hint
        _buildDefinitionHint(context),
        
        const SizedBox(height: AppTheme.space24),
        
        // Input field
        _buildInputField(context),
        
        const SizedBox(height: AppTheme.space24),
        
        // Submit button
        _buildSubmitButton(context),
      ],
    );
  }

  /// Build audio play button
  Widget _buildAudioButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _playAudio,
          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray850 : AppTheme.gray50,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Icon(
              Icons.volume_up,
              size: 32,
              color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
            ),
          ),
        ),
      ),
    );
  }

  /// Build definition hint
  Widget _buildDefinitionHint(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray850 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '定義',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            widget.question.definition,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Build input field
  Widget _buildInputField(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge,
      decoration: InputDecoration(
        hintText: '拼寫單字',
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.gray500
                  : AppTheme.gray400,
            ),
      ),
      onSubmitted: (_) => _handleSubmit(),
    );
  }

  /// Build submit button
  Widget _buildSubmitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _handleSubmit,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
      ),
      child: const Text('提交答案'),
    );
  }

  /// Play audio
  void _playAudio() {
    final audioService = ref.read(audioServiceProvider);
    audioService.playPronunciation(word: widget.question.word);
  }

  /// Handle submit
  void _handleSubmit() {
    final answer = _controller.text.trim();
    if (answer.isNotEmpty) {
      widget.onSubmit(answer);
    }
  }
}
