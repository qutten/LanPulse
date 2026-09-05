# -*- coding: utf-8 -*-
"""LanPulse 脉冲测速 · 电脑端服务端入口（Windows 终端运行）

用法:
    python server.py                          # 默认端口 8899，自动发现端口 8900
    python server.py --port 9000              # 修改 TCP 端口
    python server.py --password 1234          # 开启访问口令
    python server.py --name 我的电脑          # 自定义服务端名称
"""

import argparse
import socket
import subprocess
import sys
import threading
import time

import protocol
import discovery
import core


def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


def try_add_firewall_rules(port, discovery_port):
    """尝试添加 Windows 防火墙入站规则（需要管理员权限，失败仅提示）。"""
    if sys.platform != "win32":
        return
    rule_name = f"LanPulse-Server-{port}"
    commands = [
        ["netsh", "advfirewall", "firewall", "add", "rule",
         f"name={rule_name}", "dir=in", "action=allow",
         "protocol=TCP", f"localport={port}"],
        ["netsh", "advfirewall", "firewall", "add", "rule",
         f"name={rule_name}-udp", "dir=in", "action=allow",
         "protocol=UDP", f"localport={discovery_port}"],
    ]
    try:
        for cmd in commands:
            subprocess.run(cmd, capture_output=True, timeout=15,
                           creationflags=subprocess.CREATE_NO_WINDOW)
        log("已尝试添加 Windows 防火墙入站规则（TCP/UDP）。")
    except Exception:
        log("提示: 若手机无法连接，请手动在防火墙中放行以下入站端口:")
        log(f"      TCP {port} 与 UDP {discovery_port}")


def main():
    parser = argparse.ArgumentParser(description="LanPulse 服务端（电脑端）")
    parser.add_argument("--port", type=int, default=protocol.DEFAULT_PORT,
                        help=f"TCP 服务端口（默认 {protocol.DEFAULT_PORT}）")
    parser.add_argument("--discovery-port", type=int, default=None,
                        help="UDP 自动发现端口（默认 TCP 端口 + 1）")
    parser.add_argument("--name", default=None, help="服务端名称（默认本机主机名）")
    parser.add_argument("--password", default=None, help="访问口令（默认不开启）")
    parser.add_argument("--max-clients", type=int, default=8,
                        help="最大并发客户端数（默认 8）")
    parser.add_argument("--block-size", type=int, default=protocol.DEFAULT_BLOCK_SIZE,
                        help=f"数据块大小（默认 {protocol.DEFAULT_BLOCK_SIZE}）")
    parser.add_argument("--no-announce", action="store_true",
                        help="关闭 UDP 自动发现广播")
    args = parser.parse_args()

    name = args.name or socket.gethostname()
    discovery_port = args.discovery_port or (args.port + 1)
    stop_event = threading.Event()

    log(f"LanPulse 服务端 v{protocol.VERSION}   名称: {name}")
    ips = discovery.get_local_ips()
    log("本机局域网 IP: " + (", ".join(ips) if ips else "未检测到"))
    log(f"TCP 服务端口: {args.port}   UDP 自动发现端口: {discovery_port}")
    if args.password:
        log("访问口令: 已开启")
    log("手机 App 可自动发现本服务端，或手动输入上述任一 IP 连接")

    core_server = core.ServerCore(name, args.port, args.password,
                                  args.max_clients, args.block_size, log)

    udp_sock = None
    if not args.no_announce:
        try:
            udp_sock = discovery.start_discovery(name, args.port, discovery_port,
                                                 stop_event, log)
            log("自动发现已开启（UDP 广播）")
        except OSError as exc:
            log(f"警告: 自动发现启动失败: {exc}")

    try_add_firewall_rules(args.port, discovery_port)

    tcp_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    tcp_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    tcp_sock.bind(("0.0.0.0", args.port))
    tcp_sock.listen(32)
    tcp_sock.settimeout(0.5)
    log("服务已启动，按 Ctrl+C 退出")

    try:
        while not stop_event.is_set():
            try:
                conn, addr = tcp_sock.accept()
            except socket.timeout:
                continue
            except OSError:
                break
            threading.Thread(target=core_server.dispatch, args=(conn, addr),
                             daemon=True).start()
    except KeyboardInterrupt:
        pass
    finally:
        stop_event.set()
        try:
            tcp_sock.close()
        except OSError:
            pass
        if udp_sock:
            try:
                udp_sock.close()
            except OSError:
                pass
        log("服务已停止")


if __name__ == "__main__":
    main()
