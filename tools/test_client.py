# -*- coding: utf-8 -*-
"""内网测速 · 协议测试客户端（Python 模拟手机端）

用于验证服务端（docs/协议设计.md 的客户端实现参考）：

    python test_client.py --host 127.0.0.1 --duration 5 --concurrency 4
    python test_client.py --host 192.168.1.5 --tests ping
"""

import argparse
import json
import socket
import statistics
import threading
import time
import uuid

RECV_SIZE = 1 << 20


class LineReader:
    """带缓冲的按行读取器（避免 recv 超时丢失已缓冲数据）。"""

    def __init__(self, sock):
        self.sock = sock
        self.buf = b""

    def read(self, timeout=30):
        self.sock.settimeout(timeout)
        while b"\n" not in self.buf:
            chunk = self.sock.recv(4096)
            if not chunk:
                return None
            self.buf += chunk
        line, _, self.buf = self.buf.partition(b"\n")
        return line.decode("utf-8", "replace")


def send_msg(sock, obj):
    sock.sendall((json.dumps(obj, ensure_ascii=False) + "\n").encode("utf-8"))


def recv_msg(reader, timeout=30):
    line = reader.read(timeout)
    if line is None:
        return None
    try:
        return json.loads(line)
    except ValueError:
        return {"type": "bad-json"}


class Control:
    def __init__(self, host, port, password=None, name="测试客户端"):
        self.host = host
        self.sock = socket.create_connection((host, port), timeout=10)
        self.sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        self.reader = LineReader(self.sock)
        send_msg(self.sock, {"type": "hello", "app": "lan-speedtest",
                             "version": 1, "name": name})
        msg = recv_msg(self.reader, 10)
        if msg is None:
            raise RuntimeError("服务端无响应")
        if msg.get("type") == "auth-required":
            send_msg(self.sock, {"type": "auth", "password": password or ""})
            msg = recv_msg(self.reader, 10)
        if msg.get("type") != "welcome":
            raise RuntimeError(f"握手失败: {msg}")
        self.welcome = msg
        print(f"已连接服务端: {msg.get('name')} (协议版本 {msg.get('version')}, "
              f"最大并发 {msg.get('maxConcurrency')})")

    def close(self):
        try:
            send_msg(self.sock, {"type": "bye"})
        except OSError:
            pass
        try:
            self.sock.close()
        except OSError:
            pass


def ping_test(ctrl, count, interval):
    """延迟/抖动/丢包测试：逐个发送 ping 并等待 pong，统计 RTT。"""
    rtts = []
    received = 0
    timeout = max(interval * 4 + 0.3, 1.0)
    for i in range(count):
        ts = int(time.time() * 1000)
        send_msg(ctrl.sock, {"type": "ping", "seq": i, "ts": ts})
        t0 = time.time()
        deadline = t0 + timeout
        got = False
        while time.time() < deadline:
            msg = recv_msg(ctrl.reader, min(0.3, timeout))
            if msg is None:
                break
            if msg.get("type") == "pong" and msg.get("ts") == ts:
                rtts.append((time.time() - t0) * 1000)
                received += 1
                got = True
                break
        time.sleep(interval)

    lost = count - received
    loss_pct = lost / count * 100 if count else 0.0
    result = {"sent": count, "received": received, "lossPct": loss_pct,
              "rttMin": None, "rttAvg": None, "rttMax": None, "jitterMs": None}
    if rtts:
        result.update({
            "rttMin": round(min(rtts), 2),
            "rttAvg": round(statistics.fmean(rtts), 2),
            "rttMax": round(max(rtts), 2),
            "jitterMs": round(statistics.fmean(
                [abs(rtts[i] - rtts[i - 1]) for i in range(1, len(rtts))]), 2),
        })
    print(f"Ping: 发送 {count} 条, 接收 {received} 条, 丢包 {loss_pct:.1f}%")
    if rtts:
        print(f"  延迟: 最小 {result['rttMin']} ms / 平均 {result['rttAvg']} ms / "
              f"最大 {result['rttMax']} ms   抖动: {result['jitterMs']} ms")
    return result


def download_worker(host, port, token, block, counter, lock, stop):
    try:
        s = socket.create_connection((host, port), timeout=10)
        s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        send_msg(s, {"type": "data", "test": "download", "token": token})
        while not stop.is_set():
            data = s.recv(block)
            if not data:
                break
            with lock:
                counter["bytes"] += len(data)
                if counter.get("first") is None:
                    counter["first"] = time.time()
        s.close()
    except OSError:
        with lock:
            counter["errors"] = counter.get("errors", 0) + 1


