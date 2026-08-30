@echo off
title 内网测速 APK 构建
setlocal

rem ============================================================
rem  内网测速 · 一键构建 APK
rem  项目路径含中文（E:\Desktop\内网测速），Windows 下 Dart AOT
rem  编译器无法直接编译中文路径，因此本脚本先把源码同步到 ASCII
rem  路径 E:\lan-speed-app 再构建，完成后自动把 APK 复制回项目。
rem  前置要求：Flutter SDK 已安装（E:\flutter，可修改下方配置）
rem ============================================================

set "STAGE=E:\lan-speed-app"
set "FLUTTER=E:\flutter\bin\flutter.bat"
set "FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn"
set "PUB_HOSTED_URL=https://pub.flutter-io.cn"
set "GRADLE_USER_HOME=E:\gradle-home"

echo [1/4] 同步源码到暂存目录 ...
if exist "%STAGE%" rmdir /s /q "%STAGE%"
mkdir "%STAGE%"
robocopy "%~dp0app" "%STAGE%" /E /XD .dart_tool build .idea /XF *.iml /NFL /NDL /NJH /NJS >nul
if errorlevel 8 goto :fail

echo [2/4] 清理残留构建守护进程 ...
powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'GradleDaemon|KotlinCompileDaemon' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1

echo [3/4] 构建 release APK（首次较慢，约 5 分钟）...
pushd "%STAGE%"
call "%FLUTTER%" build apk --release
set "BUILD_RESULT=%ERRORLEVEL%"
popd
if not "%BUILD_RESULT%"=="0" goto :fail

echo [4/4] 复制 APK 到项目目录 ...
if not exist "%~dp0app\build\app\outputs\flutter-apk" mkdir "%~dp0app\build\app\outputs\flutter-apk"
copy /y "%STAGE%\build\app\outputs\flutter-apk\app-release.apk" "%~dp0app\build\app\outputs\flutter-apk\app-release.apk" >nul
if not exist "%~dp0dist" mkdir "%~dp0dist"
copy /y "%STAGE%\build\app\outputs\flutter-apk\app-release.apk" "%~dp0dist\lan-speed-test.apk" >nul

echo.
echo ============================================
echo  构建成功！
echo  APK: %~dp0app\build\app\outputs\flutter-apk\app-release.apk
echo  dist: %~dp0dist\lan-speed-test.apk
echo ============================================
pause
exit /b 0

:fail
echo.
echo 构建失败，请查看上方错误信息。
pause
exit /b 1