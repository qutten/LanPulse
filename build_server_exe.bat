@echo off
title 构建独立版服务端 exe
cd /d "%~dp0"

if not exist "%~dp0icon.ico" (
    echo [提示] 未找到 icon.ico，先运行: python toolsmake_icon.py
    echo        （需要 pip install pillow）
    pause
    exit /b 1
)

where pyinstaller >nul 2>nul
if not %errorlevel%==0 (
    echo [错误] 未找到 pyinstaller，请先安装：
    echo   pip install pyinstaller
    pause
    exit /b 1
)

echo [1/2] 清理旧构建 ...
if exist "buildpyinstaller" rmdir /s /q "buildpyinstaller"

echo [2/2] 打包单文件 exe（约 1~2 分钟）...
pyinstaller --noconfirm --clean --onefile --console --name lanpulse-server --icon "%~dp0icon.ico" --distpath "%~dp0dist" --workpath "%~dp0buildpyinstaller" --specpath "%~dp0buildpyinstaller" "%~dp0serverserver.py"
if not %errorlevel%==0 (
    echo.
    echo 打包失败：请查看上方错误信息。
    pause
    exit /b 1
)

echo.
echo 打包成功：%~dp0distlanpulse-server.exe
echo 该文件为独立版，复制到未安装 Python 的电脑上即可直接运行。
pause
