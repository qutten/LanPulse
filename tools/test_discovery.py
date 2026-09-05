# -*- coding: utf-8 -*-
"""自动发现测试：发送 probe 并监听 announce（验证服务端 UDP 发现功能）。

用法: python test_discovery.py [发现端口]
"""

import json
import socket
import sys
import time

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8900

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("0.0.0.0", PORT))
s.settimeout(8)

probe = json.dumps({"type": "lanpulse-probe", "version": 1}).encode("utf-8")
s.sendto(probe, ("255.255.255.255", PORT))
print(f"已发送 probe 到 255.255.255.255:{PORT}，等待 announce（最多 8 秒）...")

found = []
try:
    while len(found) < 5:
        data, addr = s.recvfrom(4096)
        try:
            msg = json.loads(data.decode("utf-8", "replace"))
            if msg.get("type") == "lanpulse-announce":
                print(f"发现服务端: {msg.get('name')} @ {msg.get('ip')}:{msg.get('port')} "
                      f"(协议 v{msg.get('version')}) 来自 {addr}")
                found.append(msg)
        except (ValueError, TypeError):
            pass
except socket.timeout:
    pass

if not found:
    print("未收到任何 announce。请确认服务端已启动且未使用 --no-announce。")
else:
    print(f"共发现 {len(found)} 条 announce。")
