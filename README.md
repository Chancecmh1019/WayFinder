# WayFinder

基於學習科學原理的 Android 單字學習應用程式，專為台灣學測考生設計，採用 FSRS 間隔重複系統和交錯學習策略。

## 版本資訊

- 當前版本：v1.1.0 (Build 2)
- 資料庫版本：GSAT-English v6.1.0
- 詞彙量：7,177 單字 + 688 片語 + 21 文法句型

## 專案特色

### 學習系統
- **FSRS 演算法**：採用最新的 Free Spaced Repetition Scheduler，比傳統 SM-2 更精準
- **交錯學習**：混合不同難度和類型的單字，提升長期記憶效果
- **情境強化**：克漏字、聽力、配對、造句等多元練習模式
- **義項解鎖**：漸進式學習單字的多重意義，避免認知負荷過重

### 資料特色
- **學測專用**：完整收錄歷屆學測、指考、身障甄試考題
- **頻率分析**：基於歷屆考題的 AI 重要性評分
- **字根記憶**：7,177 個單字全部包含字根拆解和記憶策略
- **學習輔助**：75 個高頻單字包含搭配詞、用法說明、文法規則、常見錯誤

### 介面設計
- **極簡風格**：黑白灰配色，文青風格的襯線字體
- **離線優先**：所有核心功能完全離線可用
- **響應式設計**：適配各種 Android 裝置
- **無廣告**：專注學習體驗

## 技術架構

### 前端技術
- **框架**：Flutter 3.10.7
- **狀態管理**：Riverpod 2.5.1
- **本地資料庫**：Hive 2.2.3
- **架構模式**：Clean Architecture

### 核心演算法
- **FSRS**：Free Spaced Repetition Scheduler
- **交錯學習**：Interleaving Strategy
- **義項解鎖**：Sense Unlock System

### 資料處理
- **壓縮格式**：GZip 壓縮的 JSON
- **快取策略**：LRU Cache Manager
- **資料驗證**：完整的型別檢查和錯誤處理

## 快速開始

### 環境需求
- Flutter SDK ^3.10.7
- Dart SDK ^3.10.7
- Android Studio 或 VS Code
- Android SDK (API Level 21+)

### 安裝步驟

1. Clone 專案
```bash
git clone https://github.com/Chancecmh1019/WayFinder.git
cd WayFinder
```

2. 安裝依賴
```bash
flutter pub get
```

3. 生成程式碼
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. 執行應用
```bash
flutter run
```

## 專案結構

```
WayFinder/
├── lib/
│   ├── core/                   # 核心功能
│   │   ├── config/            # 應用配置
│   │   ├── constants/         # 常數定義
│   │   ├── providers/         # 全域 Provider
│   │   ├── services/          # 核心服務
│   │   └── utils/             # 工具函式
│   ├── data/                   # 資料層
│   │   ├── datasources/       # 資料源（本地/遠端）
│   │   ├── models/            # 資料模型（Hive）
│   │   ├── repositories/      # Repository 實作
│   │   ├── services/          # 資料服務
│   │   └── mappers/           # Entity/Model 轉換
│   ├── domain/                 # 領域層
│   │   ├── entities/          # 領域實體
│   │   ├── repositories/      # Repository 介面
│   │   ├── services/          # 領域服務
│   │   └── usecases/          # 使用案例
│   └── presentation/           # 展示層
│       ├── providers/         # UI Provider
│       ├── screens/           # 畫面
│       ├── widgets/           # 元件
│       └── theme/             # 主題設定
├── assets/                     # 資源檔案
│   ├── fonts/                 # 字體檔案
│   └── GSAT-English.json.gz   # 詞彙資料庫
├── test/                       # 測試檔案
├── scripts/                    # 工具腳本
└── android/                    # Android 配置
```

## 主要功能

### 1. 學習模式
- **閃卡模式**：看單字翻卡查看釋義
- **選擇題**：看英文選中文，或看中文選英文
- **拼字練習**：聽音拼字，強化記憶
- **克漏字**：在句子中填入正確單字
- **情境聽力**：聽例句選擇正確單字
- **情境配對**：配對單字與釋義
- **情境造句**：重組單字成完整句子

