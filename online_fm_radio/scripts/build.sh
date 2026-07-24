#!/usr/bin/env bash
# 统一构建入口脚本
# 用法: ./scripts/build.sh [平台] [构建类型]
#
# 平台: android, ios, linux, macos, windows, web, all
# 构建类型: debug, release, profile (默认 release)

set -euo pipefail

PLATFORM="${1:-android}"
BUILD_TYPE="${2:-release}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

show_usage() {
  echo "用法: $0 [平台] [构建类型]"
  echo ""
  echo "平台:"
  echo "  android   构建 Android APK"
  echo "  ios       构建 iOS App (仅 macOS)"
  echo "  linux     构建 Linux 应用 (仅 Linux)"
  echo "  macos     构建 macOS App (仅 macOS)"
  echo "  windows   构建 Windows 应用 (仅 Windows)"
  echo "  web       构建 Web 应用"
  echo "  all       构建当前系统支持的所有平台"
  echo ""
  echo "构建类型:"
  echo "  debug     调试版本"
  echo "  release   发布版本 (默认)"
  echo "  profile   性能分析版本"
  echo ""
  echo "示例:"
  echo "  $0 android release    构建 Android Release APK"
  echo "  $0 web debug          构建 Web Debug 版本"
  echo "  $0 all release        构建当前系统所有平台"
}

build_platform() {
  local platform=$1
  local script="$SCRIPT_DIR/build_${platform}.sh"

  if [ ! -f "$script" ]; then
    echo "❌ 未知平台: $platform"
    show_usage
    exit 1
  fi

  echo ""
  echo "========================================="
  echo "  开始构建: $platform ($BUILD_TYPE)"
  echo "========================================="

  bash "$script" "$BUILD_TYPE"
}

case "$PLATFORM" in
  android|ios|linux|macos|windows|web)
    build_platform "$PLATFORM"
    ;;
  all)
    OS_TYPE="$(uname)"
    case "$OS_TYPE" in
      Darwin)
        build_platform android
        build_platform ios
        build_platform macos
        build_platform web
        ;;
      Linux)
        build_platform android
        build_platform linux
        build_platform web
        ;;
      MINGW*|MSYS*|CYGWIN*)
        build_platform android
        build_platform windows
        build_platform web
        ;;
      *)
        echo "⚠ 未知操作系统: $OS_TYPE"
        echo "仅构建通用平台..."
        build_platform android
        build_platform web
        ;;
    esac
    ;;
  -h|--help|help)
    show_usage
    ;;
  *)
    echo "❌ 未知平台: $PLATFORM"
    show_usage
    exit 1
    ;;
esac

echo ""
echo "========================================="
echo "  构建完成!"
echo "========================================="
