# 在线 FM 广播 APP (FlutterRadio)

一款使用 Flutter 开发的跨平台在线 FM 广播收听应用,支持 Android 与 iOS。用户无需 FM 硬件即可随时随地收听全球各类电台,并享受收藏、分类浏览、后台播放、定时关闭等现代流媒体体验。

## 项目说明

本项目使用 **Flutter 3.x / Dart 3.x** 开发,内置示例频道数据,无需后端即可离线演示完整功能,后续可平滑切换到远程 API。

## 技术要点

- **跨平台框架**:Flutter 3.x + Dart 3.x,目标平台 Android / iOS
- **音频播放**:`just_audio` 处理 HTTP / HLS / ICY 流,支持缓冲、错误恢复与码率自适应
- **后台播放与媒体会话**:`audio_service` 实现 Android Foreground Service 与 iOS `MPNowPlayingInfoCenter` / `MPRemoteCommandCenter`,锁屏与通知栏可控
- **状态管理**:`provider` 管理全局 `PlayerService` / `FavoritesService` / `HistoryService` / `SleepTimerService`
- **本地持久化**:`shared_preferences` 存储收藏与最近播放
- **网络**:`dio` 封装请求,内置重试与超时;`cached_network_image` 缓存频道封面
- **UI 规范**:Material 3,支持浅色/深色主题,响应式布局适配手机/平板
- **工程化**:`flutter_lints` 静态检查、`flutter analyze`、`flutter test` 单元/Widget 测试

## 使用说明

- **首页**:进入 APP 默认显示"全部"分类下的频道列表,可点击顶部筛选条切换分类(流行/新闻/古典/谈话)或地区,搜索框输入关键字实时过滤
- **播放**:点击任一频道卡片进入播放页,自动开始缓冲播放;播放页可暂停/继续、查看缓冲状态、收藏或启动 Sleep Timer
- **收藏**:在频道卡片或播放页点击心形图标即可收藏;在底部导航"我的"中查看已收藏频道
- **最近播放**:"我的"页底部展示最近播放过的 10 个频道,便于快速回到上次听的电台
- **后台播放**:播放过程中按 Home 键或切换其他 APP,音频继续播放;系统通知/锁屏卡片显示频道名与播放暂停按钮
- **定时关闭**:在播放页点击"定时关闭"选择 15 / 30 / 60 分钟或自定义时长,到达时间自动停止;倒计时未结束可点击取消
- **错误处理**:网络异常时播放页显示错误提示,点击"重试"重新加载流

## 开发进度

| 阶段 | 进度 | 说明 |
|---|---|---|
| M1 基础工程搭建 | 100% | Task 1: 初始化 Flutter 项目骨架; Task 2: 准备频道数据源 |
| M2 核心服务 | 100% | Task 3: 状态管理与音频服务封装 |
| M3 UI 完整 | 100% | Task 4: 频道浏览与搜索; Task 5: 播放页; Task 6: "我的"页面 |
| M4 后台播放与发布 | 100% | Task 7: 后台播放与媒体通知; Task 8: 应用配置与启动 |

## 开发环境

- Flutter >= 3.22.0
- Dart >= 3.4.0
- Android Studio / Xcode

## 快速开始

```bash
cd online_fm_radio
flutter pub get
flutter run
```

## 项目结构

```
online_fm_radio/
├── lib/
│   ├── core/           # 常量、主题、路由、工具类
│   ├── data/           # 数据模型、仓库、本地/远程数据源
│   ├── features/       # 功能模块:首页、播放页、我的页面
│   └── shared/         # 公共组件、通用 Widget
├── assets/
│   └── data/
│       └── stations.json   # 示例频道数据
├── pubspec.yaml
└── ...
```
