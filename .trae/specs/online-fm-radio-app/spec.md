# 在线 FM 广播 APP Spec

## Why
为用户提供一个使用 Flutter 开发的、可在移动端流畅收听全球在线 FM 广播频道的应用,解决传统 FM 受地域限制、信号差、无法随时收听的问题,同时提供收藏、分类浏览和后台播放等现代流媒体体验。

## What Changes
- 新增 Flutter 项目骨架(支持 Android / iOS)
- 实现 FM 频道列表展示(国家/地区、分类、关键字搜索)
- 实现频道详情与播放控制(播放/暂停、缓冲进度、音量)
- 集成后台音频播放与锁屏控制(通知栏 + 媒体会话)
- 实现收藏(本地持久化)与最近播放历史
- 实现定时关闭(Sleep Timer)
- 内置示例频道数据源(可后续替换为远程 API)

## Impact
- Affected specs: 无(全新项目)
- Affected code: 新建 Flutter 项目 `online_fm_radio/` 下全部源码
- 主要技术栈: Flutter 3.x、Dart 3.x、`just_audio` + `audio_service`(音频/后台)、`provider` 或 `riverpod`(状态管理)、`shared_preferences`(本地持久化)、`dio`(网络请求)

## ADDED Requirements

### Requirement: 频道浏览
系统 SHALL 提供 FM 频道列表的浏览能力,支持按地区(国家/地区)、分类(流行/新闻/古典/谈话等)筛选,并在主页以分页/无限滚动方式呈现。

#### Scenario: 用户进入首页
- **WHEN** 用户打开 APP
- **THEN** 展示默认"全部"分类下的频道列表,并按热度或字母排序

#### Scenario: 用户切换分类或地区
- **WHEN** 用户在筛选面板选择新分类或地区
- **THEN** 频道列表立即刷新为匹配项

#### Scenario: 搜索频道
- **WHEN** 用户在搜索框输入关键字
- **THEN** 列表实时过滤为名称或标签包含关键字的频道

### Requirement: 频道播放
系统 SHALL 接收用户对频道的播放指令,通过 HTTP/HLS/ICY 流播放对应音频流,并在播放页展示当前频道信息、缓冲状态、播放/暂停按钮。

#### Scenario: 用户点击频道并播放
- **WHEN** 用户在列表中点击某频道
- **THEN** 进入播放页,自动开始缓冲并播放,显示缓冲进度

#### Scenario: 用户暂停/继续
- **WHEN** 用户点击播放/暂停按钮
- **THEN** 音频在暂停和继续之间切换,UI 状态同步更新

#### Scenario: 网络异常
- **WHEN** 流地址无法连接或超时
- **THEN** 显示友好错误提示并提供"重试"按钮

### Requirement: 后台播放与媒体控制
系统 SHALL 在音频播放期间支持应用切到后台继续播放,并通过系统媒体通知(锁屏 / 通知栏)展示频道名并支持播放/暂停控制。

#### Scenario: 用户切到后台
- **WHEN** 用户按 Home 键或切换到其他 APP
- **THEN** 音频继续播放,系统通知出现媒体控制卡片

#### Scenario: 用户在通知栏暂停
- **WHEN** 用户在通知栏点击暂停
- **THEN** 音频立即暂停,UI 与通知状态同步

### Requirement: 收藏与历史
系统 SHALL 允许用户收藏喜欢的频道并记录最近播放,数据使用本地持久化存储,关闭 APP 后再次打开仍可恢复。

#### Scenario: 用户收藏频道
- **WHEN** 用户点击"收藏"图标
- **THEN** 频道被加入收藏列表,图标变为已收藏状态

#### Scenario: 用户进入收藏页
- **WHEN** 用户在底部导航进入"我的"页面
- **THEN** 显示已收藏频道列表和最近播放列表

### Requirement: 定时关闭
系统 SHALL 提供 Sleep Timer 功能,用户可设置 15/30/60 分钟或自定义时长,到达时间后自动停止播放。

#### Scenario: 用户启动 Sleep Timer
- **WHEN** 用户在播放页选择"定时关闭"并选择 30 分钟
- **THEN** 播放页显示倒计时,30 分钟后音频自动停止

#### Scenario: 用户取消 Sleep Timer
- **WHEN** 用户在倒计时未结束前点击"取消"
- **THEN** 定时器被清除,音频继续播放

### Requirement: 数据源
系统 SHALL 启动时加载内置示例频道数据(JSON 资源),每个频道包含名称、流地址、地区、分类、图标字段,保证应用无需后端即可演示完整功能。

#### Scenario: 首次启动
- **WHEN** 用户首次打开 APP 且无网络或未配置远程 API
- **THEN** 使用打包在 assets 中的示例频道 JSON 渲染列表
