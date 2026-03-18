import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../domain/services/fsrs_optimizer.dart';
import '../../../data/services/fsrs_service.dart';
import '../../../core/providers/app_providers.dart';

/// FSRS Ë®≠Â??´Èù¢
///
/// ?ÅË®±?®Êà∂Ôº?/// 1. Ë™øÊï¥?ÆÊ?‰øùÁ??á‰∏¶?¥Êé•‰øùÂ?
/// 2. ?•Á??∂Â??ÉÊï∏
/// 3. ?ãË??™Â??®Ô?Â¶ÇÊ??âË∂≥Â§†Á?Ë§áÁ?Ë®òÈ?Ôº?class FSRSSettingsScreen extends ConsumerStatefulWidget {
  const FSRSSettingsScreen({super.key});

  @override
  ConsumerState<FSRSSettingsScreen> createState() => _FSRSSettingsScreenState();
}

class _FSRSSettingsScreenState extends ConsumerState<FSRSSettingsScreen> {
  double _targetRetention = 0.9;
  bool _isOptimizing = false;
  bool _isSaving = false;
  String? _optimizationResult;
  int _reviewCount = 0;
  bool _isOptimized = false;
  bool _retentionChanged = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final fsrsService = ref.read(fsrsServiceProvider);
    final currentParams = fsrsService.getCurrentParameters();

