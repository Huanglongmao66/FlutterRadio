/// 电台统计数据模型
///
/// 对应 radio-browser.info /json/stats API 返回的数据，
/// 包含平台整体的电台、点击、国家等统计信息。
class RadioStats {
  /// 支持的电台总数
  final int stations;

  /// 总点击量
  final int clicks;

  /// 支持的国家总数
  final int countries;

  /// 总语言数
  final int languages;

  /// 总标签数
  final int tags;

  /// 最近一小时点击数
  final int clicksLastHour;

  /// 最近24小时内检查过的电台数
  final int stationsBroken;

  RadioStats({
    required this.stations,
    required this.clicks,
    required this.countries,
    required this.languages,
    required this.tags,
    required this.clicksLastHour,
    required this.stationsBroken,
  });

  factory RadioStats.fromJson(Map<String, dynamic> json) {
    return RadioStats(
      stations: json['stations'] as int? ?? 0,
      clicks: json['clicks'] as int? ?? 0,
      countries: json['countries'] as int? ?? 0,
      languages: json['languages'] as int? ?? 0,
      tags: json['tags'] as int? ?? 0,
      clicksLastHour: json['clicks_last_hour'] as int? ?? 0,
      stationsBroken: json['stationsbroken'] as int? ?? 0,
    );
  }
}
