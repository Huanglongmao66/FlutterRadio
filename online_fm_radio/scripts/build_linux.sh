#!/usr/bin/env bash
# Linux 本地构建脚本
# 用法: ./scripts/build_linux.sh [debug|release|profile]
#
# 功能:
# - 检查 Flutter 环境和 Linux 构建依赖
# - 清理并重新获取依赖
# - 生成应用图标
# - 构建 Linux 可执行文件
# - 输出构建产物路径

set -euo pipefail

BUILD_TYPE="${1:-release}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "========================================="
echo "  Linux 构建 ($BUILD_TYPE)"
echo "========================================="

# 检查操作系统
if [[ "$(uname)" != "Linux" ]]; then
  echo "❌ Linux 构建只能在 Linux 上运行"
  exit 1
fi

# 检查 Flutter
if ! command -v flutter &> /dev/null; then
  echo "❌ 未找到 flutter 命令，请确保 Flutter 已安装并添加到 PATH"
  exit 1
fi

# 检查 Linux 构建依赖
echo "🔍 检查构建依赖..."
MISSING_DEPS=""
for dep in clang cmake git ninja-build pkg-config; do
  if ! command -v "$dep" &> /dev/null; then
    MISSING_DEPS="$MISSING_DEPS $dep"
  fi
done
if [ -n "$MISSING_DEPS" ]; then
  echo "⚠ 缺少依赖:$MISSING_DEPS"
  echo "  请安装: sudo apt install$MISSING_DEPS"
  echo "  另需安装 GTK3 开发库: sudo apt install libgtk-3-dev"
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

# 启用 Linux 桌面支持
echo ""
echo "🔧 启用 Linux 桌面支持..."
flutter config --enable-linux-desktop

# 构建
echo ""
echo "🔨 构建 Linux ($BUILD_TYPE)..."
flutter build linux --"$BUILD_TYPE"

# 输出结果
APP_PATH="build/linux/x64/${BUILD_TYPE}/bundle"
echo ""
if [ -d "$APP_PATH" ]; then
  echo "✅ 构建成功!"
  echo "📦 构建目录: $PROJECT_DIR/$APP_PATH"
  echo "📊 文件大小: $(du -sh "$APP_PATH" | cut -f1)"
  echo ""
  echo "💡 运行应用: ./$APP_PATH/online_fm_radio"
else
  echo "❌ 构建失败，未找到构建产物"
  exit 1
fi
