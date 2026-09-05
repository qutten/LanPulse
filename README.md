# LanPulse 脉冲测速

[English](./README.en.md)

局域网测速工具。电脑上运行服务端，手机上运行 App，测量手机与电脑之间在局域网内的下载速度、上传速度、延迟、抖动和丢包率。测速数据只走局域网，不经过互联网。

- 电脑端：Python 终端程序，可打包成不需要安装 Python 的单文件 exe
- 手机端：Android App（Flutter），自动发现或手动输入 IP 连接服务端

## 功能

- 下载测速、上传测速
- 延迟（最小 / 平均 / 最大）、抖动、丢包率
- 自动发现服务端（UDP 广播），也支持手动输入 IP 和端口
- 测速过程中实时显示速度曲线
- 测速结果自动保存到历史记录
- 支持访问口令
- 界面支持中英文

## 截图

服务端启动：

![服务端启动](docs/screenshots/server-console.jpg)

| App 首页 | 测速页 | 结果页 |
| --- | --- | --- |
| ![App 首页](docs/screenshots/app-home.jpg) | ![测速页](docs/screenshots/app-speed.jpg) | ![结果页](docs/screenshots/app-result.jpg) |

## 快速开始

1. 电脑上双击 `run.bat`。脚本优先运行 `dist\lanpulse-server.exe`，不存在时回退到 Python 源码。
2. 手机上安装 `dist\lanpulse.apk`。
3. 手机和电脑连接到同一个 WiFi。
4. 打开 App，自动发现服务端，或手动输入电脑的 IP 和端口。
5. 选择测速时长和并发数，点击「开始测速」。

## 测速指标

| 指标 | 单位 | 说明 |
| --- | --- | --- |
| 下载速度 | Mbps | 手机从服务端接收数据的平均吞吐 |
| 上传速度 | Mbps | 手机向服务端发送数据的平均吞吐 |
| 延迟 | ms | 小包往返时间，显示最小 / 平均 / 最大 |
| 抖动 | ms | 相邻延迟差的平均值，越小越稳定 |
| 丢包率 | % | 未收到应答的数据包占比 |

## 服务端

服务端是 Python 程序，源码在 `server/`。

### 运行

方式一：独立版 exe

- 需要 Windows 10 / 11，不需要安装 Python。
- 复制 `dist\lanpulse-server.exe` 到电脑双击运行；放在项目目录时直接双击 `run.bat`。

方式二：源码运行

需要 Python 3.10 以上（安装时勾选 Add python.exe to PATH）。

```
cd server
python server.py
```

启动后终端会打印本机 IP 和端口：

```
[17:20:07] LanPulse 服务端 v1   名称: DESKTOP-ABC
[17:20:07] 本机局域网 IP: 192.168.1.5
[17:20:07] TCP 服务端口: 8899   UDP 自动发现端口: 8900
[17:20:08] 服务已启动，按 Ctrl+C 退出
```

### 参数

| 参数 | 说明 | 默认值 |
| --- | --- | --- |
| `--port` | TCP 服务端口 | 8899 |
| `--discovery-port` | UDP 自动发现端口 | TCP 端口 + 1 |
| `--name` | 服务端名称，显示在手机端 | 本机主机名 |
| `--password` | 访问口令 | 不开启 |
| `--max-clients` | 最大并发客户端数 | 8 |
| `--block-size` | 数据块大小（字节） | 65536 |
| `--no-announce` | 关闭自动发现广播 | 广播开启 |

示例：

```
python server.py --port 9000 --password 1234 --name 我的电脑
```

### 防火墙

启动时程序会尝试添加 Windows 防火墙入站规则，需要管理员权限。添加失败且手机连不上时，手动放行：

- 入站规则：TCP 8899（或自定义端口）
- 入站规则：UDP 8900（自动发现，可选）

### 手机连接方式

- 自动发现：手机和电脑在同一 WiFi 下，打开 App 自动扫描，无需输入地址。
- 手动连接：输入电脑的局域网 IP 和端口，自动发现不可用时使用。

## 手机端 App

### 构建 APK

需要 Flutter SDK 3.x、Android SDK、JDK 17 以上。双击项目根目录的 `build_apk.bat`，构建完成后 APK 复制到：

- `app\build\app\outputs\flutter-apk\app-release.apk`
- `dist\lanpulse.apk`

项目路径含中文（比如中文文件夹名）时，Windows 下 Dart AOT 编译会失败。脚本会先把源码同步到 ASCII 路径 `E:\lanpulse-build` 构建，再把 APK 拷回。手动执行 `flutter build apk` 时，也需要在非中文路径下运行。

### 使用

1. 手机和电脑连接同一个 WiFi。
2. 电脑上运行 `run.bat`。
3. 打开 App，自动发现服务端，或点右下角 + 手动输入 IP。
4. 选择测速时长（5/10/30/60 秒）、并发数（1/2/4/8），选择是否开启上传测速和 Ping 测试，点击「开始测速」。
5. 测速过程中实时显示速度曲线；结束后显示全部指标，自动保存到历史记录。

## 开发与测试

### 验证服务端（不需要手机）

终端 1：启动服务端

```
python server.py
```

终端 2：运行测试客户端（模拟手机端）

```
python tools/test_client.py --host 127.0.0.1 --duration 5 --concurrency 4
```

`test_client.py` 参数：`--host`、`--port`、`--password`、`--duration`、`--concurrency`、`--ping-count`、`--tests`（all/ping/download/upload）。

### 验证自动发现

```
python tools/test_discovery.py
```

发送 probe 并监听 announce，验证服务端 UDP 自动发现功能。

### 打包独立版 exe

先安装 PyInstaller：

```
pip install pyinstaller
python -m PyInstaller --noconfirm --clean --onefile --console --name lanpulse-server --icon icon.ico --distpath dist --workpath build\pyinstaller --specpath build\pyinstaller server\server.py
```

也可以直接双击 `build_server_exe.bat`，产物为 `dist\lanpulse-server.exe`。

### 图标

运行 `python tools\make_icon.py` 可从 App 图标重新生成 `icon.ico`（需要 `pip install pillow`）。

## 目录结构

```
├── docs/                 # 需求文档、协议设计
├── server/               # 服务端 Python 源码
│   ├── server.py         # 入口：启动、参数解析
│   ├── core.py           # TCP 控制/数据连接处理
│   ├── discovery.py      # UDP 自动发现广播
│   └── protocol.py       # 协议常量
├── app/                  # 手机端 Flutter 工程（Android）
├── tools/                # 测试客户端、自动发现测试、图标脚本
├── dist/                 # 构建产物（exe、apk）
├── run.bat               # Windows 一键启动服务端
├── build_apk.bat         # 一键构建 APK
└── build_server_exe.bat  # 一键打包服务端 exe
```

## 文档

- [需求文档](docs/需求文档.md)
- [协议设计](docs/协议设计.md)
