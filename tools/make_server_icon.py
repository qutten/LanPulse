# -*- coding: utf-8 -*-
"""从白底 JPG 分享图生成服务端 exe 图标（多尺寸 ICO）。

用法: python tools/make_server_icon.py
产物: dist/lanpulse-icon.ico（供 PyInstaller 打包服务端 exe 使用）
"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "dist", "lanpulse-icon.jpg")
OUT = os.path.join(ROOT, "dist", "lanpulse-icon.ico")

if not os.path.exists(SRC):
    raise SystemExit(f"未找到源图片: {SRC}")

img = Image.open(SRC).convert("RGBA")
# 主尺寸 256（Windows ICO 标准最大尺寸），多级缩放兼容各显示场景
if img.width != 256:
    img = img.resize((256, 256), Image.LANCZOS)
img.save(OUT, format="ICO",
         sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])

print("ICO ->", OUT, os.path.getsize(OUT), "bytes")
