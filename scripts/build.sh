#!/bin/bash
# qwenpaw-fnos 构建脚本（照 freellmapi-fnos 版式，按上游 Dockerfile 官方构建流）
# 流程: rsync 上游→stage → console npm ci+build → dist 注入 src/qwenpaw/console → pip wheel → 组装 fnpack/app → fnpack 出 .fpk
# 运行环境: NAS 本机（node v24 套件 + python312 套件）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

UPSTREAM="${UPSTREAM_DIR:-/vol1/1000/work/deepseek/src/qwenpaw}"
STAGE="$ROOT/stage"
FP_BIN="$ROOT/scripts/fnpack-1.2.3-linux-amd64"
export PATH="/var/apps/nodejs_v24/target/bin:${PATH}"
PY_RUNTIME="/var/apps/python312/target/bin/python3"
# 版本号 = 上游版本.构建号（上游版本来自 git tag）
UP_VER="$(git -C "$UPSTREAM" describe --tags --abbrev=0 | sed 's/^v//')"
BUILD_NUM="$(cat "$ROOT/VERSION" | tr -d '[:space:]' | rev | cut -d. -f1 | rev)"
VERSION="${UP_VER}.${BUILD_NUM}"
[ -f "$ROOT/VERSION" ] && echo "$VERSION" > "$ROOT/VERSION"
echo "═══ 构建 qwenpaw v$VERSION ═══"

# ── 1) stage 组装（上游干净克隆 + console 构建产物）──
echo "[1/5] rsync 上游 → stage ..."
mkdir -p "$STAGE"
rsync -a --delete --exclude '.git' --exclude 'console/node_modules' --exclude 'console/dist' "$UPSTREAM/" "$STAGE/"

if [ "${SKIP_CONSOLE:-0}" != "1" ]; then
  echo "[2/5] console npm ci + build（node $(node -v)）..."
  ( cd "$STAGE/console" && npm ci --include=dev --no-audit --no-fund && npm run build )
else
  echo "[2/5] 复用 stage/console/dist（SKIP_CONSOLE=1）"
  [ -d "$STAGE/console/dist" ] || { echo "✗ stage/console/dist 不存在"; exit 1; }
fi
# Dockerfile 官方姿势：console 构建输出复制进 src/qwenpaw/console/（无 dist 子目录）
cp -a "$STAGE/console/dist/." "$STAGE/src/qwenpaw/console/"

# ── 3) wheel（纯 Python，构建隔离从 PyPI 拉 setuptools+wheel）──
echo "[3/5] pip wheel ..."
APP="$ROOT/fnpack/app"
rm -rf "$APP/wheels"; mkdir -p "$APP/wheels"
"$PY_RUNTIME" -m pip wheel "$STAGE" -w "$APP/wheels" --no-deps -q
ls -la "$APP/wheels"

# ── 4) 运行时树组装 ──
echo "[4/5] 组装 fnpack/app ..."
cp scripts/vendor/fngateway.py "$APP/fngateway.py"
# 图标：上游官方资产 288×288 RGBA → 256/64（NAS 无 PIL，ffmpeg lanczos）
SRC_ICON="$STAGE/console/public/qwenpaw.png"
[ -f "$SRC_ICON" ] || SRC_ICON="console/public/qwenpaw.png"
ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$SRC_ICON" | grep -q '^256,256$' || {
  ffmpeg -y -v error -i "$SRC_ICON" -vf "scale=256:256:flags=lanczos" "$APP/ui/images/icon_256.png"
  ffmpeg -y -v error -i "$SRC_ICON" -vf "scale=64:64:flags=lanczos"   "$APP/ui/images/icon_64.png"
}
cp "$APP/ui/images/icon_256.png" "$ROOT/fnpack/ICON.PNG"
cp "$APP/ui/images/icon_256.png" "$ROOT/fnpack/ICON_256.PNG"
# 断链清理（安装器遍历全树设权限，断链会炸）
n=$(find "$APP" -xtype l | wc -l); [ "$n" -gt 0 ] && { find "$APP" -xtype l -delete; echo "  清理断链 $n 个"; }

echo "[x] 隐私扫描 ..."
if grep -rIl -e '/vol[0-9]\+/@app\(home\|data\)/' -e 'sk-[A-Za-z0-9]\{20,\}' -e 'token=[A-Za-z0-9]' "$APP" --exclude-dir=node_modules --exclude='*.whl' 2>/dev/null | grep -v '\.map$' | head -5 | grep -q .; then
  echo "✗ 疑似泄漏本机路径/密钥，中止（自行 grep 处理）"; exit 1
fi

# ── 5) fnpack ──
echo "[5/5] fnpack 打包 ..."
sed -i "s/^version .*=.*/version               = $VERSION/" "$ROOT/fnpack/manifest"
cd "$ROOT/fnpack"
"$FP_BIN" build
mv -f qwenpaw.fpk "$ROOT/dist/qwenpaw_v${VERSION}_x86.fpk"
ls -la "$ROOT/dist/"
echo "═══ 完成 ═══"
