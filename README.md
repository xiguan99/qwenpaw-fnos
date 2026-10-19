# qwenpaw-fnos

QwenPaw 的飞牛 OS（fnOS）原生应用打包仓库。

- 上游：https://github.com/agentscope-ai/QwenPaw （个人 AI 助理：多频道接入 + Skills 扩展 + 三层记忆）
- 版本号规则：`上游版本.构建号`（见 `VERSION`），当前 2.2.2.1
- 上游许可 Apache-2.0（LICENSE 照抄上游）；fngateway 网关中间件来自 https://github.com/yuexps/FnDepot （`scripts/vendor/fngateway.py`，保留原作者头部）

## 安装与首次启动（Getting Started）

1. 应用中心安装本 `.fpk`，向导里选存储位置与运行权限（默认即可；安装依赖 python312 套件，未装会先装）。
2. **需要联网**：首次启动自动创建 Python 环境并安装依赖（wheel 在包内，依赖从 PyPI 拉取，约几分钟），进度看应用中心日志（或 `tail ${TRIM_PKGVAR}/info.log`）。
3. 装完从 **fnOS 桌面图标**进入（统一网关 `/app/qwenpaw`，iframe），不要直连 2278 端口。
4. 浏览器自动化：默认不含 playwright 浏览器，需要时在应用数据目录的 venv 里 `pip install playwright && playwright install chromium`（或设 env 后首启自动装）；不需要浏览器自动化可忽略。

## 打包机制（与上游的差异）

- venv **不进包**：包内只带本项目 `wheel`（`app/wheels/`），安装后首启在 `${TRIM_PKGVAR}/venv` 在线重建 venv（升级保留 venv，pip 装新 wheel）。
- console 前端在构建时编译并注入 `src/qwenpaw/console/`（上游官方 Dockerfile 姿势），wheel 自带前端。
- 桌面入口走网关注册：`app/ui/config` 声明 `gatewayPrefix=/app/qwenpaw` + `gatewaySocket=app.sock`；`cmd/main` 同时拉两个进程——qwenpaw 本体（监听 127.0.0.1:2278）+ fngateway（UDS `app.sock` ↔ 后端 TCP 反代）。
- 端口 **2278**（固定；如与现网冲突可改 `cmd/main` 的 `QWENPAW_PORT` 并同步 `fngateway --listen`）。

## 仓库布局

    VERSION                  # 上游版本.构建号（publish 从此读取）
    scripts/                 # build.sh / publish.sh / fnpack CLI / vendor/fngateway.py
    stage/                   # 上游 rsync + console 构建（gitignore，构建输入）
    fnpack/                  # 打包树
      manifest               # 应用元数据（appname=qwenpaw，依赖 python312）
      wizard_install.json    # 安装向导（存储位置 + 运行权限）
      wizard_uninstall.json  # 卸载向导（数据保留选项）
      config/                # privilege / resource(data-share)
      cmd/                   # 生命周期脚本（start/stop/status + 各回调，双进程管理）
      app/                   # 运行时树：ui/ 跟踪；wheels/、fngateway.py 构建时生成
      ICON.PNG / ICON_256.PNG # 官方图标 256×256 RGBA（构建时从上游资产缩放）
    dist/                    # 构建产物 *.fpk（gitignore）

## 构建与发布（在 NAS 上跑）

    scripts/build.sh     # console npm ci/build → wheel → 组装 → fnpack 出 fpk
    GITHUB_TOKEN=$DSH_SECRET_GITHUB_PAT_PUSH scripts/publish.sh

## 运行时

- 双进程：venv `python -m qwenpaw app --host 127.0.0.1 --port 2278` + 套件 python312 跑 `fngateway.py`
- 数据：`${TRIM_PKGVAR}/data`（HOME 指到这里，`.qwenpaw` / `.qwenpaw.secret` 在上游默认位置）
- 日志：`${TRIM_PKGVAR}/info.log`（主进程）、`${TRIM_PKGVAR}/gateway.log`（网关）；pid 文件 `app.pid` / `gw.pid`
- 运行依赖：应用中心 `python312`（install_dep_apps）
