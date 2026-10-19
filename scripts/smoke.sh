#!/bin/bash
# QwenPaw fpk 冒烟：测试 venv + 复制 yuexps 数据 + 测试端口 2279（绝不碰 2277）
set -uo pipefail
T=/tmp/qptest
PY=/var/apps/python312/target/bin/python3
R=/vol1/1000/work/deepseek/fnos-apps/qwenpaw
mkdir -p "$T"
echo "[1] venv ..."
[ -x "$T/venv/bin/python" ] || $PY -m venv "$T/venv"
echo "[2] pip install wheel（全依赖树，几分钟）..."
"$T/venv/bin/pip" install --no-input "$R/fnpack/app/wheels"/*.whl "setuptools<82" -q 2>&1 | tail -3
echo "[3] 复制 yuexps 数据 ..."
[ -d "$T/data" ] || cp -a /vol1/@appdata/qwenpaw_yuexps/data "$T/data"
echo "[4] 起测试实例（2279）..."
export HOME="$T/data"
"$T/venv/bin/python" -m qwenpaw app --host 127.0.0.1 --port 2279 >> "$T/app.log" 2>&1 &
APPPID=$!
echo "app pid=$APPPID"
echo "[5] 起 fngateway（2279→test.sock）..."
$PY "$R/scripts/vendor/fngateway.py" --listen 127.0.0.1:2279 --socket "$T/test.sock" --prefix /app/qwenpaw >> "$T/gw.log" 2>&1 &
GWPID=$!
echo "gw pid=$GWPID"
echo "[6] 等待就绪（最多 120s）..."
ok=""
for i in $(seq 1 24); do
  sleep 5
  code=$(curl -s -o "$T/root.html" -w '%{http_code}' --max-time 5 "http://127.0.0.1:2279/" || echo 000)
  echo "  try$i: HTTP $code"
  [ "$code" = "200" ] && ok=1 && break
done
echo "─── 直连 2279 首页: $(head -c 200 $T/root.html | tr -d '\n' | head -c 150)"
echo "─── 经网关 UDS: $(curl -s -o "$T/gw.html" -w '%{http_code}' --max-time 8 --unix-socket "$T/test.sock" "http://localhost/app/qwenpaw/" || echo FAIL)"
head -c 200 "$T/gw.html" 2>/dev/null | tr -d '\n' | head -c 150; echo
echo "─── app.log 尾部:"; tail -5 "$T/app.log" 2>/dev/null
echo "─── gw.log 尾部:"; tail -5 "$T/gw.log" 2>/dev/null
echo "[7] 收尾：杀测试进程"
kill $GWPID $APPPID 2>/dev/null
sleep 2; kill -9 $GWPID $APPPID 2>/dev/null
echo "冒烟结束 ok=${ok:-FAIL}"
