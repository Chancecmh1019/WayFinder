
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vocabulary_entity.dart';
import '../providers/root_browser_provider.dart';
import '../theme/app_theme.dart';
import 'browse/word_detail_screen.dart';

class RootExplorerScreen extends ConsumerWidget {
  const RootExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rootBrowserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      appBar: AppBar(
        title: const Text("字根字典"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: state.rootGroups.isEmpty
          ? Center(child: Text("沒有字根資料", style: TextStyle(color: isDark ? Colors.grey : Colors.black54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.rootGroups.length,
              itemBuilder: (context, index) {
                final group = state.rootGroups[index];
                return _RootGroupCard(group: group);
              },
            ),
    );
  }
}

class _RootGroupCard extends StatelessWidget {
  final RootGroup group;

  const _RootGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      color: isDark ? AppTheme.gray900 : Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppTheme.gray800 : AppTheme.gray200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: Border.all(color: Colors.transparent),
        collapsedShape: Border.all(color: Colors.transparent),
        title: Row(
          children: [
            Text(
              group.root,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif', // Classical feel for roots
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                group.meaning,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Container(
           width: 24, height: 24,
           alignment: Alignment.center,
           decoration: BoxDecoration(
               color: isDark ? AppTheme.gray800 : AppTheme.gray100,
               shape: BoxShape.circle
           ),
           child: Text("${group.count}", style: const TextStyle(fontSize: 12)),
        ),
        children: group.words.map((word) => _WordTile(word: word)).toList(),
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  final VocabularyEntity word;

  const _WordTile({required this.word});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      title: Text(
        word.lemma,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        word.senses.isNotEmpty ? word.senses.first.zhDef : "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WordDetailScreen(lemma: word.lemma),
        ));
      },
    );
  }
}
