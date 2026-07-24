#!/usr/bin/env bash
# Android 本地构建脚本
# 用法: ./scripts/build_android.sh [debug|release|profile]
#
# 功能:
# - 检查 Flutter 环境
# - 清理并重新获取依赖
# - 生成应用图标
# - 构建 APK
# - 输出构建产物路径

set -euo pipefail

BUILD_TYPE="${1:-release}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "========================================="
echo "  Android 构建 ($BUILD_TYPE)"
echo "========================================="

# 检查 Flutter
if ! command -v flutter &> /dev/null; then
  echo "❌ 未找到 flutter 命令，请确保 Flutter 已安装并添加到 PATH"
  exit 1
fi

echo "Flutter 版本:"
flutter --version

# 清理
echo ""
echo "🧹 清理构建缓存..."
flutter clean

# 获取依赖
echo ""
echo "📦 获取依赖..."
flutter pub get

# 生成应用图标
echo ""
echo "🎨 生成应用图标..."
if grep -q "flutter_launcher_icons" pubspec.yaml; then
  dart run flutter_launcher_icons || flutter pub run flutter_launcher_icons
else
  echo "⚠ 未配置 flutter_launcher_icons，跳过"
fi

# 构建
echo ""
echo "🔨 构建 APK ($BUILD_TYPE)..."
flutter build apk --"$BUILD_TYPE"

# 输出结果
APK_PATH="build/app/outputs/flutter-apk/app-${BUILD_TYPE}.apk"
echo ""
if [ -f "$APK_PATH" ]; then
  echo "✅ 构建成功!"
  echo "📦 APK 路径: $PROJECT_DIR/$APK_PATH"
  echo "📊 文件大小: $(du -h "$APK_PATH" | cut -f1)"
else
  echo "❌ 构建失败，未找到 APK 文件"
  exit 1
fi
