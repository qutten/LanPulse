# LanPulse 脉冲测速

[English](./README.md)

局域网测速工具。电脑上运行服务端，手机上运行 App，测量手机与电脑之间在局域网内的下载速度、上传速度、延迟、抖动和丢包率。测速数据只走局域网，不经过互联网。

## 截图

服务端启动：

![服务端启动](docs/screenshots/server-console.jpg)

| App 首页 | 测速页 | 结果页 |
| --- | --- | --- |
| ![App 首页](docs/screenshots/app-home.jpg) | ![测速页](docs/screenshots/app-speed.jpg) | ![结果页](docs/screenshots/app-result.jpg) |

## 下载与使用

从 [Releases](https://github.com/qutten/Demo/releases/latest) 下载两个文件：

- `lan-speed-server.exe` — 电脑端服务端（Windows 10/11，不需要装 Python）
- `lan-speed-test.apk` — 手机端 App（Android）

然后：

1. 电脑上双击 `lan-speed-server.exe`，弹出的终端会显示本机 IP 和端口。
2. 手机上安装 `lan-speed-test.apk`。
3. 手机和电脑连同一个 WiFi。
4. 打开 App，等服务端自动出现；发现不了就点右下角 +，手动输入电脑的 IP 和端口。
5. 选好测速时长和并发数，点「开始测速」。

## 测速指标

| 指标 | 单位 | 说明 |
| --- | --- | --- |
| 下载速度 | Mbps | 手机从服务端接收数据的平均吞吐 |
| 上传速度 | Mbps | 手机向服务端发送数据的平均吞吐 |
| 延迟 | ms | 小包往返时间，显示最小 / 平均 / 最大 |
| 抖动 | ms | 相邻延迟差的平均值，越小越稳定 |
| 丢包率 | % | 未收到应答的数据包占比 |

## 服务端

### 运行

exe 在 Releases 里下载，双击运行，终端会显示：

```
[17:20:07] LanPulse 服务端 v1   名称: DESKTOP-ABC
[17:20:07] 本机局域网 IP: 192.168.1.5
[17:20:07] TCP 服务端口: 8899   UDP 自动发现端口: 8900
[17:20:08] 服务已启动，按 Ctrl+C 退出
```

想用源码跑也可以，需要 Python 3.10+：

```
cd server
python server.py
```

exe 和源码版参数一样，以下参数对两者都适用。

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

启动时程序会尝试自动添加 Windows 防火墙入站规则，需要管理员权限。添加失败且手机连不上时，手动放行：

- 入站规则：TCP 8899（或自定义端口）
- 入站规则：UDP 8900（自动发现，可选）

## 手机 App

### 连接

- 自动发现：手机和电脑在同一 WiFi 下，首页会自动列出服务端，点进去即可。
- 手动连接：点右下角 +，输入电脑的 IP 和端口，自动发现不可用时用。

### 测速

测速页可选测速时长（5/10/30/60 秒）、并发连接数（1/2/4/8），可以关掉上传测速或 Ping 测试再测。测速中实时显示速度曲线，结束后显示全部指标，结果自动存到历史记录（首页右上角的时钟图标里看）。

## 开发与测试

不带手机也能验证服务端，用自带测试客户端模拟手机端。

终端 1 启动服务端：

```
python server.py
```

终端 2 跑测试客户端：

```
python tools/test_client.py --host 127.0.0.1 --duration 5 --concurrency 4
```

`test_client.py` 参数：`--host`、`--port`、`--password`、`--duration`、`--concurrency`、`--ping-count`、`--tests`（all/ping/download/upload）。

单独验证自动发现：

```
python tools/test_discovery.py
```

## 目录结构

```
├── docs/                 # 截图
├── server/               # 服务端源码（Python）
│   ├── server.py         # 入口：启动、参数解析
│   ├── core.py           # TCP 控制/数据连接处理
│   ├── discovery.py      # UDP 自动发现广播
│   └── protocol.py       # 协议常量
├── app/                  # 手机端 Flutter 工程（Android）
├── tools/                # 测试客户端等
├── run.bat               # 一键启动源码版服务端（Windows）
├── build_apk.bat         # 本地构建 APK 用
└── build_server_exe.bat  # 本地打包 exe 用
```
