import 'package:flutter/material.dart';
import '../../domain/entities/vocabulary_entity.dart';
import '../../data/models/vocab_models_enhanced.dart';
import '../screens/browse/word_detail_screen.dart';
import 'word/frequency_stats_widget.dart';
import 'word/root_analysis_widget.dart';
import 'word/confusion_pair_widget.dart';
import 'word/synonyms_antonyms_widget.dart';
import 'audio_button.dart';

// --- Sense Tabs ---
class SenseTabs extends StatefulWidget {
  final VocabularyEntity entry;
  final List<VocabSense> senses;
  final String lemma;

  const SenseTabs({
    super.key,
    required this.entry,
    required this.senses,
    required this.lemma,
  });

  @override
  State<SenseTabs> createState() => _SenseTabsState();
}

class _SenseTabsState extends State<SenseTabs> {
  int _selectedIndex = 0;
  bool _showExamExamples = true;

  @override
  Widget build(BuildContext context) {
    if (widget.senses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs
        if (widget.senses.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(widget.senses.length, (index) {
                final sense = widget.senses[index];
                final isSelected = index == _selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 12.0),
                  child: ChoiceChip(
                    showCheckmark: false,
                    label: Row(
                      children: [
                        Text(
                          _formatPos(sense.pos),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _truncate(sense.zhDef),
                          style: TextStyle(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (sense.examples.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.green, // SRS Good color approximation
                              shape: BoxShape.circle,
                            ),
                          )
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedIndex = index;
                          _showExamExamples = true;
                        });
                      }
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected 
                            ? Colors.transparent 
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

        // Content
        _buildSenseContent(widget.senses[_selectedIndex]),
      ],
    );
  }

  String _formatPos(String pos) {
    // Simplistic mapping, can be expanded
    if (pos.startsWith('n')) return 'n.';
    if (pos.startsWith('v')) return 'v.';
    if (pos.startsWith('adj')) return 'adj.';
    if (pos.startsWith('adv')) return 'adv.';
    return pos;
  }

  String _truncate(String text) {
    if (text.length > 10) return '${text.substring(0, 10)}...';
    return text;
  }

  Widget _buildSenseContent(VocabSense sense) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Definitions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                     decoration: BoxDecoration(
                       color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: Text(
                       sense.pos,
                       style: TextStyle(
                         fontSize: 12,
                         color: Theme.of(context).colorScheme.onSecondaryContainer,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ),
                    const Spacer(),
                 ],
               ),
               const SizedBox(height: 8),
               Text(
                 sense.zhDef,
                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
                   fontWeight: FontWeight.bold,
                 ),
               ),
               if (sense.enDef != null && sense.enDef!.isNotEmpty)
                 Padding(
                   padding: const EdgeInsets.only(top: 4.0),
                   child: Text(
                     sense.enDef!,
                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                       color: Theme.of(context).colorScheme.onSurfaceVariant,
                     ),
                   ),
                 ),
            ],
          ),
        ),


        // Generated Example (Learning Example)
        if (sense.generatedExample != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildHighlightedText(context, sense.generatedExample!, widget.entry.lemma),
                  ),
                  const SizedBox(width: 8),
                  AudioButton(text: sense.generatedExample!, size: 20),
                ],
              ),
            ),
          ),

        // Exam Examples
        if (sense.examples.isNotEmpty) ...[
          const SizedBox(height: 24),
          InkWell(
            onTap: () {
              setState(() {
                _showExamExamples = !_showExamExamples;
              });
            },
            child: Row(
              children: [
                Text(
                  "歷屆考題 (${sense.examples.length})",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Icon(
                  _showExamExamples ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 18,
                ),
              ],
            ),
          ),
          if (_showExamExamples)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: sense.examples.map((ex) => _buildExamExample(ex)).toList(),
              ),
            ),
        ]
      ],
    );
  }

  Widget _buildExamExample(ExamExample example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHighlightedText(context, example.text, widget.entry.lemma),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '考題例句',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              AudioButton(text: example.text, size: 18),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHighlightedText(BuildContext context, String text, String highlight) {
    if (highlight.isEmpty) return Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5));

    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();
    
    if (!lowerText.contains(lowerHighlight)) {
       return Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5));
    }

    final List<TextSpan> spans = [];
    int start = 0;
    int indexOfHighlight = lowerText.indexOf(lowerHighlight, start);

    while (indexOfHighlight != -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
      }
      
      final end = indexOfHighlight + lowerHighlight.length;
      spans.add(TextSpan(
        text: text.substring(indexOfHighlight, end),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.amber, // Highlight color
        ),
      ));
      
      start = end;
      indexOfHighlight = lowerText.indexOf(lowerHighlight, start);
    }
    
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, color: Theme.of(context).colorScheme.onSurface),
        children: spans,
      ),
    );
  }
}

// --- Deep Dive Section ---
class DeepDiveSection extends StatefulWidget {
  final VocabularyEntity entity;

  const DeepDiveSection({super.key, required this.entity});

  @override
  State<DeepDiveSection> createState() => _DeepDiveSectionState();
}

