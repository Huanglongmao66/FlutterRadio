/// 国家数据模型类
///
/// 用于表示国家信息，包含国家名称、代码和电台数量。
/// 支持从 radio-browser.info API 返回的 JSON 格式解析。
class Country {
  /// 国家名称（英文）
  final String name;

  /// ISO 3166-1 alpha-2 国家代码（如 CN、US、GB）
  /// 用于生成国旗 emoji
  final String countryCode;

  /// 该国家的电台数量
  final int stationCount;

  /// 创建国家对象
  ///
  /// [name] - 国家名称，必填
  /// [countryCode] - 国家代码，必填
  /// [stationCount] - 电台数量，必填
  const Country({
    required this.name,
    required this.countryCode,
    required this.stationCount,
  });

  /// 从 radio-browser.info API 返回的 JSON 格式解析国家对象
  ///
  /// API 返回的字段说明：
  /// - name: 国家名称
  /// - iso_3166_1: ISO 3166-1 alpha-2 国家代码
  /// - stationcount: 电台数量
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'] as String? ?? 'Unknown',
      countryCode: json['iso_3166_1'] as String? ?? '',
      stationCount: json['stationcount'] as int? ?? 0,
    );
  }

  /// 根据 ISO 3166-1 alpha-2 国家代码生成国旗 emoji
  ///
  /// 使用 Unicode 区域指示符编码规则：
  /// - 基础码点为 0x1F1E6（区域指示符字母 A）
  /// - 每个字母偏移为字母 ASCII 码减去 0x41（字母 A）
  /// - 组合两个字母的区域指示符得到国旗 emoji
  ///
  /// 如果 countryCode 不是两位字符或在当前平台无法渲染，返回空字符串
  String get flagEmoji {
    if (countryCode.length != 2) return '';
    final upper = countryCode.toUpperCase();
    final base = 0x1F1E6;
    final first = base + (upper.codeUnitAt(0) - 0x41);
    final second = base + (upper.codeUnitAt(1) - 0x41);
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}