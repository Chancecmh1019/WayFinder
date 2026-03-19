import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/unified_learning_provider.dart';
import '../../domain/entities/user_settings.dart';
import '../../core/providers/repository_providers.dart';
import '../../data/services/export_service.dart';

/// Settings screen for user preferences
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsState = ref.watch(settingsProvider);
    final settings = settingsState.settings;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ────────────────────────────────────────────
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 20, 0),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SETTINGS', style: TextStyle(fontSize: 11, letterSpacing: 3,
                      color: isDark ? AppTheme.gray600 : AppTheme.gray400,
                      fontWeight: AppTheme.weightSemiBold)),
                  const SizedBox(height: 6),
                  Text('設定', style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      letterSpacing: -0.5, fontFamily: AppTheme.fontFamilyChinese)),
                ])),
                IconButton(
                  icon: Icon(Icons.close, color: isDark ? AppTheme.gray400 : AppTheme.gray600, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
            )),

            // Content
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppTheme.space20),

                // Learning section
                _buildSectionHeader(context, '學習設定'),
                _buildSettingItem(
                  context: context,
                  title: '每日目標',
                  subtitle: '${settings.dailyGoal} 個新單字',
                  trailing: null,
                  onTap: () => _showDailyGoalPicker(context, ref, settings.dailyGoal),
                ),
                _buildDivider(isDark),

                // Audio section
                _buildSectionHeader(context, '音訊設定'),
                _buildSettingItem(
                  context: context,
                  title: 'TTS 引擎',
                  subtitle: settings.ttsEngine.displayName,
                  trailing: null,
                  onTap: () => _showTtsEnginePicker(context, ref, settings.ttsEngine),
                ),
                _buildDivider(isDark),
                _buildSettingItem(
                  context: context,
                  title: '發音偏好',
                  subtitle: settings.preferredPronunciation.displayName,
                  trailing: null,
                  onTap: () => _showPronunciationPicker(context, ref, settings.preferredPronunciation),
                ),
                _buildDivider(isDark),
                _buildSettingItem(
                  context: context,
                  title: '自動播放音訊',
                  subtitle: settings.autoPlayAudio ? '已開啟' : '已關閉',
                  trailing: CupertinoSwitch(
                    value: settings.autoPlayAudio,
                    activeTrackColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).updateAutoPlayAudio(value);
                    },
                  ),
                  onTap: null,
                ),
                _buildDivider(isDark),
                _buildSettingItem(
                  context: context,
                  title: '語音播放速度',
                  subtitle: '${(settings.speechRate * 100).toInt()}%',
                  trailing: null,
                  onTap: () => _showSpeechRatePicker(context, ref, settings.speechRate),
                ),
                _buildDivider(isDark),

                // Data Management section
                _buildSectionHeader(context, '資料管理'),
                _buildSettingItem(
                  context: context,
                  title: '本地儲存',
                  subtitle: '所有資料儲存在本地裝置',
                  trailing: Icon(Icons.lock_outline, size: 18,
                      color: isDark ? AppTheme.gray600 : AppTheme.gray400),
                  onTap: null,
                ),
                _buildDivider(isDark),
                _buildSettingItem(
                  context: context,
                  title: '匯出學習記錄',
                  subtitle: '匯出為 JSON 或 CSV',
                  trailing: null,
                  onTap: () => _showExportDialog(context, ref, isDark),
                ),
                _buildDivider(isDark),
                _buildSettingItem(
                  context: context,
                  title: '匯入學習記錄',
                  subtitle: '從 JSON 檔案恢復資料',
                  trailing: null,
                  onTap: () => _importData(context, ref),
                ),
                _buildDivider(isDark),

                // About section
                _buildSectionHeader(context, '關於'),
                _buildSettingItem(
                  context: context,
                  title: '版本',
                  subtitle: _version.isNotEmpty ? 'v$_version ($_buildNumber)' : '載入中...',
                  trailing: null,
                  onTap: null,
                ),
                _buildDivider(isDark),

                const SizedBox(height: AppTheme.space32),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space16,
        AppTheme.space20,
        AppTheme.space8,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget? trailing,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: enabled
                            ? (isDark ? AppTheme.pureWhite : AppTheme.pureBlack)
                            : (isDark ? AppTheme.gray600 : AppTheme.gray400),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null && enabled)
                Icon(
                  Icons.chevron_right,
                  color: isDark ? AppTheme.gray600 : AppTheme.gray400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: AppTheme.space20),
      color: isDark ? AppTheme.gray800 : AppTheme.gray200,
    );
  }

  void _showDailyGoalPicker(BuildContext context, WidgetRef ref, int currentGoal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selectedGoal = currentGoal;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '每日目標',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.space24),
              Text(
                '$selectedGoal 個新單字',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppTheme.space16),
              Slider(
                value: selectedGoal.toDouble(),
                min: 5,
                max: 100,
                divisions: 19,
                activeColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                inactiveColor: isDark ? AppTheme.gray700 : AppTheme.gray300,
                onChanged: (value) {
                  setState(() {
                    selectedGoal = value.toInt();
                  });
                },
              ),
              const SizedBox(height: AppTheme.space24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(settingsProvider.notifier).updateDailyGoal(selectedGoal);
                    Navigator.pop(context);
                  },
                  child: const Text('確認'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPronunciationPicker(BuildContext context, WidgetRef ref, PronunciationType current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          children: [
            Text(
              '發音偏好',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              '選擇預設的英語口音',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            ...PronunciationType.values.map((type) {
              final isSelected = type == current;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space8),
                child: Material(
                  color: isSelected
                      ? (isDark ? AppTheme.gray800 : AppTheme.gray100)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: InkWell(
                    onTap: () {
                      ref.read(settingsProvider.notifier).updatePronunciationType(type);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Row(
                        children: [
                          Text(
                            type.countryFlag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: Text(
                              type.displayName,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showTtsEnginePicker(BuildContext context, WidgetRef ref, TtsEngineType current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          children: [
            Text(
              'TTS 引擎',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              '選擇語音合成引擎',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            ...TtsEngineType.values.map((type) {
              final isSelected = type == current;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space8),
                child: Material(
                  color: isSelected
                      ? (isDark ? AppTheme.gray800 : AppTheme.gray100)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: InkWell(
                    onTap: () {
                      ref.read(settingsProvider.notifier).updateTtsEngine(type);
                      Navigator.pop(context);
                      
                      // Show info message for Edge TTS
                      if (type == TtsEngineType.edgeTts) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edge TTS 需要網路連線'),
                            backgroundColor: Colors.blue,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.displayName,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  type.description,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSpeechRatePicker(BuildContext context, WidgetRef ref, double currentRate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double selectedRate = currentRate;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '語音播放速度',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                '調整語音播放的速度（較慢的速度適合學習）',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space24),
              Row(
                children: [
                  Text(
                    '慢',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: selectedRate,
                      min: 0.3,
                      max: 1.0,
                      divisions: 14,
                      label: '${(selectedRate * 100).toInt()}%',
                      activeColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                      onChanged: (value) {
                        setState(() {
                          selectedRate = value;
                        });
                      },
                    ),
                  ),
                  Text(
                    '快',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                '目前速度：${(selectedRate * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.space24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(settingsProvider.notifier).updateSpeechRate(selectedRate);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                    foregroundColor: isDark ? AppTheme.pureBlack : AppTheme.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  child: const Text('確認'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show export dialog
  Future<void> _showExportDialog(BuildContext context, WidgetRef ref, bool isDark) async {
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
          children: [
            Text(
              '匯出格式',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.space24),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON'),
              subtitle: const Text('完整資料結構，適合備份'),
              onTap: () async {
                Navigator.pop(context);
                await _exportData(context, ref, ExportFormat.json);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
              subtitle: const Text('表格格式，適合分析'),
              onTap: () async {
                Navigator.pop(context);
                await _exportData(context, ref, ExportFormat.csv);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Export data
  Future<void> _exportData(BuildContext context, WidgetRef ref, ExportFormat format) async {
    try {
      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final exportService = ref.read(exportServiceProvider);
      await exportService.exportAndShare(format: format);

      // Close loading
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('匯出成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('匯出失敗：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Import data
  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      final importService = ref.read(importServiceProvider);
      
      if (importService == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('匯入服務未初始化'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Pick and import file
      final result = await importService.pickAndImportJson();

      // Close loading
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show result
      if (context.mounted) {
        final color = result.isSuccess
            ? Colors.green
            : result.hasErrors
                ? Colors.orange
                : Colors.blue;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: color,
            duration: const Duration(seconds: 4),
          ),
        );

        // If successful, refresh stats
        if (result.isSuccess) {
          ref.read(unifiedStatsRefreshProvider.notifier).state++;
        }
      }
    } catch (e) {
      // Close loading if still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('匯入失敗：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
