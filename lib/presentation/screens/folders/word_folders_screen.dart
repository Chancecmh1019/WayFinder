import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../../core/providers/word_folder_providers.dart';
import '../../../data/models/word_folder_model.dart';
import 'word_folder_detail_screen.dart';

class WordFoldersScreen extends ConsumerWidget {
  const WordFoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foldersAsync = ref.watch(allFoldersProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
        elevation: 0,
        title: const Text('我的資料夾'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context, ref, isDark),
          ),
        ],
      ),
      body: foldersAsync.when(
        data: (folders) {
          if (folders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 64,
                    color: isDark ? AppTheme.gray600 : AppTheme.gray400,
                  ),
                  const SizedBox(height: AppTheme.space16),
                  Text(
                    '還沒有資料夾',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    '點擊右上角 + 建立第一個資料夾',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.space16),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WordFolderDetailScreen(folderId: folder.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.space20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: isDark ? null : AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Icon(
                            Icons.folder,
                            color: isDark ? AppTheme.pureWhite : AppTheme.pureBlack,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                folder.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${folder.wordCount} 個單字',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: isDark ? AppTheme.gray600 : AppTheme.gray400,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: isDark ? AppTheme.gray600 : AppTheme.gray400,
              ),
              const SizedBox(height: AppTheme.space16),
              Text(
                '載入失敗',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                '$e',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref, bool isDark) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('建立資料夾'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '資料夾名稱',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final folder = WordFolderModel.create(
                  id: const Uuid().v4(),
                  name: controller.text.trim(),
                );
                await ref.read(wordFolderRepositoryProvider).createFolder(folder);
                ref.invalidate(allFoldersProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('建立'),
          ),
        ],
      ),
    );
  }
}
