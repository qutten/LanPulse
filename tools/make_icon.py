# -*- coding: utf-8 -*-
"""生成服务端 exe 图标（icon.ico）与 JPG 分享图（与手机 App 图标一致）。

用法: python tools/make_icon.py
产物: icon.ico（多尺寸，供 Exe 打包）; dist/lanpulse-icon.jpg（白底分享图）
"""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "app", "android", "app", "src", "main", "res",
                   "mipmap-xxxhdpi", "ic_launcher.png")
ICO_OUT = os.path.join(ROOT, "icon.ico")
JPG_OUT = os.path.join(ROOT, "dist", "lanpulse-icon.jpg")

img = Image.open(SRC).convert("RGBA")

# ---- ICO：256 主尺寸 + 多级缩放，兼容 Windows 全场景显示 ----
ico = img
if img.width < 256:
    ico = img.resize((256, 256), Image.LANCZOS)
ico.save(ICO_OUT, format="ICO",
        sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])

# ---- JPG：白底合成（JPG 不支持透明）----
bg = Image.new("RGBA", (512, 512), (255, 255, 255, 255))
big = img.resize((512, 512), Image.LANCZOS)
bg.alpha_composite(big)
bg.convert("RGB").save(JPG_OUT, format="JPEG", quality=92)

print("ICO ->", ICO_OUT, os.path.getsize(ICO_OUT), "bytes")
print("JPG ->", JPG_OUT, os.path.getsize(JPG_OUT), "bytes")
