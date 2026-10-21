#!/bin/bash
# qwenpaw-panel 构建：面板 dist（scripts/shell/panel）→ 组装 fnpack-panel/app → fnpack 出 .fpk
# 主包 build.sh 姊妹篇；面板 dist 源在 scripts/shell/panel（node v24 套件）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PATH="/var/apps/nodejs_v24/target/bin:${PATH}"
FP_BIN="$ROOT/scripts/fnpack-1.2.3-linux-amd64"
FP="$ROOT/fnpack-panel"
VER="$(cat "$FP/VERSION" | tr -d '[:space:]')"
echo "═══ 构建 qwenpaw-panel v${VER} ═══"

if [ "${SKIP_PANEL_BUILD:-0}" != "1" ]; then
  echo "[1/3] panel npm ci + build（node $(node -v)）..."
  ( cd "$ROOT/scripts/shell/panel" && npm ci --include=dev --no-audit --no-fund && npm run build )
else
  echo "[1/3] 复用 scripts/shell/panel/dist（SKIP_PANEL_BUILD=1）"
fi
[ -f "$ROOT/scripts/shell/panel/dist/index.html" ] || { echo "✗ 缺面板产物"; exit 1; }

APP="$FP/app"
mkdir -p "$APP/cmd" "$APP/ui/images"
cp scripts/shell/fnshell.py "$APP/fnshell.py"
# 官方技能授权机制：捆绑 trim-cli（脚本+linux-x64 二进制，与 fnOS 官方 skill 同款布局 scripts/ + bin/）
mkdir -p "$APP/vendor/trim-cli/scripts" "$APP/vendor/trim-cli/bin"
cp scripts/vendor/trim-cli/scripts/trim-cli "$APP/vendor/trim-cli/scripts/"
cp scripts/vendor/trim-cli/bin/trim-cli-linux-x64 "$APP/vendor/trim-cli/bin/"
chmod +x "$APP/vendor/trim-cli/scripts/trim-cli" "$APP/vendor/trim-cli/bin/trim-cli-linux-x64"
rm -rf "$APP/panel_dist"; cp -a scripts/shell/panel/dist "$APP/panel_dist"
cp fnpack/app/ui/images/icon_256.png "$APP/ui/images/icon_256.png"
cp fnpack/app/ui/images/icon_64.png "$APP/ui/images/icon_64.png"
cp "$APP/ui/images/icon_256.png" "$FP/ICON.PNG"
cp "$APP/ui/images/icon_256.png" "$FP/ICON_256.PNG"
# ui/config 已在工程内；cmd/main 已在工程内（本脚本只做文件同步，不改内容）
n=$(find "$APP" -xtype l | wc -l); [ "$n" -gt 0 ] && { find "$APP" -xtype l -delete; echo "  清理断链 $n 个"; }

echo "[2/3] 隐私扫描 ..."
if grep -rIl -e '/vol[0-9]\+/@app\(home\|data\)/' -e 'sk-[A-Za-z0-9]\{20,\}' -e 'token=[A-Za-z0-9]' "$APP" --exclude-dir=node_modules 2>/dev/null | grep -v '\.map$' | head -5 | grep -q .; then
  echo "✗ 疑似泄漏本机路径/密钥，中止"; exit 1
fi

echo "[3/3] fnpack 打包 ..."
sed -i "s/^version .*=.*/version               = $VER/" "$FP/manifest"
cd "$FP"
"$FP_BIN" build
mv -f qwenpaw-panel.fpk "$ROOT/dist/qwenpaw-panel_v${VER}_x86.fpk" 2>/dev/null || mv -f *.fpk "$ROOT/dist/"
ls -la "$ROOT/dist/"
echo "═══ 完成 ═══"
