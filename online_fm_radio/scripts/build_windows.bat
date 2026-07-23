@echo off
REM Windows 本地构建脚本 (CMD)
REM 用法: scripts\build_windows.bat [debug^|release^|profile]

setlocal enabledelayedexpansion

set BUILD_TYPE=%1
if "%BUILD_TYPE%"=="" set BUILD_TYPE=release

echo =========================================
echo   Windows 构建 (%BUILD_TYPE%)
echo =========================================

REM 检查 Flutter
where flutter >nul 2>nul
if %errorlevel% neq 0 (
  echo [31m❌ 未找到 flutter 命令，请确保 Flutter 已安装并添加到 PATH[0m
  exit /b 1
)

echo Flutter 版本:
flutter --version

REM 清理
echo.
echo 🧹 清理构建缓存...
flutter clean

REM 获取依赖
echo.
echo 📦 获取依赖...
flutter pub get

REM 生成应用图标
echo.
echo 🎨 生成应用图标...
findstr "flutter_launcher_icons" pubspec.yaml >nul
if %errorlevel% equ 0 (
  dart run flutter_launcher_icons
) else (
  echo ⚠ 未配置 flutter_launcher_icons，跳过
)

REM 启用 Windows 桌面支持
echo.
echo 🔧 启用 Windows 桌面支持...
flutter config --enable-windows-desktop

REM 构建
echo.
echo 🔨 构建 Windows (%BUILD_TYPE%)...
flutter build windows --%BUILD_TYPE%

REM 输出结果
echo.
if exist "build\windows\x64\runner\%BUILD_TYPE%\online_fm_radio.exe" (
  echo ✅ 构建成功!
  echo 📦 构建目录: %CD%\build\windows\x64\runner\%BUILD_TYPE%
  echo 💡 运行应用: build\windows\x64\runner\%BUILD_TYPE%\online_fm_radio.exe
) else (
  echo ❌ 构建失败，未找到构建产物
  exit /b 1
)

endlocal
