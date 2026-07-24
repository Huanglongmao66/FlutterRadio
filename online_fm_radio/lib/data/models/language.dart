/// 语言数据模型类
///
/// 用于表示语言信息，包含语言名称和使用该语言的电台数量。
/// 支持从 radio-browser.info API 返回的 JSON 格式解析。
class Language {
  /// 语言名称（英文）
  final String name;

  /// 使用该语言的电台数量
  final int stationCount;

  /// 创建语言对象
  ///
  /// [name] - 语言名称，必填
  /// [stationCount] - 电台数量，必填
  const Language({
    required this.name,
    required this.stationCount,
  });

  /// 从 radio-browser.info API 返回的 JSON 格式解析语言对象
  ///
  /// API 返回的字段说明：
  /// - name: 语言名称
  /// - stationcount: 使用该语言的电台数量
  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      name: json['name'] as String? ?? '',
      stationCount: json['stationcount'] as int? ?? 0,
    );
  }
}