import 'package:flutter/material.dart';
import '../../../data/datasources/remote/wiktionary_api_client.dart';
import '../../theme/app_theme.dart';
import '../../theme/text_theme_extensions.dart';

/// Collapsible etymology section
class EtymologySection extends StatefulWidget {
  final Etymology? etymology;
  final bool isLoading;
  final VoidCallback? onExpand;

  const EtymologySection({
    super.key,
    this.etymology,
    this.isLoading = false,
    this.onExpand,
  });

  @override
  State<EtymologySection> createState() => _EtymologySectionState();
}

class _EtymologySectionState extends State<EtymologySection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
        widget.onExpand?.call();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Etymology',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.gray600,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildContent(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gray400),
            ),
          ),
        ),
      );
    }

    if (widget.etymology == null) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Text(
          'No etymology information available',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.gray600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        0,
        AppTheme.space16,
        AppTheme.space16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusMedium),
          bottomRight: Radius.circular(AppTheme.radiusMedium),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etymology text
          Text(
            widget.etymology!.text,
            style: AppTextStyles.bodyMedium,
          ),

          // Roots
          if (widget.etymology!.roots.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space16),
            Text(
              'Roots:',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space8,
              children: widget.etymology!.roots.map((root) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.gray200,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    root,
                    style: AppTextStyles.labelMedium,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
