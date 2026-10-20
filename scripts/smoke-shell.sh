#!/bin/bash
# QwenPaw fpk 冒烟（壳架构版）：backend 22791 + fnshell 双听 2279 + panel + stub cmd（绝不碰 2277/2278 生产实例）
# WS 实测难以自动化，报告中注明人工验证
set -uo pipefail
T=/tmp/qptest
PY=/var/apps/python312/target/bin/python3
R=/vol1/1000/work/deepseek/fnos-apps/qwenpaw
DIST=$R/scripts/shell/panel/dist
PANEL_MARK='QwenPaw</title>'
APP_MARK='QwenPaw Console</title>'
PASS=0; FAIL=0
chk() { # chk 名称 期望字符串 文件 说明
  local name="$1" expect="$2" file="$3" note="$4"
  if grep -qF "$expect" "$file" 2>/dev/null; then
    echo "  PASS $name ($note)"; PASS=$((PASS+1))
  else
    echo "  FAIL $name ($note) — 未找到 [$expect]"; head -c 300 "$file" 2>/dev/null; echo; FAIL=$((FAIL+1))
  fi
}
chkcode() { # chkcode 名称 期望码 curl参数...
  local name="$1" want="$2"; shift 2
  local code; code=$(curl -s -o "$T/_c.out" -w '%{http_code}' --max-time 10 "$@")
  [ "$code" = "$want" ] && { echo "  PASS $name (HTTP $code)"; PASS=$((PASS+1)); } \
    || { echo "  FAIL $name (want $want got ${code:-000})"; cat "$T/_c.out" 2>/dev/null | head -c 200; echo; FAIL=$((FAIL+1)); }
}
mkdir -p "$T/cmd" "$T/state"

echo "[1] stub cmd/main（不得 exec 真实生产 main）..."
cat > "$T/cmd/main" <<'STUB'
#!/bin/bash
echo "{\"stub\":true,\"action\":\"$1\"}"
STUB
chmod +x "$T/cmd/main"

echo "[2] sed 测试数据绝对路径（先修后起，上次就是没修写进了生产 history.db）..."
sed -i 's|/vol1/@appdata/qwenpaw_yuexps/data|/tmp/qptest/data|g' "$T/data/.qwenpaw/config.json"
grep -c '/tmp/qptest/data' "$T/data/.qwenpaw/config.json"

echo "[3] 起 backend 22791（venv 已装齐依赖）..."
export HOME="$T/data"
"$T/venv/bin/python" -m qwenpaw app --host 127.0.0.1 --port 22791 >> "$T/app.log" 2>&1 &
APPPID=$!
echo "backend pid=$APPPID"

echo "[3b] 等 backend 就绪（最多 120s）..."
bok=""
for i in $(seq 1 24); do
  sleep 5
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://127.0.0.1:22791/" || echo 000)
  echo "  try$i: backend HTTP $code"
  [ "$code" = "200" ] && bok=1 && break
done
[ -z "$bok" ] && echo "  ⚠ backend 未就绪，后续 B 项可能失败"

echo "[4] 起 fnshell（TCP 2279 + UDS + panel + stub cmd）..."
$PY "$R/scripts/shell/fnshell.py" --tcp 2279 --backend 127.0.0.1:22791 --socket "$T/test.sock" \
  --prefix /app/qwenpaw --panel "$DIST" --cmd-dir "$T/cmd" --state "$T/state" >> "$T/shell.log" 2>&1 &
SHELLPID=$!
echo "shell pid=$SHELLPID"

echo "[5] 等待就绪（最多 120s）..."
ok=""
for i in $(seq 1 24); do
  sleep 5
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://127.0.0.1:2279/shell/api/status" || echo 000)
  echo "  try$i: status API HTTP $code"
  [ "$code" = "200" ] && ok=1 && break
done
if [ -z "$ok" ]; then
  echo "启动失败！shell.log:"; tail -20 "$T/shell.log"; echo "app.log:"; tail -10 "$T/app.log"
  kill $SHELLPID $APPPID 2>/dev/null; exit 1
fi

echo "─── [6] 路由验证集"
curl -s --max-time 8 "http://127.0.0.1:2279/" -o "$T/v_root.html"; chk "A 直连根=面板" "$PANEL_MARK" "$T/v_root.html" "GET /"
curl -s --max-time 8 "http://127.0.0.1:2279/qwenpaw/" -o "$T/v_app.html"; chk "B /qwenpaw/=本体HTML" "$APP_MARK" "$T/v_app.html" "iframe 命名空间剥段反代"
curl -s --max-time 8 --unix-socket "$T/test.sock" "http://localhost/app/qwenpaw/" -o "$T/v_gw.html"; chk "C UDS prefix=面板" "$PANEL_MARK" "$T/v_gw.html" "fnOS 网关路径"
chkcode "D panel 静态资源直出" 200 "http://127.0.0.1:2279/assets/index-BScZE7Ud.css"
chkcode "E status API JSON" 200 "http://127.0.0.1:2279/shell/api/status"; chk "E2 status 字段" '"backend"' "$T/_c.out" "status_json"
grep -o '"shell":{[^}]*' "$T/_c.out" | head -1; grep -o '"backend":{[^}]*' "$T/_c.out" | head -1; grep -o '"auth":{[^}]*' "$T/_c.out" | head -1

