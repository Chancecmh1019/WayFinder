# 修正常見搭配顯示問題

## 問題說明
應用程式中的「常見搭配」欄位顯示為空白，這是因為資料解析時使用了錯誤的欄位名稱。

## 已修正內容
更新了 `CollocationModel.fromJson()` 方法，正確對應 JSON 資料中的欄位：
- `collocation` → `english`
- `zh` → `chinese`

## 如何查看修正結果

由於應用程式已經將舊的（錯誤的）資料快取到本地資料庫，您需要清除快取才能看到正確的資料。

### 方法 1：清除應用程式資料（推薦）
1. 在 Android 裝置上：設定 → 應用程式 → WayFinder → 儲存空間 → 清除資料
2. 重新啟動應用程式
3. 應用程式會自動重新匯入資料

### 方法 2：解除安裝後重新安裝
1. 解除安裝 WayFinder 應用程式
2. 重新執行 `flutter run` 或安裝新版本
3. 完成初始設定

## 驗證修正
修正後，查看任何一個包含學習輔助資料的單字（例如：delicate, injure, desperate, brilliant, crisis），應該可以看到：

常見搭配區塊顯示 5 組搭配詞，例如 "delicate" 會顯示：
- a delicate situation (微妙的處境)
- delicate health (脆弱的健康)
- delicate balance (微妙的平衡)
- delicate flavor (細膩的風味)
- a delicate matter (敏感的事情)

## 技術細節
- 修改檔案：`lib/data/models/vocab_models_enhanced.dart`
- 新增檢查腳本：`scripts/check_new_fields.dart`, `scripts/inspect_collocations.dart`
- 資料庫版本：GSAT-English v6.1.0
- 包含新欄位的單字數量：75 個高頻單字
