import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/tts_providers.dart';
import '../../core/providers/connectivity_providers.dart';

/// Audio button state enum
enum AudioButtonState {
  idle,
  loading,
  playing,
  error,
  offline,
}

/// Audio button with full state management
/// Handles loading, playing, error, and offline states
class AudioButton extends ConsumerStatefulWidget {
  final String text;
  final double size;
  final Color? color;
  final bool showOfflineIndicator;
  final VoidCallback? onError;

  const AudioButton({
    super.key,
    required this.text,
    this.size = 24.0,
    this.color,
    this.showOfflineIndicator = true,
    this.onError,
  });

  @override
  ConsumerState<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends ConsumerState<AudioButton> {
  AudioButtonState _state = AudioButtonState.idle;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final audioController = ref.watch(globalAudioControllerProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final isPlayingThis = audioController.isPlayingText(widget.text);

    // Update playing state based on global controller
    if (isPlayingThis && _state != AudioButtonState.playing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _state = AudioButtonState.playing;
          });
        }
      });
    } else if (!isPlayingThis && _state == AudioButtonState.playing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _state = AudioButtonState.idle;
          });
        }
      });
    }

    // Show offline indicator if offline and feature requires network
    // Note: TTS with flutter_tts works offline, but we show indicator for user awareness
    final showOffline = !isOnline && widget.showOfflineIndicator;

    return InkWell(
      onTap: _state == AudioButtonState.loading ? null : _handleTap,
      borderRadius: BorderRadius.circular(widget.size),
      child: Tooltip(
        message: _getTooltipMessage(showOffline),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getBackgroundColor(context, showOffline),
            shape: BoxShape.circle,
          ),
          child: _buildIcon(context, showOffline),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, bool showOffline) {
    switch (_state) {
      case AudioButtonState.loading:
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: widget.color ?? Theme.of(context).colorScheme.primary,
          ),
        );

      case AudioButtonState.error:
        return Icon(
          Icons.error_outline,
          size: widget.size,
          color: Theme.of(context).colorScheme.error,
        );

      case AudioButtonState.playing:
        return Icon(
          Icons.volume_up,
          size: widget.size,
          color: widget.color ?? Theme.of(context).colorScheme.primary,
        );

      case AudioButtonState.offline:
      case AudioButtonState.idle:
        if (showOffline) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.volume_up_outlined,
                size: widget.size,
                color: widget.color ?? Theme.of(context).colorScheme.primary,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_off,
                    size: widget.size * 0.4,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ],
          );
        }
        return Icon(
          Icons.volume_up_outlined,
          size: widget.size,
          color: widget.color ?? Theme.of(context).colorScheme.primary,
        );
    }
  }

  Color _getBackgroundColor(BuildContext context, bool showOffline) {
    switch (_state) {
      case AudioButtonState.error:
        return Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3);
      case AudioButtonState.offline:
        return Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2);
      case AudioButtonState.loading:
      case AudioButtonState.playing:
      case AudioButtonState.idle:
        return Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    }
  }

  String _getTooltipMessage(bool showOffline) {
    switch (_state) {
      case AudioButtonState.loading:
        return '載入中...';
      case AudioButtonState.playing:
        return '播放中（點擊停止）';
      case AudioButtonState.error:
        return _errorMessage ?? '播放失敗（點擊重試）';
      case AudioButtonState.offline:
        return '離線模式（使用本地語音）';
      case AudioButtonState.idle:
        if (showOffline) {
          return '離線模式（點擊播放）';
        }
        return '點擊播放';
    }
  }

  Future<void> _handleTap() async {
    final audioController = ref.read(globalAudioControllerProvider);
    final isPlayingThis = audioController.isPlayingText(widget.text);

    // If currently playing this text, stop it
    if (isPlayingThis) {
      await audioController.stopAll();
      if (mounted) {
        setState(() {
          _state = AudioButtonState.idle;
        });
      }
      return;
    }

    // Start loading
    if (mounted) {
      setState(() {
        _state = AudioButtonState.loading;
        _errorMessage = null;
      });
    }

    try {
      final ttsService = ref.read(flutterTtsServiceProvider);
      final success = await audioController.playTts(ttsService, widget.text);

      if (mounted) {
        if (success) {
          setState(() {
            _state = AudioButtonState.playing;
          });
        } else {
          setState(() {
            _state = AudioButtonState.error;
            _errorMessage = 'TTS 引擎無法播放';
          });
          widget.onError?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = AudioButtonState.error;
          _errorMessage = '播放失敗: ${e.toString()}';
        });
        widget.onError?.call();
      }
    }
  }
}

/// Enhanced Audio Button with global audio control
/// Automatically stops other playing audio when clicked
/// Simple version without state management
class EnhancedAudioButton extends ConsumerWidget {
  final String text;
  final double size;
  final Color? color;

  const EnhancedAudioButton({
    super.key,
    required this.text,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.watch(globalAudioControllerProvider);
    final isPlayingThis = audioController.isPlayingText(text);

    return InkWell(
      onTap: () async {
        final ttsService = ref.read(flutterTtsServiceProvider);
        if (isPlayingThis) {
          // Stop if currently playing this text
          await audioController.stopAll();
        } else {
          // Play this text (will stop any other playing audio)
          await audioController.playTts(ttsService, text);
        }
      },
      borderRadius: BorderRadius.circular(size),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlayingThis ? Icons.volume_up : Icons.volume_up_outlined,
          size: size,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Audio Button with loading state (legacy version)
/// Use AudioButton instead for full state management
@Deprecated('Use AudioButton instead for full state management')
class AudioButtonWithState extends ConsumerStatefulWidget {
  final String text;
  final double size;
  final Color? color;

  const AudioButtonWithState({
    super.key,
    required this.text,
    this.size = 24.0,
    this.color,
  });

  @override
  // ignore: deprecated_member_use_from_same_package
  ConsumerState<AudioButtonWithState> createState() => _AudioButtonWithStateState();
}

// ignore: deprecated_member_use_from_same_package
class _AudioButtonWithStateState extends ConsumerState<AudioButtonWithState> {
  bool _isLoading = false;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final audioController = ref.watch(globalAudioControllerProvider);
    final isPlayingThis = audioController.isPlayingText(widget.text);

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: widget.color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_hasError) {
      return InkWell(
        onTap: () {
          setState(() {
            _hasError = false;
          });
          _playAudio();
        },
        borderRadius: BorderRadius.circular(widget.size),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline,
            size: widget.size,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }

    return InkWell(
      onTap: _playAudio,
      borderRadius: BorderRadius.circular(widget.size),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlayingThis ? Icons.volume_up : Icons.volume_up_outlined,
          size: widget.size,
          color: widget.color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Future<void> _playAudio() async {
    final audioController = ref.read(globalAudioControllerProvider);
    final isPlayingThis = audioController.isPlayingText(widget.text);

    if (isPlayingThis) {
      await audioController.stopAll();
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final ttsService = ref.read(flutterTtsServiceProvider);
      final success = await audioController.playTts(ttsService, widget.text);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = !success;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }
}
