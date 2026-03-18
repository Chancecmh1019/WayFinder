import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../theme/app_theme.dart';
import '../../theme/text_theme_extensions.dart';

/// Collapsible dictionary section widget
class DictionarySection extends StatefulWidget {
  final String title;
  final String? htmlContent;
  final bool isLoading;
  final VoidCallback? onExpand;

  const DictionarySection({
    super.key,
    required this.title,
    this.htmlContent,
    this.isLoading = false,
    this.onExpand,
  });

  @override
  State<DictionarySection> createState() => _DictionarySectionState();
}

class _DictionarySectionState extends State<DictionarySection>
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
                      widget.title,
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
        padding: const EdgeInsets.all(AppTheme.space16),
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
            _buildSkeletonLine(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            _buildSkeletonLine(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            _buildSkeletonLine(width: 200, height: 16),
          ],
        ),
      );
    }

    if (widget.htmlContent == null || widget.htmlContent!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Text(
          'No content available',
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
      child: Html(
        data: widget.htmlContent!,
        style: {
          'body': Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(15),
            color: AppTheme.pureBlack,
          ),
          'p': Style(
            margin: Margins.only(bottom: 8),
          ),
          'a': Style(
            color: AppTheme.gray700,
            textDecoration: TextDecoration.underline,
          ),
          'strong': Style(
            fontWeight: FontWeight.w600,
          ),
          'em': Style(
            fontStyle: FontStyle.italic,
          ),
        },
      ),
    );
  }

  Widget _buildSkeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.gray200,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
