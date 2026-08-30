# 内网测速（LAN Speed Test）

局域网测速软件：**电脑端**以终端程序运行（测速服务端），**手机端**为 Android App（测速客户端），测量手机 ↔ 电脑在局域网内的真实速度（下载 / 上传 / 延迟 / 抖动 / 丢包），**全程不依赖互联网**。

> 需求与协议文档见 `docs/` 目录：
> - `docs/需求文档.md` — 功能与非功能需求
> - `docs/协议设计.md` — 服务端与 App 的通信协议（唯一契约）

## 目录结构

```
内网测速/
├── docs/               # 需求文档、协议设计文档
├── server/             # 电脑端 Python 测速服务端（源码）
│   ├── server.py       # 入口（终端运行）
│   ├── core.py         # TCP 控制/数据连接处理
│   ├── discovery.py    # UDP 自动发现
│   └── protocol.py     # 协议常量
├── app/                # 手机端 Flutter 工程（Android）
├── dist/               # 构建产物：lan-speed-server.exe（免 Python 独立版）、lan-speed-test.apk
├── tools/
│   └── test_client.py  # 协议测试客户端（Python 模拟手机端，可独立验证服务端）
├── run.bat             # Windows 一键启动服务端（优先独立版 exe，回退源码运行）
├── build_apk.bat       # 一键构建手机 APK
└── build_server_exe.bat# 一键构建独立版服务端 exe（需 pyinstaller）
```

---

## 一、电脑端（服务端）使用

### 1. 方式一：独立版（免安装 Python，推荐）

- 仅需 Windows 10 / 11，**无需安装 Python 或任何其他软件**
- 将 `dist\lan-speed-server.exe` 复制到电脑上，**双击运行**即可；或放回项目目录后双击 `run.bat`
- 功能与参数和源码版完全一致（`--port` / `--password` / `--name` 等均可用）
- 该 exe 由源码打包生成（见「四、开发与测试」）

### 2. 方式二：Python 源码运行

- 需要 Python 3.10+（下载：https://www.python.org/downloads/ ，安装时勾选 **Add python.exe to PATH**）

双击 **`run.bat`**（自动优先使用独立版 exe），或在终端中执行：

```bat
cd server
python server.py
```

启动后终端会打印本机局域网 IP、端口等信息，例如：

```
[17:20:07] 内网测速服务端 v1   名称: DESKTOP-ABC
[17:20:07] 本机局域网 IP: 192.168.1.5
[17:20:07] TCP 服务端口: 8899   UDP 自动发现端口: 8900
[17:20:08] 服务已启动，按 Ctrl+C 退出
```

### 3. 常用参数

| 参数 | 说明 | 默认 |
| --- | --- | --- |
| `--port 9000` | 修改 TCP 服务端口 | 8899 |
| `--discovery-port 9001` | 修改 UDP 自动发现端口 | TCP 端口 + 1 |
| `--name 我的电脑` | 自定义服务端名称（手机端显示） | 本机主机名 |
| `--password 1234` | 开启访问口令 | 不开启 |
| `--max-clients 4` | 最大并发客户端数 | 8 |
| `--block-size 131072` | 数据块大小（字节） | 65536 |
| `--no-announce` | 关闭自动发现广播（只能手动输入 IP 连接） | 关闭该项 |

示例：

```bat
python server.py --port 9000 --password 1234 --name 客厅电脑
```

### 4. 防火墙

启动时程序会尝试自动添加 Windows 防火墙入站规则（**需要以管理员身份运行**才会成功）。若未成功且手机连不上，请手动放行：

- 入站规则：允许 **TCP 8899**（或自定义端口）
- 入站规则：允许 **UDP 8900**（自动发现，可选）

### 5. 手机连接方式

1. 手机 App 自动发现（同一 WiFi 下，无需输入任何地址）；
2. 或手动输入电脑的局域网 IP 和端口（自动发现不可用时）。

---

## 二、手机端（Android App）

### 1. 构建 APK（需要 Flutter SDK）

**推荐：双击项目根目录的 `build_apk.bat`**（一键构建，自动处理国内镜像与中文路径问题），产物自动复制到：
- `app\build\app\outputs\flutter-apk\app-release.apk`
- `dist\lan-speed-test.apk`

> **为什么需要这个脚本**：项目路径含中文（`E:\Desktop\内网测速`），Windows 下 Dart AOT 编译器无法直接编译中文路径。脚本先把源码同步到 ASCII 路径 `E:\lan-speed-app` 构建，再把 APK 拷回。若自行使用 `flutter build apk`，请确保在**非中文路径**下运行。

构建前置要求：
- Flutter SDK 3.x（https://docs.flutter.cn/get-started/install/windows ）；本机已安装于 `E:\flutter`
- Android SDK 与 JDK 17+；国内网络建议保留脚本中的镜像配置（flutter-io.cn / 腾讯 Gradle 镜像 / 阿里云 Maven）

### 2. 使用

1. 手机与电脑连接**同一局域网**（同一 WiFi / 同一路由器）。
2. 电脑端启动 `run.bat`。
3. 打开 App → 自动发现电脑服务端（或点右下角 + 手动输入 IP）→ 进入测速页。
4. 选择测速时长（5/10/30/60 秒）、并发数（1/2/4/8），开关上传测速与 Ping 测试 → 点「开始测速」。
5. 测速过程实时显示速度曲线；完成后展示全部指标并**自动保存到历史记录**。

---

## 三、指标说明

| 指标 | 单位 | 含义 |
| --- | --- | --- |
| 下载速度 | Mbps | 手机从电脑接收数据的平均吞吐 |
| 上传速度 | Mbps | 手机向电脑发送数据的平均吞吐 |
| 延迟（Ping） | ms | 小包往返时间：最小 / 平均 / 最大 |
| 抖动（Jitter） | ms | 相邻延迟差的平均值，越小越稳定 |
| 丢包率 | % | 未收到回应的数据包比例，无线信号差时升高 |

---

## 四、开发与测试

### 验证服务端（无需手机）

```bat
:: 终端 1：启动服务端
python server.py

:: 终端 2：运行测试客户端（模拟手机端）
python tools/test_client.py --host 127.0.0.1 --duration 5 --concurrency 4
```

`test_client.py` 参数：`--host`、`--port`、`--password`、`--duration`、`--concurrency`、`--ping-count`、`--tests`（all/ping/download/upload）。

### 打包独立版服务端（免 Python 分发，需要 PyInstaller）

**一键方式：双击项目根目录的 `build_server_exe.bat`**（需先 `pip install pyinstaller`）。

手动方式：

```bat
pip install pyinstaller

python -m PyInstaller --noconfirm --clean --onefile --console --name lan-speed-server --icon icon.ico ^
  --distpath dist --workpath build\pyinstaller --specpath build\pyinstaller ^
  server\server.py
```

产物为 `dist\lan-speed-server.exe`（约 7 MB 单文件，图标与手机 App 一致），复制到**未安装 Python** 的电脑上双击即可运行，手机 App 照常自动发现/连接。

> 图标管理：执行 `python tools\make_icon.py` 可从手机 App 图标重新生成 `icon.ico` 与 `dist\内网测速-图标.jpg`（白底分享图，需 `pip install pillow`）。
