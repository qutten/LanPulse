# -*- coding: utf-8 -*-
"""TCP 控制连接与数据连接处理（docs/协议设计.md 第 3、4、5 节）"""

import json
import socket
import threading
import time

import protocol

BUF_SIZE = 1 << 20  # 数据连接收发缓冲区 1 MiB
DATA_RECV_SIZE = 1 << 20  # 上传接收每次读取 1 MiB


class ServerCore:
    """同时处理控制连接与数据连接（两者共用同一 TCP 端口，按首行 JSON 区分）。"""

    def __init__(self, server_name, tcp_port, password, max_clients, block_size, log):
        self.server_name = server_name
        self.tcp_port = tcp_port
        self.password = password
        self.max_clients = max_clients
        self.log = log
        self.lock = threading.Lock()
        self.sessions = {}  # token -> {"test":..., "bytes": 服务端统计字节数}
        self.control_clients = 0
        self._block = bytes(block_size)  # 预生成下载数据块

    # ------------------------------------------------------------------ 入口
    def dispatch(self, conn, addr):
        """读取首行 JSON，按 type 分流到控制或数据连接处理。"""
        try:
            conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            conn.settimeout(600)
            line = self._read_line(conn)
            if line is None:
                return
            msg = self._parse(line, conn)
            if msg is None:
                return
            mtype = msg.get("type")
            if mtype == "data":
                self._handle_data(conn, addr, msg)
                return
            if mtype == "hello":
                self._handle_control(conn, addr, msg)
                return
            self._send(conn, {"type": "error", "code": "unknown-type"})
        except OSError:
            pass
        finally:
            try:
                conn.close()
            except OSError:
                pass

    # ------------------------------------------------------------ 控制连接
    def _handle_control(self, conn, addr, hello):
        with self.lock:
            if self.control_clients >= self.max_clients:
                self._send(conn, {"type": "error", "code": "too-many-clients"})
                return
            self.control_clients += 1
        authed = self.password is None
        try:
            self.log(f"[连接] {addr[0]}:{addr[1]} 控制连接已建立 (name={hello.get('name', '')})")
            self._send(conn, self._welcome() if authed else {"type": "auth-required"})
            while True:
                line = self._read_line(conn)
                if line is None:
                    break
                msg = self._parse(line, conn)
                if msg is None:
                    continue
                mtype = msg.get("type")
                if mtype == "auth":
                    if msg.get("password") == self.password:
                        authed = True
                        self._send(conn, self._welcome())
                    else:
                        self._send(conn, {"type": "auth-failed"})
                        break
                elif mtype == "ping":
                    self._send(conn, {"type": "pong", "seq": msg.get("seq", 0),
                                      "ts": msg.get("ts", 0)})
                elif mtype == "start":
                    test = msg.get("test")
                    if test not in ("download", "upload"):
                        self._send(conn, {"type": "error", "code": "bad-test"})
                        continue
                    token = str(msg.get("token") or "")
                    with self.lock:
                        self.sessions[token] = {"test": test, "bytes": 0}
                    self._send(conn, {
                        "type": "started",
                        "test": test,
                        "duration": msg.get("duration"),
                        "concurrency": msg.get("concurrency"),
                    })
                elif mtype == "complete":
                    token = str(msg.get("token") or "")
                    with self.lock:
                        sess = self.sessions.pop(token, {})
                        server_bytes = sess.get("bytes", 0)
                    self.log(
                        f"[测速] {addr[0]} {msg.get('test')} 完成: "
                        f"客户端上报 {msg.get('speedMbps')} Mbps "
                        f"({msg.get('durationMs')} ms / {msg.get('bytes')} B) "
                        f"服务端统计 {server_bytes} B"
                    )
                    self._send(conn, {"type": "complete-ack"})
                elif mtype == "bye":
                    break
                else:
                    self._send(conn, {"type": "error", "code": "unknown-type"})
        except OSError:
            pass
        finally:
            with self.lock:
                self.control_clients -= 1
            self.log(f"[断开] {addr[0]}:{addr[1]}")

    def _welcome(self):
        return {
            "type": "welcome",
            "name": self.server_name,
            "version": protocol.VERSION,
            "tcpPort": self.tcp_port,
            "maxConcurrency": self.max_clients,
        }

    # ------------------------------------------------------------ 数据连接
    def _handle_data(self, conn, addr, msg):
        test = msg.get("test")
        token = str(msg.get("token") or "")
        try:
            conn.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, BUF_SIZE)
            conn.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, BUF_SIZE)
            if test == "download":
                self._serve_download(conn, token)
            elif test == "upload":
                self._serve_upload(conn, token)
            # 其他 test 值：直接关闭
        except OSError:
            pass

    def _serve_download(self, conn, token):
        """下载测速：持续发送数据块，直到客户端关闭连接。"""
        total = 0
        started = time.time()
        try:
            while True:
                conn.sendall(self._block)
                total += len(self._block)
        except OSError:
            pass
        duration = time.time() - started
        self._record(token, total)
        if total and duration > 0:
            self.log(f"[测速] 下载数据连接 {conn.getpeername()[0]} 发送 {total} B "
                     f"({total * 8 / duration / 1e6:.2f} Mbps)")

    def _serve_upload(self, conn, token):
        """上传测速：循环接收数据直到 EOF（客户端停止发送）。"""
        total = 0
        started = time.time()
        try:
            while True:
                data = conn.recv(DATA_RECV_SIZE)
                if not data:
                    break
                total += len(data)
        except OSError:
            pass
        duration = time.time() - started
        self._record(token, total)
        if total and duration > 0:
            self.log(f"[测速] 上传数据连接 {conn.getpeername()[0]} 接收 {total} B "
                     f"({total * 8 / duration / 1e6:.2f} Mbps)")

    def _record(self, token, nbytes):
        with self.lock:
            sess = self.sessions.get(token)
            if sess is None:
                self.sessions[token] = {"test": "?", "bytes": nbytes}
            else:
                sess["bytes"] = sess.get("bytes", 0) + nbytes

    # ---------------------------------------------------------------- 工具
    def _read_line(self, conn):
        buf = b""
        while b"\n" not in buf:
            chunk = conn.recv(4096)
            if not chunk:
                return None
            buf += chunk
            if len(buf) > protocol.MAX_LINE:
                return None
        line, _, _ = buf.partition(b"\n")
        return line.decode("utf-8", "replace")

    def _parse(self, line, conn):
        try:
            return json.loads(line)
        except (ValueError, TypeError):
            self._send(conn, {"type": "error", "code": "bad-message"})
            return None

    def _send(self, conn, obj):
        try:
            conn.sendall((json.dumps(obj, ensure_ascii=False) + "\n").encode("utf-8"))
        except OSError:
            pass
