@echo off
title 内网测速服务端
cd /d "%~dp0"

rem ============================================================
rem  启动优先级：独立版 exe（免安装 Python）> python 源码运行
rem ============================================================

if exist "%~dp0dist\lan-speed-server.exe" (
    "%~dp0dist\lan-speed-server.exe" %*
    pause
    exit /b
)

if exist "%~dp0server\lan-speed-server.exe" (
    "%~dp0server\lan-speed-server.exe" %*
    pause
    exit /b
)

cd /d "%~dp0server"
where python >nul 2>nul
if %errorlevel%==0 (
    python server.py %*
) else (
    echo.
    echo [错误] 未找到 python 命令，也未找到独立版服务端 exe。
    echo 请任选一种方式继续：
    echo   1. 使用独立版：把 dist\lan-speed-server.exe 复制到本机，
    echo      双击该 exe，或在项目根目录再次运行本脚本。
    echo   2. 安装 Python 3.10+ 后重试：https://www.python.org/downloads/
    echo      （安装时勾选 "Add python.exe to PATH"）
    echo.
    pause
    exit /b 1
)
pause
