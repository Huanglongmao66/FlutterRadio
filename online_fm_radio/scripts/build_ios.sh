#!/usr/bin/env bash
# iOS 本地构建脚本
# 用法: ./scripts/build_ios.sh [debug|release|profile]
#
# 功能:
# - 检查 Flutter 和 Xcode 环境
# - 清理并重新获取依赖
# - 生成应用图标
# - 构建 iOS App
# - 输出构建产物路径
#
# 注意: 仅限 macOS 系统使用

set -euo pipefail

BUILD_TYPE="${1:-release}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "========================================="
echo "  iOS 构建 ($BUILD_TYPE)"
echo "========================================="

# 检查操作系统
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ iOS 构建只能在 macOS 上运行"
  exit 1
fi

# 检查 Flutter
if ! command -v flutter &> /dev/null; then
  echo "❌ 未找到 flutter 命令，请确保 Flutter 已安装并添加到 PATH"
  exit 1
fi

# 检查 Xcode
if ! command -v xcodebuild &> /dev/null; then
  echo "❌ 未找到 xcodebuild，请安装 Xcode"
  exit 1
fi

echo "Flutter 版本:"
flutter --version

echo ""
echo "Xcode 版本:"
xcodebuild -version

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
echo "🔨 构建 iOS ($BUILD_TYPE)..."
flutter build ios --"$BUILD_TYPE" --no-codesign

# 输出结果
APP_PATH="build/ios/iphoneos/Runner.app"
echo ""
if [ -d "$APP_PATH" ]; then
  echo "✅ 构建成功!"
  echo "📦 App 路径: $PROJECT_DIR/$APP_PATH"
  echo "📊 文件大小: $(du -sh "$APP_PATH" | cut -f1)"
  echo ""
  echo "💡 如需打包 IPA，请使用 Xcode Organizer 或:"
  echo "   flutter build ipa --$BUILD_TYPE"
else
  echo "❌ 构建失败，未找到 Runner.app"
  exit 1
fi
