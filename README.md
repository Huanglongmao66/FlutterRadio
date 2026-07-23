# FMradio - 在线 FM 广播收音机

一款使用 Flutter 开发的跨平台在线 FM 广播收听应用，支持 Android 与 iOS。用户无需 FM 硬件即可随时随地收听全球各类电台，并享受收藏、分类浏览、后台播放、定时关闭、导入导出等现代流媒体体验。

## 功能特性

### 核心播放
- **全球电台收听** — 接入 Radio-Browser API，支持 10000+ 电台在线收听
- **后台保活播放** — 前台服务保活，切到后台继续播放，通知栏/锁屏可控
- **线控/蓝牙控制** — 支持有线耳机按键、蓝牙耳机媒体控制（播放/暂停/上一曲/下一曲）
- **锁屏控制** — 锁屏界面显示电台名称、封面、播放控制按钮
- **断点续传更新** — 电台列表更新时如果中断，下次从断点位置继续
- **屏幕常亮** — 更新电台列表时自动保持屏幕常亮，防止锁屏中断

### 浏览与发现
- **推荐页面** — 根据所选国家推荐热门电台
- **国家/地区筛选** — 按国家浏览电台，支持搜索
- **语言分类** — 按语言浏览电台，支持中英文双语显示
- **标签分类** — 按标签浏览电台（Pop、Rock、Jazz 等）
- **搜索功能** — 实时搜索电台名称、国家、语言、标签
- **本地电台** — 查看已缓存的本地电台列表

### 收藏与历史
- **收藏电台** — 点击心形图标收藏，最多支持 50 个
- **播放历史** — 自动记录最近播放的 10 个电台
- **最近播放** — 快速回到上次收听的电台

### 导入导出
- **M3U 格式** — 导入/导出标准 M3U 播放列表
- **M3U8 格式** — 导入/导出扩展 M3U8 格式（含分组信息）
- **JSON 格式** — 导入/导出 JSON 格式电台列表

### 其他功能
- **定时关闭** — 15/30/60 分钟或自定义时长，到点自动停止播放
- **音乐可视化** — 播放时显示音乐频谱动画效果
- **主题切换** — 浅色/深色/跟随系统
- **国家偏好** — 设置首选国家，推荐页自动展示对应国家电台
- **睡眠定时器** — 支持自定义倒计时

## 技术栈

| 类别 | 技术 | 说明 |
|------|------|------|
| 框架 | Flutter 3.x + Dart 3.x | 跨平台，目标 Android / iOS / Web / Desktop |
| 音频播放 | just_audio | HTTP / HLS / ICY 流，缓冲、错误恢复 |
| 后台播放 | audio_service | Android Foreground Service + iOS Media Session |
| 状态管理 | provider | 全局 PlayerService / FavoritesService / HistoryService |
| 本地存储 | shared_preferences | 收藏、播放历史、设置项 |
| 网络 | dio | 请求封装、重试、超时 |
| 图片缓存 | cached_network_image | 电台封面缓存 |
| 文件选择 | file_picker | 导入导出文件选择 |
| 屏幕常亮 | wakelock_plus | 更新时防止锁屏 |
| 权限管理 | permission_handler | 通知权限、电池优化白名单 |
| UI 规范 | Material 3 | 浅色/深色主题，响应式布局 |

## 快速开始

### 环境要求

- Flutter >= 3.22.0
- Dart >= 3.4.0
- Android Studio / Xcode
- Android SDK 33+（构建 Android）
- Xcode 15+（构建 iOS，仅 macOS）

### 安装与运行

```bash
# 1. 克隆仓库
git clone https://github.com/Huanglongmao66/FlutterRadio.git
cd FlutterRadio/online_fm_radio

# 2. 获取依赖
flutter pub get

# 3. 生成应用图标
dart run flutter_launcher_icons

# 4. 运行（Debug 模式）
flutter run

# 5. 构建 Release APK
flutter build apk --release
```

### 构建脚本

项目内置各平台构建脚本，位于 `scripts/` 目录：

```bash
# 构建指定平台（默认 release）
./scripts/build.sh android          # 构建 Android APK
./scripts/build.sh ios              # 构建 iOS App（需 macOS）
./scripts/build.sh web              # 构建 Web 应用
./scripts/build.sh linux            # 构建 Linux 应用（需 Linux）
./scripts/build.sh macos           # 构建 macOS App（需 macOS）
./scripts/build.sh windows         # 构建 Windows 应用

# 指定构建类型
./scripts/build.sh android debug    # Debug 版本
./scripts/build.sh android profile  # Profile 版本

# 构建当前系统支持的所有平台
./scripts/build.sh all

# Windows CMD 用户
scripts\build_windows.bat release
```

每个脚本功能：环境检查 → 清理 → 获取依赖 → 生成图标 → 构建 → 输出产物路径。

## 详细使用说明

### 首次使用

1. **安装应用** — 安装后打开应用，应用会自动从 API 加载电台数据
2. **更新电台列表** — 进入「我的」页面，点击「更新电台列表」，应用会批量拉取 10000+ 电台数据到本地
   - 更新过程中屏幕保持常亮
   - 如果网络中断，下次更新会从断点位置继续
