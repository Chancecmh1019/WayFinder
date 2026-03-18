# WayFinder — lib/ 結構說明

## 目錄結構

```
lib/
├── main.dart                          入口點 (無 Firebase)
├── app.dart                           MaterialApp + 主題
├── core/
│   ├── providers/
│   │   └── app_providers.dart         全域 Riverpod providers
│   └── utils/
│       └── logger.dart                Debug 日誌工具
├── data/
│   ├── models/                        Hive 資料模型 (含 .g.dart 生成檔)
│   │   ├── vocab_models_enhanced.dart  詞彙核心模型 (WordEntry/Phrase/Pattern...)
│   │   ├── fsrs_card_model.dart        FSRS 記憶卡片
│   │   ├── fsrs_review_log_model.dart  複習歷史記錄
│   │   ├── fsrs_daily_stats_model.dart 每日統計
│   │   ├── learning_progress_model.dart 學習進度
│   │   └── review_history_model.dart   複習歷史
│   └── services/
│       ├── hive_service.dart           Hive 初始化 + box 管理
│       ├── local_vocab_service.dart    從 assets/GSAT-English.json.gz 載入
│       ├── fsrs_service.dart           FSRS 演算法整合 + 進度儲存
│       └── tts_service.dart            flutter_tts 封裝
├── domain/
│   ├── entities/
│   │   └── vocabulary_entity.dart      領域實體
│   └── services/
│       └── fsrs_algorithm.dart         FSRS v5 演算法實作
└── presentation/
    ├── theme/
    │   └── app_theme.dart              黑白灰設計系統
    ├── providers/
    │   ├── browse_provider.dart        單字瀏覽篩選/排序狀態
    │   └── study_provider.dart         翻卡/填空/選擇 session 狀態
    ├── screens/
    │   ├── splash_screen.dart          啟動畫面 + 初始化
    │   ├── main_shell.dart             底部 IndexedStack 導航 (5 頁)
    │   ├── home/home_screen.dart       首頁 (streak + 統計 + 快速開始)
    │   ├── browse/
    │   │   ├── browse_screen.dart      單字庫瀏覽 (搜尋/篩選/排序)
    │   │   └── word_detail_screen.dart 完整單字詳情 (所有欄位)
    │   ├── study/
    │   │   ├── study_hub_screen.dart   學習模式選擇
    │   │   ├── flashcard_screen.dart   FSRS 翻牌學習
    │   │   ├── cloze_screen.dart       考題填空練習
    │   │   ├── multiple_choice_screen.dart 四選一測驗
    │   │   └── session_complete_screen.dart 完成結算
    │   ├── grammar/grammar_screen.dart  12 個文法句型 + 詳情
    │   └── stats/stats_screen.dart     統計 (熱力圖/掌握度/進度)
    └── widgets/
        └── common/
            ├── wf_app_bar.dart         統一 AppBar
            ├── skeleton_loader.dart    骨架屏動畫
            └── audio_button.dart       TTS 播音按鈕
```

## 資料來源
`assets/GSAT-English.json.gz` — 壓縮 JSON，包含：
- `words[7172]` — 單字詞條
- `phrases[688]` — 片語詞條  
- `patterns[12]` — 文法句型

## pubspec.yaml 依賴 (需要)
```yaml
dependencies:
  flutter_riverpod: ^2.x
  hive: ^2.x
  hive_flutter: ^1.x
  archive: ^3.x          # GZip 解壓
  flutter_tts: ^4.x      # TTS 播音
  equatable: ^2.x

dev_dependencies:
  hive_generator: ^2.x
  build_runner: ^2.x
```
