import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 骨架屏加載組件
/// 
/// 用於替代 CircularProgressIndicator，提供更好的用戶體驗
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  
  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });
  
  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusSmall),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [
                      AppTheme.gray800,
                      AppTheme.gray700,
                      AppTheme.gray800,
                    ]
                  : [
                      AppTheme.gray200,
                      AppTheme.gray100,
                      AppTheme.gray200,
                    ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// 骨架屏卡片
class SkeletonCard extends StatelessWidget {
  final double? height;
  
  const SkeletonCard({
    super.key,
    this.height,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: height ?? 120,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: 100,
            height: 16,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          const SizedBox(height: AppTheme.space12),
          SkeletonLoader(
            width: double.infinity,
            height: 24,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          const Spacer(),
          SkeletonLoader(
            width: 60,
            height: 14,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
        ],
      ),
    );
  }
}

/// 骨架屏列表項
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      child: Row(
        children: [
          SkeletonLoader(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                const SizedBox(height: AppTheme.space8),
                SkeletonLoader(
                  width: 120,
                  height: 14,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 骨架屏文本
class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;
  
  const SkeletonText({
    super.key,
    this.width,
    this.height = 16,
  });
  
  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
    );
  }
}