echo "─── [7] SSE 日志（tail200，8s 截断取首批）"
# 生产里 state 下日志由 cmd/main 重定向产生；冒烟无真 main，手动模拟
echo "smoke-marker-shell-line" >> "$T/state/gateway.log"
echo "smoke-marker-app-line" >> "$T/state/info.log"
timeout 8 curl -s -N "http://127.0.0.1:2279/shell/api/logs?src=shell" > "$T/v_sse.txt" || true
grep -q 'smoke-marker-shell-line' "$T/v_sse.txt" && { echo "  PASS F1 SSE src=shell tail 首批"; PASS=$((PASS+1)); } \
  || { echo "  FAIL F1 SSE src=shell"; head -c 200 "$T/v_sse.txt"; echo; FAIL=$((FAIL+1)); }
timeout 8 curl -s -N "http://127.0.0.1:2279/shell/api/logs?src=app" > "$T/v_sse2.txt" || true
grep -q 'smoke-marker-app-line' "$T/v_sse2.txt" && { echo "  PASS F2 SSE src=app tail 首批"; PASS=$((PASS+1)); } \
  || { echo "  FAIL F2 SSE src=app"; head -c 200 "$T/v_sse2.txt"; echo; FAIL=$((FAIL+1)); }

echo "─── [8] 服务控制（stub cmd/main）"
curl -s --max-time 30 -X POST -H 'Content-Type: application/json' -d '{"action":"status"}' \
  "http://127.0.0.1:2279/shell/api/service" -o "$T/v_svc.json"; chk "G service action→stub" '"stub\":true' "$T/v_svc.json" "exec_service→cmd main"
cat "$T/v_svc.json"; echo

echo "─── [9] 登录/配置闭环"
curl -s --max-time 8 -X POST -H 'Content-Type: application/json' -d '{"access_password":"test-pw-123"}' \
  "http://127.0.0.1:2279/shell/api/config" -o "$T/v_cfg.json"; chk "H1 设密码" '"access_password_set": true' "$T/v_cfg.json" "POST config"
perms=$(stat -c '%a' "$T/state/shell_config.json" 2>/dev/null || echo "缺失:$T/state")
[ "$perms" = "600" ] && { echo "  PASS H2 config 文件 0600"; PASS=$((PASS+1)); } || { echo "  FAIL H2 config 权限=$perms"; FAIL=$((FAIL+1)); }
code=$(curl -s -o "$T/_c.out" -w '%{http_code}' --max-time 8 -X POST -H 'Content-Type: application/json' -d '{"password":"wrong"}' "http://127.0.0.1:2279/shell/api/login")
[ "$code" = "401" ] && { echo "  PASS H3 错密码 401"; PASS=$((PASS+1)); } || { echo "  FAIL H3 错密码 got $code"; FAIL=$((FAIL+1)); }
code=$(curl -s -o "$T/_c.out" -w '%{http_code}' --max-time 8 -X POST -H 'Content-Type: application/json' -d '{"password":"test-pw-123"}' -D "$T/_hdr.txt" "http://127.0.0.1:2279/shell/api/login")
grep -qi 'set-cookie: *qwp_shell=' "$T/_hdr.txt" && [ "$code" = "200" ] \
  && { echo "  PASS H4 登录 200 + cookie qwp_shell"; PASS=$((PASS+1)); } \
  || { echo "  FAIL H4 登录 code=$code cookie=$(grep -ci set-cookie "$T/_hdr.txt")"; FAIL=$((FAIL+1)); }
curl -s --max-time 8 -X POST -H 'Content-Type: application/json' -d '{"access_password":""}' "http://127.0.0.1:2279/shell/api/config" -o "$T/v_cfg2.json"
chk "H5 清密码恢复" '"access_password_set": false' "$T/v_cfg2.json" "恢复无密码态"

echo "─── WS 隧道：自动化未测（难），发版后人工验证"

echo "[10] 收尾：杀测试进程（测试数据保持 sed 态，幂等）"
kill $SHELLPID $APPPID 2>/dev/null
sleep 2; kill -9 $SHELLPID $APPPID 2>/dev/null
rm -f "$T/test.sock"
echo "════ 冒烟结果: PASS=$PASS FAIL=$FAIL ════"
[ "$FAIL" = "0" ] && echo "SMOKE-SHELL OK" || echo "SMOKE-SHELL 有失败项"
