
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : (isDark ? AppTheme.gray850 : AppTheme.gray50),
          border: Border.all(
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : (isDark ? AppTheme.gray800 : AppTheme.gray200)
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : (isDark ? AppTheme.gray400 : AppTheme.gray600),
          ),
        ),
      ),
    );
  }
}

class AdvancedFilterSheet extends StatefulWidget {
  final Set<int> selectedLevels; // Should be handled by provider, but nice to sync local UI
  final String? selectedType;
  final String? selectedPos;
  final bool officialOnly;
  final bool testedOnly;
  
  // Actions
  final Function(int level) onLevelToggle;
  final Function(String type) onTypeSelect;
  final Function(String pos) onPosSelect;
  final Function(bool) onOfficialToggle;
  final Function(bool) onTestedToggle;
  final VoidCallback onReset;

  const AdvancedFilterSheet({
    super.key,
    required this.selectedLevels,
    required this.selectedType,
    required this.selectedPos,
    required this.officialOnly,
    required this.testedOnly,
    required this.onLevelToggle,
    required this.onTypeSelect,
    required this.onPosSelect,
    required this.onOfficialToggle,
    required this.onTestedToggle,
    required this.onReset,
  });

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  // We can pass current state via props
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Handle bar
            Center(
                child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                        color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                        borderRadius: BorderRadius.circular(2)
                    ),
                )
            ),
            
            // Header
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Text("篩選條件", style: Theme.of(context).textTheme.titleMedium),
                    TextButton(
                        onPressed: widget.onReset,
                        child: Text("重設", style: TextStyle(color: Theme.of(context).primaryColor)),
                    )
                ],
            ),
            
            const SizedBox(height: 24),
            
            // Levels
            _buildSectionHeader(context, "詞彙等級", "大考中心官方難度分級：1-2 基礎、3-4 中級、5-6 進階"),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [1,2,3,4,5,6].map((l) {
                final isSelected = widget.selectedLevels.contains(l);
                return _buildLevelChip(context, l, isSelected, () => widget.onLevelToggle(l));
            }).toList()),
            
            const SizedBox(height: 24),
            
            // Type
            _buildSectionHeader(context, "詞彙類型", null),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
                {'v': 'all', 'l': '全部'},
                {'v': 'word', 'l': '單字'},
                {'v': 'phrase', 'l': '片語'},
                // {'v': 'pattern', 'l': '句型'},
            ].map((opt) {
                final isSelected = widget.selectedType == opt['v'] || (widget.selectedType == null && opt['v'] == 'all');
                return FilterChipWidget(
                    label: opt['l']!, 
                    isSelected: isSelected, 
                    onTap: () => widget.onTypeSelect(opt['v']!)
                );
            }).toList()),
            
            const SizedBox(height: 24),
            
            // POS
            _buildSectionHeader(context, "詞性", null),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
                {'v': 'all', 'l': '全部'},
                {'v': 'n.', 'l': '名詞'},
                {'v': 'v.', 'l': '動詞'},
                {'v': 'adj.', 'l': '形容詞'},
                {'v': 'adv.', 'l': '副詞'},
            ].map((opt) {
                 final isSelected = widget.selectedPos == opt['v'] || (widget.selectedPos == null && opt['v'] == 'all'); // Simplification assumes single select logic for UI
                 // NOTE: Provider uses Set<String>, but here we simplify to single select for the Sheet as per web
                 // We need to check if 'all' is selected or specific pos
                 
                 // If provider has empty set -> all
                 // If provider has 'n.' -> n.
                 
                 // Logic handled by parent passing 'selectedPos' as string
                 
                 return FilterChipWidget(
                    label: opt['l']!, 
                    isSelected: isSelected, 
                    onTap: () => widget.onPosSelect(opt['v']!)
                );
            }).toList()),

            const SizedBox(height: 24),
            
            // Advanced
            _buildSectionHeader(context, "進階篩選", null),
            const SizedBox(height: 12),
            _buildCheckboxOption(
                context, 
                "僅顯示大考中心詞彙表", 
                "官方公布的 7000 單字範圍", 
                widget.officialOnly,
                widget.onOfficialToggle
            ),
             const SizedBox(height: 16),
            _buildCheckboxOption(
                context, 
                "僅顯示曾出現在考題的詞彙", 
                "作為答案、選項或翻譯關鍵字", 
                widget.testedOnly,
                widget.onTestedToggle
            ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title, String? subtitle) {
      return Row(children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
              const SizedBox(width: 8),
              Tooltip(
                  message: subtitle,
                  child: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              )
          ]
      ]);
  }
  
  Widget _buildLevelChip(BuildContext context, int level, bool isSelected, VoidCallback onTap) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
              width: 44, height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                      : (isDark ? AppTheme.gray850 : AppTheme.gray50),
                  border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent
                  ),
                  borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                  level.toString(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Theme.of(context).primaryColor : (isDark ? AppTheme.gray400 : AppTheme.gray600)
                  )
              ),
          ),
      );
  }
  
  Widget _buildCheckboxOption(BuildContext context, String title, String subtitle, bool value, Function(bool) onChanged) {
       final isDark = Theme.of(context).brightness == Brightness.dark;
       return InkWell(
           onTap: () => onChanged(!value),
           child: Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                   SizedBox(
                       width: 24, height: 24,
                       child: Checkbox(
                           value: value, 
                           onChanged: (v) => onChanged(v ?? false),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                       )
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                       child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                               Text(title, style: TextStyle(
                                   color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                                   fontSize: 14
                               )),
                               const SizedBox(height: 2),
                               Text(subtitle, style: TextStyle(
                                   color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                   fontSize: 12
                               )),
                           ],
                       )
                   )
               ],
           ),
       );
  }
}
