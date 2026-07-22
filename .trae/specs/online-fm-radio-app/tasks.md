# Tasks

- [ ] Task 1: 初始化 Flutter 项目骨架
  - [ ] SubTask 1.1: 使用 `flutter create` 创建项目 `online_fm_radio`,组织目录结构(`lib/core`、`lib/data`、`lib/features`、`lib/shared`)
  - [ ] SubTask 1.2: 在 `pubspec.yaml` 中添加依赖:`just_audio`、`audio_service`、`provider`(或 `riverpod`)、`shared_preferences`、`dio`、`cached_network_image`
  - [ ] SubTask 1.3: 配置 Android `minSdkVersion` / iOS `Info.plist` 允许后台音频与网络访问

- [ ] Task 2: 准备频道数据源
  - [ ] SubTask 2.1: 在 `assets/data/stations.json` 中准备 20+ 示例频道(名称、流地址、地区、分类、图标 URL)
  - [ ] SubTask 2.2: 实现 `Station` 数据模型与 `StationRepository`(支持本地 assets 加载,接口预留远程 API 扩展)
  - [ ] SubTask 2.3: 在 `pubspec.yaml` 中声明 assets 资源

- [ ] Task 3: 状态管理与音频服务封装
  - [ ] SubTask 3.1: 实现 `PlayerService`,封装 `just_audio` + `audio_service`,提供 `play/pause/seek/stop` 与当前频道、播放状态流
  - [ ] SubTask 3.2: 实现 `FavoritesService`(基于 `shared_preferences`)和 `HistoryService`
  - [ ] SubTask 3.3: 实现 `SleepTimerService`(基于 `Timer`)

- [ ] Task 4: 频道浏览与搜索 UI
  - [ ] SubTask 4.1: 实现 `HomePage`:分类/地区筛选条 + 频道列表(ListView)
  - [ ] SubTask 4.2: 实现搜索框与实时过滤逻辑
  - [ ] SubTask 4.3: 实现 `StationCard` 组件(频道图标、名称、地区、收藏按钮)

- [ ] Task 5: 播放页与播放控制 UI
  - [ ] SubTask 5.1: 实现 `PlayerPage`:展示当前频道、播放/暂停、缓冲指示、跳转播放详情
  - [ ] SubTask 5.2: 集成 `SleepTimer` 与收藏切换按钮
  - [ ] SubTask 5.3: 错误状态处理与"重试"按钮

- [ ] Task 6: "我的"页面(收藏与历史)
  - [ ] SubTask 6.1: 实现 `FavoritesPage` 展示已收藏频道
  - [ ] SubTask 6.2: 实现 `HistorySection` 展示最近播放
  - [ ] SubTask 6.2: 底部导航整合(首页 / 我的)

- [ ] Task 7: 后台播放与媒体通知
  - [ ] SubTask 7.1: 注册 `audio_service` 后台任务,配置 Android `ForegroundService` 与 iOS 音频会话
  - [ ] SubTask 7.2: 媒体通知(标题/封面/播放暂停)在锁屏与通知栏生效

- [ ] Task 8: 应用配置与启动
  - [ ] SubTask 8.1: 实现应用主题(浅色/深色,Material 3)
  - [ ] SubTask 8.2: 在 `main.dart` 中注入 `PlayerService`、`FavoritesService`、`HistoryService`,完成启动流程

# Task Dependencies
- Task 2 依赖 Task 1
- Task 3 依赖 Task 1、Task 2
- Task 4、Task 5、Task 6 依赖 Task 3
- Task 7 依赖 Task 3
- Task 8 依赖 Task 4、Task 5、Task 6、Task 7