class _DeepDiveSectionState extends State<DeepDiveSection> {
  String? _activeSection; // 'stats', 'root', 'confusion', 'related'

  @override
  Widget build(BuildContext context) {
    final hasRoot = widget.entity.rootInfo != null;
    final hasConfusion = widget.entity.confusionNotes.isNotEmpty;
    // final hasStats = widget.entity.frequencyData != null; // Always show stats if data exists? Assumed yes.

    if (!hasRoot && !hasConfusion) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "深入學習",
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.entity.frequency != null)
              _buildDeepDiveButton("統計", Icons.bar_chart, "stats"),
            if (hasRoot)
              _buildDeepDiveButton("字源", Icons.account_tree, "root"),
            if (hasConfusion)
              _buildDeepDiveButton("易混淆", Icons.compare_arrows, "confusion"),
          ],
        ),

        // Section Content
        if (_activeSection != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: _buildSectionContent(),
            ),
          ),
      ],
    );
  }

  Widget _buildDeepDiveButton(String label, IconData icon, String sectionKey) {
    final isActive = _activeSection == sectionKey;
    return InkWell(
      onTap: () {
        setState(() {
          _activeSection = isActive ? null : sectionKey;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive 
                  ? Theme.of(context).colorScheme.onPrimary 
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_activeSection) {
      case 'root':
        final root = widget.entity.rootInfo!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("字根：${root.rootBreakdown}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("意義：${root.memoryStrategy}"),
            const SizedBox(height: 8),
            Text("記憶策略：${root.memoryStrategy}"),
            if (widget.entity.derivedForms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text("衍生詞：${widget.entity.derivedForms.join(', ')}"),
            ],
          ],
        );
      case 'confusion':
        return Column(
          children: widget.entity.confusionNotes.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("vs ${widget.entity.confusionNotes.map((n) => n.confusedWith).toList()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("說明：${item.distinction}"),
              ],
            ),
          )).toList(),
        );
      case 'stats':
        final f = widget.entity.frequency!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("頻率等級：${f.importanceScore.toInt()}"),
            Text("Zipf 分數：${f.importanceScore.toStringAsFixed(2)}"),
            Text("每百萬詞出現：${f.totalAppearances.toStringAsFixed(2)}"),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}


// ============================================================================
// Enhanced Components for VocabEntryModel
// ============================================================================

/// Enhanced Sense Tabs for VocabSenseModel
class EnhancedSenseTabs extends StatefulWidget {
  final List<VocabSense> senses;
  final String lemma;

  const EnhancedSenseTabs({
    super.key,
    required this.senses,
    required this.lemma,
  });

  @override
  State<EnhancedSenseTabs> createState() => _EnhancedSenseTabsState();
}

class _EnhancedSenseTabsState extends State<EnhancedSenseTabs> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _showExamExamples = true;

  @override
  Widget build(BuildContext context) {
    if (widget.senses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs
        if (widget.senses.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(widget.senses.length, (index) {
                final sense = widget.senses[index];
                final isSelected = index == _selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 12.0),
                  child: ChoiceChip(
                    showCheckmark: false,
                    label: Row(
                      children: [
                        Text(
                          _formatPos(sense.pos),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _truncate(sense.zhDef),
                          style: TextStyle(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (sense.examples.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          )
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedIndex = index;
                          _showExamExamples = true;
                        });
                      }
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected 
                            ? Colors.transparent 
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

        // Content with animation
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildSenseContent(widget.senses[_selectedIndex]),
        ),
      ],
    );
  }

  String _formatPos(String pos) {
    final posMap = {
      'NOUN': 'n.',
      'VERB': 'v.',
      'ADJ': 'adj.',
      'ADV': 'adv.',
      'PREP': 'prep.',
      'CONJ': 'conj.',
      'PRON': 'pron.',
      'DET': 'det.',
      'INTERJ': 'interj.',
    };
    return posMap[pos.toUpperCase()] ?? pos.toLowerCase();
  }

  String _truncate(String text) {
    if (text.length > 10) return '${text.substring(0, 10)}...';
    return text;
  }

  Widget _buildSenseContent(VocabSense sense) {
    return Column(
      key: ValueKey(sense.senseId),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Definitions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatPos(sense.pos),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sense.zhDef,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (sense.enDef != null && sense.enDef!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    sense.enDef!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Generated Example (Learning Example)
        if (sense.generatedExample != null && sense.generatedExample!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildHighlightedText(context, sense.generatedExample!, widget.lemma),
                  ),
                  const SizedBox(width: 8),
                  AudioButton(text: sense.generatedExample!, size: 20),
                ],
              ),
            ),
          ),

        // Exam Examples
        if (sense.examples.isNotEmpty) ...[
          const SizedBox(height: 24),
          InkWell(
            onTap: () {
              setState(() {
                _showExamExamples = !_showExamExamples;
              });
            },
            child: Row(
              children: [
                Text(
                  "歷屆考題 (${sense.examples.length})",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Icon(
                  _showExamExamples ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 18,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showExamExamples
                ? Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: sense.examples.map((ex) => _buildExamExample(ex)).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ]
      ],
    );
  }

  Widget _buildExamExample(ExamExample example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHighlightedText(context, example.text, widget.lemma),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _buildSourceTag(context, '${example.source.year}'),
                    _buildSourceTag(context, _formatExamType(example.source.examType)),
                    _buildSourceTag(context, _formatSectionType(example.source.sectionType)),
                  ],
                ),
              ),
              AudioButton(text: example.text, size: 18),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSourceTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _formatExamType(String type) {
    final map = {
      'gsat': '學測',
      'gsat_makeup': '學測補',
      'ast': '指考',
      'ast_makeup': '指考補',
      'gsat_trial': '試辦',
      'gsat_ref': '參考',
    };
    return map[type] ?? type;
  }

  String _formatSectionType(String type) {
    final map = {
      'vocabulary': '詞彙',
      'cloze': '綜測',
      'discourse': '文選',
      'structure': '結構',
      'reading': '閱讀',
      'translation': '翻譯',
      'mixed': '混合',
    };
    return map[type] ?? type;
  }

  Widget _buildHighlightedText(BuildContext context, String text, String highlight) {
    if (highlight.isEmpty) return Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5));

    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();
    
    if (!lowerText.contains(lowerHighlight)) {
      return Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5));
    }

    final List<TextSpan> spans = [];
    int start = 0;
    int indexOfHighlight = lowerText.indexOf(lowerHighlight, start);

    while (indexOfHighlight != -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
      }
      
      final end = indexOfHighlight + lowerHighlight.length;
      spans.add(TextSpan(
        text: text.substring(indexOfHighlight, end),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.amber,
        ),
      ));
      
      start = end;
      indexOfHighlight = lowerText.indexOf(lowerHighlight, start);
    }
    
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, color: Theme.of(context).colorScheme.onSurface),
        children: spans,
      ),
    );
  }
}

