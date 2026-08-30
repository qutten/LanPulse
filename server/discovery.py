# -*- coding: utf-8 -*-
"""UDP 自动发现：周期性广播 announce，响应 probe（docs/协议设计.md 第 2 节）"""

import json
import socket
import threading
import time

import protocol


def get_local_ips():
    """获取本机局域网 IPv4 地址列表（排除 127.*）。"""
    ips = set()
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None):
            if info[0] == socket.AF_INET:
                ip = info[4][0]
                if not ip.startswith("127."):
                    ips.add(ip)
    except socket.gaierror:
        pass
    if not ips:
        # 兜底：UDP connect 获取出口地址（TEST-NET 地址不会真正发包）
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("192.0.2.1", 9))
            ips.add(s.getsockname()[0])
            s.close()
        except OSError:
            pass
    return sorted(ips)


def make_announce(name, ip, port):
    return json.dumps({
        "type": "lan-speedtest-announce",
        "name": name,
        "ip": ip,
        "port": port,
        "version": protocol.VERSION,
    }, ensure_ascii=False)


def start_discovery(server_name, tcp_port, discovery_port, stop_event, log):
    """在后台线程运行 UDP 发现服务。返回 socket 供主线程关闭。"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("0.0.0.0", discovery_port))
    sock.settimeout(0.5)

    ips = get_local_ips()
    announce_ip = ips[0] if ips else "127.0.0.1"
    payload = make_announce(server_name, announce_ip, tcp_port).encode("utf-8")

    def run():
        next_announce = 0.0
        while not stop_event.is_set():
            now = time.time()
            try:
                data, addr = sock.recvfrom(4096)
                try:
                    msg = json.loads(data.decode("utf-8", "replace"))
                    if msg.get("type") == "lan-speedtest-probe":
                        sock.sendto(payload, addr)
                except (ValueError, TypeError):
                    pass
            except socket.timeout:
                pass
            if now >= next_announce:
                next_announce = now + protocol.ANNOUNCE_INTERVAL
                try:
                    sock.sendto(payload, ("255.255.255.255", discovery_port))
                except OSError as exc:
                    log(f"[发现] 广播失败: {exc}")

    threading.Thread(target=run, name="discovery", daemon=True).start()
    return sock