### 2. 單字瀏覽
- **進階篩選**：依難度、詞性、考試類型、頻率篩選
- **搜尋功能**：支援英文、中文、模糊搜尋
- **詳細資訊**：
  - 音標和發音
  - 多重義項
  - 歷屆考題例句
  - 字根分析
  - 同義詞/反義詞/衍生詞
  - 易混淆詞說明
  - 頻率統計
  - 學習輔助（搭配詞、用法說明、文法規則、常見錯誤）

### 3. 文法句型
- 21 個學測高頻文法句型
- 初學者摘要（快速理解）
- 完整教學說明
- 句型結構公式
- 歷屆考題例句
- AI 生成例句

### 4. 學習統計
- 學習進度追蹤
- 記憶保留率分析
- 學習時間統計
- 熱力圖視覺化
- 卡片分布圖表
- 精熟度分析

### 5. 單字資料夾
- 自訂分類
- 收藏管理
- 批次學習

## 資料庫說明

### GSAT-English v6.1.0

#### 單字資料結構
```dart
{
  "lemma": "單字",
  "pos": ["詞性"],
  "level": 1-6,  // 7000 單難度等級
  "in_official_list": true/false,
  "frequency": {
    "total_appearances": 總出現次數,
    "tested_count": 出題次數,
    "active_tested_count": 正確答案次數,
    "importance_score": AI 重要性分數,
    "by_exam_type": {
      "gsat": 學測次數,
      "ast": 指考次數,
      "sped": 身障甄試次數
    }
  },
  "senses": [義項列表],
  "root_info": {
    "root_breakdown": "字根拆解",
    "memory_strategy": "記憶策略"
  },
  "collocations": [搭配詞],  // v6.1.0 新增
  "usage_notes": "用法說明",  // v6.1.0 新增
  "grammar_notes": "文法規則",  // v6.1.0 新增
  "common_mistakes": "常見錯誤"  // v6.1.0 新增
}
```

#### 考試類型
- `gsat`: 學測
- `gsat_ref`: 學測參考試題
- `gsat_makeup`: 學測補考
- `ast`: 指定科目考試
- `ast_makeup`: 指考補考
- `sped`: 身障甄試（v6.0.0 新增）

## 開發指南

### 程式碼生成
```bash
# 生成 Hive TypeAdapter 和 Riverpod Provider
dart run build_runner build --delete-conflicting-outputs

# 監聽模式（開發時使用）
dart run build_runner watch
```

### 測試
```bash
# 執行所有測試
flutter test

# 執行特定測試
flutter test test/data_validation_test.dart

# 靜態分析
flutter analyze
```

### 建置
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (Google Play)
flutter build appbundle --release
```

## 更新日誌

### v1.1.0 (2026-03-18)
- 更新資料庫至 GSAT-English v6.1.0
- 新增 6 個單字（總計 7,177 個）
- 新增 9 個文法句型（總計 21 個）
- 新增 78 筆身障甄試例句
- 新增單字學習輔助欄位（搭配詞、用法說明、文法規則、常見錯誤）
- 新增文法句型初學者摘要
- 支援身障甄試考試類型
- 修正所有簡體中文為繁體中文
- 更新詞彙統計顯示

### v1.0.0 (2026-03-01)
- 初始版本發布
- 完整的 FSRS 學習系統
- 7,171 個單字 + 688 片語 + 12 文法句型
- 多種學習模式
- 離線功能支援

## 常見問題

### Q: 如何匯入/匯出學習進度？
A: 進入「設定」→「帳號管理」→「匯出/匯入資料」

### Q: 單字發音無法播放？
A: 請確認網路連線，首次播放需要下載音檔

### Q: 如何重置學習進度？
A: 進入「設定」→「進階設定」→「重置所有資料」

### Q: 支援哪些 Android 版本？
A: Android 5.0 (API Level 21) 以上

## 貢獻指南

本專案目前為私有專案，暫不接受外部貢獻。

## 授權

Copyright © 2026 WayFinder Team. All rights reserved.

本專案為私有專案，未經授權不得使用、複製、修改或散布。

## 聯絡資訊

- GitHub: https://github.com/Chancecmh1019/WayFinder
- Issues: https://github.com/Chancecmh1019/WayFinder/issues

## 致謝

- Flutter 團隊提供優秀的跨平台框架
- FSRS 演算法開發者
- 所有測試使用者的寶貴回饋

---

Made with ❤️ for Taiwan GSAT students
