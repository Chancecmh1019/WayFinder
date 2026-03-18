import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Flip Card Widget - 卡片翻轉動畫
/// 
/// 設計要點：
/// - 翻轉軸：Y 軸
/// - 過渡時間：300ms
/// - 緩動函數：ease-in-out
/// - 背面延遲顯示：150ms
/// - 配合 cardShadow 變化
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool isFlipped;
  final Duration duration;
  final Curve curve;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.isFlipped = false,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _animation.addListener(() {
      // Switch to back side at halfway point
      if (_animation.value >= pi / 2 && _showFront) {
        setState(() => _showFront = false);
      } else if (_animation.value < pi / 2 && !_showFront) {
        setState(() => _showFront = true);
      }
    });

    // Start animation if initially flipped
    if (widget.isFlipped) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculate rotation angle
        final angle = _animation.value;
        
        // Determine which side to show
        final isUnder = (angle > pi / 2);
        final child = isUnder ? widget.back : widget.front;
        
        // Calculate transform
        var transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateY(angle);

        // Flip back side
        if (isUnder) {
          transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(pi - angle);
        }

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: _buildCardWithShadow(child, angle),
        );
      },
    );
  }

  /// Build card with dynamic shadow based on flip angle
  Widget _buildCardWithShadow(Widget child, double angle) {
    // Calculate shadow intensity based on flip angle
    final shadowIntensity = (1 - (angle / pi).abs()).clamp(0.0, 1.0);
    
    // Interpolate between card shadow and elevated shadow
    final shadows = shadowIntensity > 0.5
        ? AppTheme.cardShadow
        : AppTheme.elevatedShadow;

    return Container(
      decoration: BoxDecoration(
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}

/// Flip Card Controller - 控制卡片翻轉
class FlipCardController extends ChangeNotifier {
  bool _isFlipped = false;

  bool get isFlipped => _isFlipped;

  void flip() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  void reset() {
    _isFlipped = false;
    notifyListeners();
  }

  void showBack() {
    if (!_isFlipped) {
      _isFlipped = true;
      notifyListeners();
    }
  }

  void showFront() {
    if (_isFlipped) {
      _isFlipped = false;
      notifyListeners();
    }
  }
}

/// Answer Reveal Animation - 答案揭示動畫
/// 
/// 淡入 + 輕微上移效果
class AnswerRevealAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const AnswerRevealAnimation({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 150),
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<AnswerRevealAnimation> createState() => _AnswerRevealAnimationState();
}

class _AnswerRevealAnimationState extends State<AnswerRevealAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05), // Slight upward movement
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
