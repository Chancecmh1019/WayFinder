#!/usr/bin/env python3
import gzip
import json

# 讀取原始檔案
with gzip.open('assets/GSAT-English.json.gz', 'rt', encoding='utf-8') as f:
    data = json.load(f)

# 找到並刪除 zokeeper
original_count = len(data['words'])
data['words'] = [w for w in data['words'] if w.get('lemma') != 'zokeeper']
new_count = len(data['words'])

print(f"原始單字數量: {original_count}")
print(f"刪除後單字數量: {new_count}")
print(f"已刪除: {original_count - new_count} 個詞條")

# 寫回檔案
with gzip.open('assets/GSAT-English.json.gz', 'wt', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, separators=(',', ':'))

print("✓ 已成功更新 GSAT-English.json.gz")