/// Enhanced Deep Dive Section for WordEntryModel
class EnhancedDeepDiveSection extends StatefulWidget {
  final VocabularyEntity entity;
  final WordEntryModel entry;

  const EnhancedDeepDiveSection({super.key, required this.entity, required this.entry});

  @override
  State<EnhancedDeepDiveSection> createState() => _EnhancedDeepDiveSectionState();
}

class _EnhancedDeepDiveSectionState extends State<EnhancedDeepDiveSection> {
  String? _activeSection;

  @override
  void initState() {
    super.initState();
    // Auto-select first available section
    if (widget.entity.frequency != null && widget.entity.senses.isNotEmpty) {
      _activeSection = 'stats';
    } else if (widget.entity.rootInfo != null) {
      _activeSection = 'root';
    } else if (widget.entity.confusionNotes.isNotEmpty) {
      _activeSection = 'confusion';
    } else if (widget.entity.synonyms.isNotEmpty || widget.entity.antonyms.isNotEmpty) {
      _activeSection = 'related';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStats = widget.entity.frequency != null && widget.entity.senses.isNotEmpty;
    final hasRoot = widget.entity.rootInfo != null;
    final hasConfusion = widget.entity.confusionNotes.isNotEmpty;
    final hasRelated = widget.entity.synonyms.isNotEmpty || widget.entity.antonyms.isNotEmpty;

    if (!hasStats && !hasRoot && !hasConfusion && !hasRelated) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "深入學習",
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (hasStats)
              _buildDeepDiveButton("統計", Icons.bar_chart, "stats"),
            if (hasRoot)
              _buildDeepDiveButton("字根", Icons.account_tree, "root"),
            if (hasConfusion)
              _buildDeepDiveButton("易混淆", Icons.compare_arrows, "confusion"),
            if (hasRelated)
              _buildDeepDiveButton("相關詞", Icons.link, "related"),
          ],
        ),

        // Section Content with animation
        if (_activeSection != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(_activeSection),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: _buildSectionContent(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeepDiveButton(String label, IconData icon, String sectionKey) {
    final isActive = _activeSection == sectionKey;
    return InkWell(
      onTap: () {
        setState(() {
          _activeSection = isActive ? null : sectionKey;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive 
                  ? Theme.of(context).colorScheme.onPrimary 
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_activeSection) {
      case 'stats':
        return FrequencyStatsWidget(
          frequency: widget.entity.frequency!,
          senses: widget.entity.senses,
        );
      case 'root':
        return RootAnalysisWidget(
          rootInfo: widget.entity.rootInfo!,
          derivedForms: widget.entity.derivedForms,
        );
      case 'confusion':
        return ConfusionPairWidget(
          currentLemma: widget.entity.lemma,
          confusionNotes: widget.entity.confusionNotes,
          onWordTap: (lemma) {
            // 導航到單字詳情頁面
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WordDetailScreen(lemma: lemma),
              ),
            );
          },
        );
      case 'related':
        return SynonymsAntonymsWidget(
          synonyms: widget.entity.synonyms,
          antonyms: widget.entity.antonyms,
          onWordTap: (lemma) {
            // 導航到單字詳情頁面
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WordDetailScreen(lemma: lemma),
              ),
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
