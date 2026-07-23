#!/usr/bin/env bash
# Web 本地构建脚本
# 用法: ./scripts/build_web.sh [debug|release|profile]
#
# 功能:
# - 检查 Flutter 环境
# - 清理并重新获取依赖
# - 构建 Web 应用
# - 输出构建产物路径

set -euo pipefail

BUILD_TYPE="${1:-release}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "========================================="
echo "  Web 构建 ($BUILD_TYPE)"
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

# 启用 Web 支持
echo ""
echo "🔧 启用 Web 支持..."
flutter config --enable-web

# 构建
echo ""
echo "🔨 构建 Web ($BUILD_TYPE)..."
if [ "$BUILD_TYPE" = "release" ]; then
  flutter build web --release
else
  flutter build web --"$BUILD_TYPE"
fi

# 输出结果
APP_PATH="build/web"
echo ""
if [ -d "$APP_PATH" ]; then
  echo "✅ 构建成功!"
  echo "📦 构建目录: $PROJECT_DIR/$APP_PATH"
  echo "📊 文件大小: $(du -sh "$APP_PATH" | cut -f1)"
  echo ""
  echo "💡 本地预览: cd $APP_PATH && python3 -m http.server 8080"
  echo "   然后打开浏览器访问 http://localhost:8080"
else
  echo "❌ 构建失败，未找到构建产物"
  exit 1
fi
