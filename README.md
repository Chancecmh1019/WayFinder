# WayFinder

基於學習科學原理的 Android 單字學習應用程式，採用間隔重複系統（SRS）和交錯學習策略。

## 專案特色

- 🎯 **智能學習系統**：基於 SM-2 演算法的間隔重複系統
- 📚 **離線優先**：完整的離線功能支援
- 🎨 **極簡設計**：高冷文青風格的黑白灰 iOS 風格介面
- 🔄 **雲端同步**：Firebase 整合，多裝置同步
- 🎵 **語音支援**：單字發音功能
- 📊 **學習統計**：詳細的學習進度追蹤

## 技術架構

### Flutter App (主應用)
- **狀態管理**：Riverpod
- **本地資料庫**：Hive
- **雲端服務**：Firebase (Auth, Firestore, Storage)
- **架構模式**：Clean Architecture (Domain/Data/Presentation)

### Backend (資料處理)
- **語言**：Python
- **用途**：詞彙資料處理、字典生成、機器學習模型訓練

### Frontend (Web 版本)
- **框架**：Svelte + Vite
- **用途**：Web 版本的學習平台

## 快速開始

### 環境需求
- Flutter SDK ^3.10.7
- Dart SDK ^3.10.7
- Android Studio / VS Code
- Firebase 專案設定

### 安裝步驟

1. **Clone 專案**
```bash
git clone <repository-url>
cd wayfinder
```

2. **安裝依賴**
```bash
flutter pub get
```

3. **設定 Firebase**
- 將 `google-services.json` 放到 `android/app/` 目錄
- 確認 Firebase 專案已啟用 Authentication 和 Firestore

4. **設定本地配置**
複製 `keystore.properties.example` 為 `keystore.properties` 並填入相關資訊

5. **執行應用**
```bash
flutter run
```

## 專案結構

```
wayfinder/
├── lib/                    # Flutter 主程式
│   ├── core/              # 核心功能（配置、服務、工具）
│   ├── data/              # 資料層（資料源、模型、Repository 實作）
│   ├── domain/            # 領域層（實體、Repository 介面、Use Cases）
│   └── presentation/      # 展示層（畫面、Widget、Provider）
├── backend/               # Python 後端（資料處理）
├── frontend/              # Svelte Web 前端
├── assets/                # 資源檔案（字典、圖片）
├── android/               # Android 平台配置
└── web/                   # Web 平台配置
```

## 開發指南

### 設計系統
請參考 [DESIGN_GUIDE.md](DESIGN_GUIDE.md) 了解完整的設計規範。

### 程式碼生成
```bash
# 生成 Riverpod 和 Hive 程式碼
flutter pub run build_runner build --delete-conflicting-outputs
```

### 圖標生成
```bash
# 生成應用圖標
dart run flutter_launcher_icons
```

## 建置發布版本

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

## 授權

本專案為私有專案，未經授權不得使用。

## 聯絡資訊

如有問題或建議，請聯繫開發團隊。