    setState(() {
      _targetRetention = currentParams.requestRetention;
      _reviewCount = fsrsService.getReviewLogCount();
      _isOptimized = fsrsService.isUsingOptimizedParameters();
    });
  }

  Future<void> _saveRetention(FsrsService fsrsService) async {
    setState(() {
      _isSaving = true;
    });
    try {
      final currentParams = fsrsService.getCurrentParameters();
      final updatedParams = currentParams.copyWith(
        requestRetention: _targetRetention,
      );
      await fsrsService.updateParameters(updatedParams);
      setState(() {
        _retentionChanged = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('?ÆÊ?‰øùÁ??áÂ∑≤?≤Â?'),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.gray800
                : AppTheme.gray900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('?≤Â?Â§±Ê?Ôº?e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fsrsService = ref.watch(fsrsServiceProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('FSRS Ë®≠Â?'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.space24),
        children: [
          // Ë™™Ê??°Á?
          _buildInfoCard(isDark),

          const SizedBox(height: AppTheme.space24),

          // ?ÆÊ?‰øùÁ??áË®≠ÂÆ?          _buildRetentionCard(isDark, fsrsService),

          const SizedBox(height: AppTheme.space24),

          // ?∂Â??ÉÊï∏Ë≥áË?
          _buildParametersCard(isDark),

          const SizedBox(height: AppTheme.space24),

          // ?™Â???          _buildOptimizerCard(isDark, fsrsService),

          if (_optimizationResult != null) ...[
            const SizedBox(height: AppTheme.space24),
            _buildResultCard(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isDark ? AppTheme.gray300 : AppTheme.gray900,
                size: 20,
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                '?úÊñº FSRS',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            'FSRS (Free Spaced Repetition Scheduler) ?Ø‰??ãÁèæ‰ª???ÑÈ??îÈ?Ë§áÁ?Ê≥ïÔ?'
            '?∏Ê??≥Áµ±??SM-2 ÁÆóÊ?ÔºåËÉΩ?¥Á≤æÊ∫ñÂú∞?êÊ∏¨Ë®òÊÜ∂Ë°∞ÈÄÄ‰∏¶Ëá™ÂÆöÁæ©?ÆÊ?‰øùÁ??á„Ä?,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppTheme.gray300 : AppTheme.gray900,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionCard(bool isDark, FsrsService fsrsService) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '?ÆÊ?‰øùÁ???,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Ë®≠Â?‰Ω†Â??õÂú®Ë§áÁ??ÇË?‰ΩèÂñÆÂ≠óÁ?Ê©üÁ??ÇË?È´òÁ?‰øùÁ??áÊ?Â¢ûÂ?Ë§áÁ??ªÁ???,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppTheme.gray300 : AppTheme.gray900,
            ),
          ),
          const SizedBox(height: AppTheme.space20),

          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _targetRetention,
                  min: 0.7,
                  max: 0.98,
                  divisions: 28,
                  activeColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                  inactiveColor: isDark ? AppTheme.gray700 : AppTheme.gray300,
                  label: '${(_targetRetention * 100).toStringAsFixed(0)}%',
                  onChanged: (value) {
                    setState(() {
                      _targetRetention = value;
                      _retentionChanged = true;
                    });
                  },
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  '${(_targetRetention * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space12),

          // Âª∫Ë≠∞Ë™™Ê?
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray800 : AppTheme.gray50,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: isDark ? AppTheme.gray300 : AppTheme.gray900,
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    _getRetentionAdvice(_targetRetention),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.gray300 : AppTheme.gray900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ‰øùÂ??âÈ?ÔºàÂè™?â‰øÆ?πÈ??çÈ?‰∫ÆÈ°ØÁ§∫Ô?
          if (_retentionChanged) ...[
            const SizedBox(height: AppTheme.space16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _saveRetention(fsrsService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                  foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('?≤Â?‰øùÁ??áË®≠ÂÆ?,
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getRetentionAdvice(double retention) {
    if (retention >= 0.95) {
      return '?ûÂ∏∏È´òÁ?‰øùÁ??áÔ?Ë§áÁ??ªÁ??ÉÂ?È´òÔ??©Â??çË??ÉË©¶?çË??∫„Ä?;
    } else if (retention >= 0.90) {
      return '?®Ëñ¶Ë®≠Â?ÔºåÂπ≥Ë°°Ë??∂Ê??úÂ?Ë§áÁ?Ë≤†Ê???;
    } else if (retention >= 0.85) {
      return 'ËºÉ‰??Ñ‰??ôÁ?ÔºåË?ÁøíÊ¨°?∏Ë?Â∞ëÔ??©Â??∑Ê?Â≠∏Á???;
    } else {
      return 'Âæà‰??Ñ‰??ôÁ?ÔºåÂèØ?ΩÊ?Á∂ìÂ∏∏ÂøòË?Ôºå‰?Âª∫Ë≠∞Ë®≠Â??é‰???;
    }
  }

  Widget _buildParametersCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '?∂Â??ÉÊï∏',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (_isOptimized)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                    vertical: AppTheme.space4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: isDark ? AppTheme.gray600 : AppTheme.gray400,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: isDark ? AppTheme.gray300 : AppTheme.gray600,
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Text(
                        'Â∑≤ÂÑ™??,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppTheme.gray300 : AppTheme.gray600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),

          _buildParameterRow(
            isDark,
            'Ê¨äÈ??ÉÊï∏',
            '19 ?ãÂÑ™?ñÂ???,
            Icons.tune,
          ),

          const Divider(height: AppTheme.space24),

          _buildParameterRow(
            isDark,
            '?ÆÊ?‰øùÁ???,
            '${(_targetRetention * 100).toStringAsFixed(0)}%',
            Icons.track_changes,
          ),

          const Divider(height: AppTheme.space24),

          _buildParameterRow(
            isDark,
            '?ÄÂ§ßÈ???,
            '36500 Â§?,
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildParameterRow(
    bool isDark,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.space8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.gray800 : AppTheme.gray100,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDark ? AppTheme.gray300 : AppTheme.gray900,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppTheme.gray300 : AppTheme.gray900,
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizerCard(bool isDark, FsrsService fsrsService) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_fix_high,
                color: isDark ? AppTheme.gray300 : AppTheme.gray900,
                size: 20,
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                '?ÉÊï∏?™Â???,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            '?πÊ?‰Ω†Á?Ë§áÁ?Ê≠∑Âè≤Ë®òÈ?ÔºåËá™?ïÂÑ™??FSRS ?ÉÊï∏ÔºåÁ??êÊ??©Â?‰Ω†Á?Â≠∏Á??≤Á???,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppTheme.gray300 : AppTheme.gray900,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.space16),

          // Áµ±Ë?Ë≥áË?
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray800 : AppTheme.gray50,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  isDark,
                  'Ë§áÁ?Ë®òÈ?',
                  '$_reviewCount',
                  Icons.history,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                ),
                _buildStatItem(
                  isDark,
                  '?ÄË¶ÅË???,
                  '${FSRSOptimizer.minReviewsForOptimization}',
                  Icons.check_circle_outline,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.space16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isOptimizing ? null : () => _runOptimizer(fsrsService),
              icon: _isOptimizing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(_isOptimizing ? '?™Â?‰∏?..' : '?ãË??™Â???),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(bool isDark, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppTheme.gray300 : AppTheme.gray900,
        ),
        const SizedBox(height: AppTheme.space4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.space4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.gray300 : AppTheme.gray900,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: isDark ? null : AppTheme.cardShadow,
        border: Border.all(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: isDark ? AppTheme.gray300 : AppTheme.gray600,
                size: 20,
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                '?™Â?ÁµêÊ?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            _optimizationResult!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.gray300 : AppTheme.gray700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runOptimizer(FsrsService fsrsService) async {
    setState(() {
      _isOptimizing = true;
      _optimizationResult = null;
    });

    try {
      // ?≤Â?Ë§áÁ?Ë®òÈ?
      final reviewLogs = fsrsService.getAllReviewLogs();
      final currentParams = fsrsService.getCurrentParameters();

      // Ê™¢Êü•?ØÂê¶?âË∂≥Â§†Á??∏Ê?
      if (reviewLogs.length < FSRSOptimizer.minReviewsForOptimization) {
        setState(() {
          _optimizationResult = 'Ë§áÁ?Ë®òÈ?‰∏çË∂≥\n\n'
              '?ÆÂ???${reviewLogs.length} Á≠ÜË??ÑÔ??ÄË¶ÅËá≥Â∞?${FSRSOptimizer.minReviewsForOptimization} Á≠ÜË??ÑÊ??ΩÈÄ≤Ë??™Â??Ç\n\n'
              'Ë´ãÁπºÁ∫åÂ≠∏Áøí‰ª•Á¥ØÁ??¥Â??∏Ê???;
        });
        return;
      }

      // ?ãË??™Â???      final optimizer = FSRSOptimizer();
      final optimizedParams = optimizer.optimize(
        reviewLogs: reviewLogs,
        currentParams: currentParams.copyWith(
          requestRetention: _targetRetention,
        ),
      );

      // ?üÊ??±Â?
      final report = optimizer.generateReport(
        originalParams: currentParams,
        optimizedParams: optimizedParams,
        reviewLogs: reviewLogs,
      );

      // ‰øùÂ??™Â?ÂæåÁ??ÉÊï∏
      await fsrsService.updateParameters(optimizedParams);

      setState(() {
        _isOptimized = true;
        _retentionChanged = false;
        _optimizationResult = '?™Â?ÂÆåÊ?ÔºÅ\n\n'
            '?∫Êñº ${report.reviewCount} Á≠ÜË?ÁøíË??Ñ\n'
            '?üÂ??ÜÊï∏Ôº?{report.originalScore.toStringAsFixed(3)}\n'
            '?™Â??ÜÊï∏Ôº?{report.optimizedScore.toStringAsFixed(3)}\n'
            '?πÂ?Á®ãÂ∫¶Ôº?{report.improvementText}\n\n'
            '?ÆÊ?‰øùÁ??áÔ?${(report.originalRetention * 100).toStringAsFixed(0)}% ??${(report.optimizedRetention * 100).toStringAsFixed(0)}%\n\n'
            '?ÉÊï∏Â∑≤‰?Â≠òÔ?Â∞áÂú®‰∏ãÊ¨°Ë§áÁ??ÇÁ??à„Ä?;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('FSRS ?ÉÊï∏Â∑≤Ê??üÂÑ™?ñ‰∏¶‰øùÂ?'),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.gray800
                : AppTheme.gray900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _optimizationResult = '?™Â?Â§±Ê?Ôº?e';
      });
    } finally {
      setState(() {
        _isOptimizing = false;
      });
    }
  }
}
