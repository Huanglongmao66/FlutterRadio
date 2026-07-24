/// 标签数据模型类
///
/// 用于表示电台分类标签信息，包含标签名称和使用该标签的电台数量。
/// 支持从 radio-browser.info API 返回的 JSON 格式解析。
class Tag {
  /// 标签名称
  final String name;

  /// 使用该标签的电台数量
  final int stationCount;

  /// 创建标签对象
  ///
  /// [name] - 标签名称，必填
  /// [stationCount] - 电台数量，必填
  const Tag({
    required this.name,
    required this.stationCount,
  });

  /// 从 radio-browser.info API 返回的 JSON 格式解析标签对象
  ///
  /// API 返回的字段说明：
  /// - name: 标签名称
  /// - stationcount: 使用该标签的电台数量
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'] as String? ?? 'Unknown',
      stationCount: json['stationcount'] as int? ?? 0,
    );
  }
}