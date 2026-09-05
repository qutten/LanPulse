# LanPulse

[中文](./README.md)

A LAN speed test tool. The server runs on a PC, the app runs on a phone. It measures download speed, upload speed, latency, jitter and packet loss between the two devices over the LAN. All test traffic stays on the local network; no internet connection is used.

- PC side: a Python terminal program, optionally packaged as a standalone exe that needs no Python
- Phone side: an Android app (Flutter), connects to the server via auto-discovery or manual IP entry

## Features

- Download and upload speed tests
- Latency (min / avg / max), jitter, packet loss
- Auto-discovery of the server (UDP broadcast), plus manual IP/port entry
- Real-time speed chart during the test
- Results saved to history automatically
- Optional access password
- English and Chinese UI

## Screenshots

Server startup:

![Server startup](docs/screenshots/server-console.jpg)

| App home | Speed test | Result |
| --- | --- | --- |
| ![App home](docs/screenshots/app-home.jpg) | ![Speed test](docs/screenshots/app-speed.jpg) | ![Result](docs/screenshots/app-result.jpg) |

## Quick Start

1. On the PC, double-click `run.bat`. It runs `dist\lanpulse-server.exe` if present, otherwise it falls back to the Python source.
2. On the phone, install `dist\lanpulse.apk`.
3. Connect the phone and the PC to the same WiFi.
4. Open the app. It discovers the server automatically, or you can enter the PC's IP and port manually.
5. Choose a duration and concurrency, then tap Start.

## Metrics

| Metric | Unit | Meaning |
| --- | --- | --- |
| Download speed | Mbps | average throughput from PC to phone |
| Upload speed | Mbps | average throughput from phone to PC |
| Latency | ms | round-trip time of small packets, shown as min / avg / max |
| Jitter | ms | average difference between consecutive pings; lower is more stable |
| Packet loss | % | share of packets that got no response |

## Server

The server is a Python program, source in `server/`.

### Running

Option 1: standalone exe

- Windows 10/11, no Python required.
- Copy `dist\lanpulse-server.exe` to the PC and double-click it. From the project directory, just double-click `run.bat`.

Option 2: run from source

Requires Python 3.10+ (check "Add python.exe to PATH" during installation).

```
cd server
python server.py
```

The terminal prints the local IP and ports on startup:

```
[17:20:07] LanPulse 服务端 v1   名称: DESKTOP-ABC
[17:20:07] 本机局域网 IP: 192.168.1.5
[17:20:07] TCP 服务端口: 8899   UDP 自动发现端口: 8900
[17:20:08] 服务已启动，按 Ctrl+C 退出
```

### Arguments

| Argument | Description | Default |
| --- | --- | --- |
| `--port` | TCP service port | 8899 |
| `--discovery-port` | UDP discovery port | TCP port + 1 |
| `--name` | Server name, shown in the app | local hostname |
| `--password` | Access password | disabled |
| `--max-clients` | Maximum concurrent clients | 8 |
| `--block-size` | Data block size (bytes) | 65536 |
| `--no-announce` | Disable auto-discovery announcements | announcements on |

Example:

```
python server.py --port 9000 --password 1234 --name 我的电脑
```

### Firewall

On startup the program tries to add a Windows firewall inbound rule, which requires administrator privileges. If that fails and the phone cannot connect, allow the ports manually:

- Inbound rule: TCP 8899 (or your custom port)
- Inbound rule: UDP 8900 (auto-discovery, optional)

### Connecting from the phone

- Auto-discovery: with the phone and the PC on the same WiFi, the app scans automatically; no address needed.
- Manual: enter the PC's LAN IP and port, used when discovery is unavailable.

## Phone App

### Building the APK

Requires Flutter SDK 3.x, Android SDK, JDK 17+. Double-click `build_apk.bat` in the project root. When the build finishes, the APK is copied to:

- `app\build\app\outputs\flutter-apk\app-release.apk`
- `dist\lanpulse.apk`

Note: if the project path contains Chinese characters (e.g. a Chinese folder name), the Dart AOT compiler fails on Windows. The script syncs the source to an ASCII path (`E:\lanpulse-build`) first, builds there, then copies the APK back. When running `flutter build apk` manually, use a non-ASCII path as well.

### Usage

1. Connect the phone and the PC to the same WiFi.
2. Run `run.bat` on the PC.
3. Open the app; it discovers the server automatically, or tap + (bottom right) to enter the IP manually.
4. Choose a duration (5/10/30/60 s) and concurrency (1/2/4/8), toggle upload and ping tests, then tap Start.
5. The speed chart updates in real time; when finished, all metrics are shown and saved to history automatically.

## Development & Testing

### Verify the server (no phone needed)

Terminal 1: start the server

```
python server.py
```

Terminal 2: run the test client (simulates the phone)

```
python tools/test_client.py --host 127.0.0.1 --duration 5 --concurrency 4
```

`test_client.py` arguments: `--host`, `--port`, `--password`, `--duration`, `--concurrency`, `--ping-count`, `--tests` (all/ping/download/upload).

### Verify auto-discovery

```
python tools/test_discovery.py
```

Sends a probe and listens for announcements to verify the server's UDP discovery.

### Package the standalone exe

Install PyInstaller first:

```
pip install pyinstaller
python -m PyInstaller --noconfirm --clean --onefile --console --name lanpulse-server --icon icon.ico --distpath dist --workpath build\pyinstaller --specpath build\pyinstaller server\server.py
```

Or double-click `build_server_exe.bat`. The output is `dist\lanpulse-server.exe`.

### Icon

Run `python tools\make_icon.py` to regenerate `icon.ico` from the app icon (requires `pip install pillow`).

## Project Structure

```
├── docs/                 # requirements and protocol documents
├── server/               # server Python source
│   ├── server.py         # entry point: startup, argument parsing
│   ├── core.py           # TCP control/data connection handling
│   ├── discovery.py      # UDP auto-discovery broadcasting
│   └── protocol.py       # protocol constants
├── app/                  # phone app Flutter project (Android)
├── tools/                # test client, discovery test, icon scripts
├── dist/                 # build outputs (exe, apk)
├── run.bat               # one-click server start on Windows
├── build_apk.bat         # one-click APK build
└── build_server_exe.bat  # one-click server exe packaging
```

## Documents

- [Requirements](docs/需求文档.md) (Chinese)
- [Protocol design](docs/协议设计.md) (Chinese)