3. **授权后台播放** — 首次播放时应用会请求通知权限和电池优化白名单
   - 小米/华为等手机还需在系统设置中开启「自启动」

### 播放电台

1. **浏览电台** — 在首页推荐页浏览热门电台，或通过底部导航切换到「探索」页面
2. **筛选电台** — 在探索页面点击「国家」「语言」「标签」标签查看对应分类
3. **搜索电台** — 点击搜索图标，输入电台名称、国家、语言关键字实时搜索
4. **播放电台** — 点击任意电台卡片进入播放页，自动开始缓冲播放
5. **播放控制** — 播放页可暂停/继续、调节音量、查看缓冲状态

### 后台播放

1. **切到后台** — 播放中按 Home 键或切换其他应用，音频继续播放
2. **通知栏控制** — 下拉通知栏可看到播放控制卡片，支持播放/暂停/停止
3. **锁屏控制** — 锁屏界面显示电台名称和封面，支持播放/暂停/上一曲/下一曲
4. **线控/蓝牙** — 有线耳机按键和蓝牙耳机媒体键均可控制播放

### 收藏与历史

1. **收藏电台** — 在电台卡片或播放页点击心形图标收藏
2. **查看收藏** — 进入「我的」页面查看已收藏电台列表
3. **播放历史** — 「我的」页面底部显示最近播放的 10 个电台

### 导入导出

1. **导出电台** — 进入「设置」→「数据管理」→「导出电台列表」
   - 选择格式：M3U / M3U8 / JSON
   - 选择保存位置
2. **导入电台** — 进入「设置」→「数据管理」→「导入电台列表」
   - 选择 m3u / m3u8 / json 文件
   - 导入的电台自动添加到收藏列表（自动去重）

### 定时关闭

1. **设置定时** — 在播放页点击「定时关闭」按钮
2. **选择时长** — 15 / 30 / 60 分钟或自定义时长
3. **取消定时** — 倒计时期间再次点击「定时关闭」可取消

### 后台保活设置

进入「设置」→「后台保活」：

1. **通知权限** — 确保通知权限已开启，通知栏播放控制卡片才能显示
2. **关闭电池优化** — 请求加入电池优化白名单，防止系统后台断网

**小米/红米手机额外设置（MIUI/HyperOS）：**
1. 设置 → 应用管理 → FMradio → 自启动 → 开启
2. 设置 → 应用管理 → FMradio → 省电策略 → 无限制
3. 最近任务列表中下拉锁定应用，防止被一键清理

## 项目结构

```
online_fm_radio/
├── lib/
│   ├── core/
│   │   ├── constants/       # 应用常量配置
│   │   ├── services/        # 核心服务（播放、音频、收藏、历史等）
│   │   ├── theme/           # Material 3 主题
│   │   ├── ui/              # 主框架组件（导航、侧边栏）
│   │   └── utils/           # 工具类（电池优化等）
│   ├── data/
│   │   ├── datasources/     # 本地/远程数据源
│   │   ├── models/          # 数据模型（Station、Country、Tag 等）
│   │   └── repositories/    # 数据仓库
│   ├── features/
│   │   ├── home/            # 首页（推荐电台）
│   │   ├── explore/         # 探索（国家/语言/标签）
│   │   ├── player/          # 播放页
│   │   ├── favorites/       # 收藏列表
│   │   ├── search/          # 搜索页
│   │   ├── settings/        # 设置页
│   │   ├── profile/         # 我的页面
│   │   ├── countries/      # 国家列表/详情
│   │   ├── languages/      # 语言列表/详情
│   │   ├── tags/           # 标签列表/详情
│   │   └── stations/       # 本地电台列表
│   └── shared/
│       └── components/      # 公共组件（电台卡片、播放控制、可视化器等）
├── assets/
│   ├── data/                # 示例数据
│   └── icons/              # 应用图标
├── scripts/                # 各平台构建脚本
├── android/                # Android 原生配置
├── ios/                    # iOS 原生配置
├── pubspec.yaml            # 依赖配置
└── ...
```

## API 数据源

应用使用 [Radio-Browser.info](https://www.radio-browser.info/) 公共 API：

- **基础地址**：`http://de1.api.radio-browser.info/json`
- **无需 API Key** — 完全免费开放
- **支持接口**：电台列表、国家列表、语言列表、标签列表、搜索

## 开发进度

| 阶段 | 进度 | 说明 |
|------|------|------|
| M1 基础工程搭建 | 100% | Flutter 项目骨架、数据源 |
| M2 核心服务 | 100% | 状态管理、音频服务封装、缓存服务 |
| M3 UI 完整 | 100% | 首页、探索、播放页、我的、设置 |
| M4 后台播放 | 100% | 前台服务、锁屏控制、线控/蓝牙 |
| M5 插件系统 | 100% | M3U/M3U8/JSON 导入导出 |
| M6 后台保活 | 100% | 电池优化白名单、MIUI 适配 |
| M7 构建脚本 | 100% | 各平台本地构建脚本 |

## License

MIT License