def upload_worker(host, port, token, block, counter, lock, stop):
    try:
        s = socket.create_connection((host, port), timeout=10)
        s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        send_msg(s, {"type": "data", "test": "upload", "token": token})
        while not stop.is_set():
            s.sendall(b"\x00" * block)
            with lock:
                counter["bytes"] += block
                if counter.get("first") is None:
                    counter["first"] = time.time()
        s.close()
    except OSError:
        with lock:
            counter["errors"] = counter.get("errors", 0) + 1


def speed_test(ctrl, test, host, port, duration, concurrency, block_size):
    """下载/上传测速：并发 N 条数据连接，每秒采样，返回结果与曲线样本。"""
    token = uuid.uuid4().hex[:12]
    send_msg(ctrl.sock, {"type": "start", "test": test, "duration": duration,
                         "concurrency": concurrency, "blockSize": block_size,
                         "token": token})
    msg = recv_msg(ctrl.reader, 10)
    if msg.get("type") != "started":
        raise RuntimeError(f"{test} start 失败: {msg}")

    counter = {"bytes": 0, "errors": 0}
    lock = threading.Lock()
    stop = threading.Event()
    samples = []  # (t 秒, 瞬时 Mbps)
    worker = download_worker if test == "download" else upload_worker

    threads = []
    for _ in range(concurrency):
        t = threading.Thread(target=worker, args=(host, port, token, block_size,
                                                  counter, lock, stop))
        t.start()
        threads.append(t)

    t0 = time.time()
    prev_bytes = 0
    prev_t = t0
    while time.time() - t0 < duration:
        time.sleep(0.2)
        now = time.time()
        with lock:
            cur = counter["bytes"]
        samples.append((round(now - t0, 2),
                        round((cur - prev_bytes) * 8 / max(now - prev_t, 1e-6) / 1e6, 2)))
        prev_bytes, prev_t = cur, now

    stop.set()
    for t in threads:
        t.join()
    with lock:
        total = counter["bytes"]
        first = counter.get("first")
        errors = counter.get("errors", 0)
    elapsed = (time.time() - first) if first else duration
    speed = total * 8 / elapsed / 1e6 if elapsed > 0 else 0.0

    print(f"{'下载' if test == 'download' else '上传'}测速: {speed:.2f} Mbps "
          f"(共 {total / 1e6:.1f} MB, 耗时 {elapsed:.2f} s, 并发 {concurrency}, 错误连接 {errors})")
    send_msg(ctrl.sock, {"type": "complete", "test": test, "token": token,
                         "bytes": total, "durationMs": int(elapsed * 1000),
                         "speedMbps": round(speed, 2)})
    ack = recv_msg(ctrl.reader, 10)
    if ack.get("type") != "complete-ack":
        raise RuntimeError(f"complete-ack 失败: {ack}")
    return {"speedMbps": round(speed, 2), "bytes": total,
            "durationMs": int(elapsed * 1000), "samples": samples}


def main():
    parser = argparse.ArgumentParser(description="内网测速协议测试客户端")
    parser.add_argument("--host", default="127.0.0.1", help="服务端 IP")
    parser.add_argument("--port", type=int, default=8899, help="服务端 TCP 端口")
    parser.add_argument("--password", default=None, help="访问口令")
    parser.add_argument("--duration", type=int, default=5, help="每项测速时长(秒)")
    parser.add_argument("--concurrency", type=int, default=4, help="并发连接数")
    parser.add_argument("--ping-count", type=int, default=20, help="Ping 条数")
    parser.add_argument("--block-size", type=int, default=65536, help="数据块大小")
    parser.add_argument("--tests", default="all",
                        help="测速项: all / ping / download / upload（逗号分隔）")
    args = parser.parse_args()

    tests = [t.strip() for t in args.tests.split(",") if t.strip()]
    if "all" in tests:
        tests = ["ping", "download", "upload"]

    ctrl = Control(args.host, args.port, args.password)
    result = {"server": ctrl.welcome.get("name"), "host": args.host, "tests": {}}
    try:
        if "ping" in tests:
            result["tests"]["ping"] = ping_test(ctrl, args.ping_count, 0.03)
        if "download" in tests:
            result["tests"]["download"] = speed_test(
                ctrl, "download", args.host, args.port, args.duration,
                args.concurrency, args.block_size)
        if "upload" in tests:
            result["tests"]["upload"] = speed_test(
                ctrl, "upload", args.host, args.port, args.duration,
                args.concurrency, args.block_size)
    finally:
        ctrl.close()
    print("\n结果汇总: " + json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
