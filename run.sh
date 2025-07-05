#!/usr/bin/env bash
# 在專案根目錄執行：會連續跑 20 回
#   1. 產生隨機測試向量：./python/data_generate.py
#   2. 進入 RTL 目錄並 source 01_run
# 若任一步失敗 (非 0 exit code) 就立即終止

set -e  # 發生錯誤立刻退出

for i in $(seq 1 20); do
  echo "========== Iteration $i / 20 =========="
  python3 ./python/data_generate.py
  pushd ./01_RTL > /dev/null
  source 01_run          # 等同於 ". 01_run"
  popd > /dev/null
done

echo "✅  全部 20 次執行完成！"
