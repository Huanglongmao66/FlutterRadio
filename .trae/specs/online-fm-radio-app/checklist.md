# Checklist

- [ ] Flutter 项目创建成功,目录结构符合 `lib/core` `lib/data` `lib/features` `lib/shared`
- [ ] `pubspec.yaml` 包含 `just_audio` / `audio_service` / `provider`(或 `riverpod`) / `shared_preferences` / `dio` / `cached_network_image`
- [ ] Android `minSdkVersion` 与 iOS `Info.plist` 已开启后台音频与网络权限
- [ ] `assets/data/stations.json` 至少包含 20 条示例频道且可通过 `StationRepository` 加载
- [ ] `PlayerService` 能够播放、暂停、恢复、停止音频,并暴露播放状态流
- [ ] `FavoritesService` 收藏数据在重启 APP 后仍可恢复
- [ ] `HistoryService` 记录最近播放的频道
- [ ] `SleepTimerService` 可在指定时间后自动停止播放,并支持取消
- [ ] 首页支持分类/地区筛选与关键字搜索,过滤结果实时刷新
- [ ] 点击频道进入播放页后可正常播放音频,缓冲状态可见
- [ ] 播放/暂停切换在 UI 与系统通知中保持一致
- [ ] 切到后台后音频继续播放,通知栏出现媒体控制卡片
- [ ] 锁屏/通知栏上的播放暂停按钮可控制音频
- [ ] 网络异常时显示错误提示并提供"重试"按钮
- [ ] "我的"页面显示已收藏频道与最近播放列表
- [ ] 应用支持浅色/深色主题(Material 3)
- [ ] `flutter analyze` 与 `flutter build` 通过(Android / iOS 至少其中之一)
