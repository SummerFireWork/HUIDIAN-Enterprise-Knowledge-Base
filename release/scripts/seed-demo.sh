#!/usr/bin/env bash
# seed-demo.sh — 一键灌入演示数据（合成示例文档）
#
# 用法（在 release/ 目录下执行）：
#   bash scripts/seed-demo.sh                 # 默认 http://localhost:8081/api/v1
#   BASE=http://your-host:8081/api/v1 bash scripts/seed-demo.sh
#
# 前置条件：kb-app 已启动（docker compose up -d），Python3 可用（解析 JSON）。
# 幂等：已存在同名知识库时自动跳过，不会重复灌入。
set -euo pipefail

BASE="${BASE:-http://localhost:8081/api/v1}"
KB_NAME="演示知识库（Demo）"
DOCS_DIR="$(cd "$(dirname "$0")/../demo-docs" && pwd)"

echo "==> 等待 kb-app 健康检查通过 (${BASE}) ..."
for i in $(seq 1 40); do
  if curl -sf "${BASE}/actuator/health" | grep -q '"UP"'; then
    echo "    healthy ✓"; break
  fi
  [ "$i" -eq 40 ] && { echo "!! 等待超时，请检查 kb-app 是否启动成功（docker compose logs kb-app）"; exit 1; }
  sleep 3
done

get() { python3 -c "import sys,json;d=json.load(sys.stdin);print(d$1)"; }

echo "==> 检查是否已存在演示知识库 ..."
KB_ID=""
EXISTING=$(curl -sf "${BASE}/kbs" 2>/dev/null || echo "")
if [ -n "$EXISTING" ]; then
  KB_ID=$(echo "$EXISTING" | get "['data']['items']" 2>/dev/null | python3 -c "
import sys,json
for it in json.load(sys.stdin):
    if it.get('name')=='${KB_NAME}':
        print(it.get('kbId') or it.get('id')); break
")
fi
if [ -n "$KB_ID" ]; then
  echo "    已存在（kb_id=${KB_ID}），跳过建库"
else
  echo "==> 创建演示知识库 ..."
  RESP=$(curl -sf -X POST "${BASE}/kbs" \
    -H 'Content-Type: application/json' \
    -d "{\"name\":\"${KB_NAME}\",\"description\":\"合成演示文档，可自由使用与删除\",\"kb_type\":\"PERSONAL\"}")
  KB_ID=$(echo "$RESP" | get "['data']['id']")
  echo "    创建成功 kb_id=${KB_ID}"
fi

echo "==> 上传演示文档（text-extract 解析 → 切片 → 向量索引）..."
for f in "${DOCS_DIR}"/*.txt; do
  name="$(basename "$f")"
  size=$(wc -c < "$f" | tr -d ' ')
  md5=$(md5sum "$f" | cut -d' ' -f1)
  echo "  -- ${name} (${size} B)"
  INIT=$(curl -sf -X POST "${BASE}/upload/init" \
    -H 'Content-Type: application/json' \
    -d "{\"kb_id\":${KB_ID},\"filename\":\"${name}\",\"size\":${size},\"md5\":\"${md5}\"}")
  UID=$(echo "$INIT" | get "['data']['upload_id']")
  INSTANT=$(echo "$INIT" | get "['data']['instant']")
  if [ "$INSTANT" = "True" ] || [ "$INSTANT" = "true" ]; then
    echo "     秒传命中，跳过"
    continue
  fi
  curl -sf -X PUT "${BASE}/upload/${UID}/part/1" \
    -H 'Content-Type: application/octet-stream' \
    --data-binary "@${f}" > /dev/null
  COMPLETE=$(curl -sf -X POST "${BASE}/upload/${UID}/complete" \
    -H 'Content-Type: application/json' \
    -d '{"parts":[1]}')
  FID=$(echo "$COMPLETE" | get "['data']['file_id']")
  echo "     已提交 file_id=${FID}"
done

echo "==> 等待解析与索引完成（最多 120 秒）..."
ALL_OK=1
for i in $(seq 1 40); do
  ALL_OK=1
  for fid in $(curl -sf "${BASE}/files?kb_id=${KB_ID}" 2>/dev/null | get "['data']['items']" 2>/dev/null | python3 -c "
import sys,json
for it in json.load(sys.stdin):
    print(it.get('fileId') or it.get('id'))
" ); do
    ST=$(curl -sf "${BASE}/files/${fid}/status" | get "['data']['rawStatus']")
    echo "    file ${fid}: ${ST}"
    [ "$ST" != "INDEXED" ] && ALL_OK=0
  done
  [ "$ALL_OK" = "1" ] && { echo "    全部完成 ✓"; exit 0; }
  [ "$i" -eq 40 ] && { echo "!! 部分文件尚未索引完成，可稍后刷新页面或查看日志"; exit 0; }
  sleep 3
done
