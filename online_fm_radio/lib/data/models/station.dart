/// 电台数据模型类
///
/// 用于表示一个广播电台的完整信息，包括基本属性、元数据和辅助方法。
/// 支持从 radio-browser.info API 响应和本地 JSON 缓存两种格式解析。
class Station {
  /// 电台唯一标识符
  /// - 来自 API 时使用 stationuuid
  /// - 本地缓存时使用自定义 ID
  final String id;

  /// 电台名称
  final String name;

  /// 流媒体播放地址
  final String streamUrl;

  /// 国家名称（英文）
  final String country;

  /// ISO 3166-1 alpha-2 国家代码（如 CN、US、GB）
  /// 用于生成国旗 emoji
  final String countryCode;

  /// 语言名称（英文，可能包含多个语言用逗号分隔）
  final String language;

  /// 电台分类标签（如 pop、news、jazz）
  final String category;

  /// 电台 Logo 图片 URL
  final String logo;

  /// 电台描述/标签（多个标签用逗号分隔）
  final String description;

  /// 用户投票数
  final int votes;

  /// 比特率（kbps）
  final int bitrate;

  /// 音频编码格式（如 MP3、AAC）
  final String codec;

  /// 创建电台对象
  ///
  /// [id] - 唯一标识符，必填
  /// [name] - 电台名称，必填
  /// [streamUrl] - 流媒体地址，必填
  /// [country] - 国家名称，必填
  /// [countryCode] - 国家代码，默认空字符串
  /// [language] - 语言名称，默认空字符串
  /// [category] - 分类标签，必填
  /// [logo] - Logo URL，必填
  /// [description] - 描述信息，必填
  /// [votes] - 投票数，默认 0
  /// [bitrate] - 比特率，默认 0
  /// [codec] - 编码格式，默认空字符串
  const Station({
    required this.id,
    required this.name,
    required this.streamUrl,
    required this.country,
    this.countryCode = '',
    this.language = '',
    required this.category,
    required this.logo,
    required this.description,
    this.votes = 0,
    this.bitrate = 0,
    this.codec = '',
  });

  /// 从 radio-browser.info API 返回的 JSON 格式解析电台对象
  ///
  /// API 返回的字段与本地缓存格式不同，需要特殊处理：
  /// - 标签存储在 tags 字段中，第一个标签作为 category
  /// - 唯一 ID 字段为 stationuuid
  /// - 播放地址优先使用 url_resolved，回退到 url
  /// - 图标字段为 favicon
  factory Station.fromRadioBrowserJson(Map<String, dynamic> json) {
    final tags = (json['tags'] as String?)?.split(',') ?? [];
    final category = tags.isNotEmpty ? tags.first.trim() : 'Other';

    return Station(
      id: json['stationuuid'] as String? ?? '',
      name: (json['name'] as String?)?.trim() ?? 'Unknown',
      streamUrl: json['url_resolved'] as String? ?? json['url'] as String? ?? '',
      country: json['country'] as String? ?? 'Unknown',
      countryCode: json['countrycode'] as String? ?? '',
      language: (json['language'] as String?)?.trim() ?? '',
      category: category,
      logo: json['favicon'] as String? ?? '',
      description: tags.join(', '),
      votes: json['votes'] as int? ?? 0,
      bitrate: json['bitrate'] as int? ?? 0,
      codec: json['codec'] as String? ?? '',
    );
  }

  /// 从本地缓存的 JSON 格式解析电台对象
  ///
  /// 本地缓存使用标准字段命名方式，与 [toJson] 方法对应
  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      streamUrl: json['streamUrl'] as String? ?? '',
      country: json['country'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      language: json['language'] as String? ?? '',
      category: json['category'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      description: json['description'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
      bitrate: json['bitrate'] as int? ?? 0,
      codec: json['codec'] as String? ?? '',
    );
  }

  /// 将电台对象转换为 JSON 格式，用于本地缓存存储
  ///
  /// 返回的 Map 包含所有字段，与 [fromJson] 方法对应
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'streamUrl': streamUrl,
      'country': country,
      'countryCode': countryCode,
      'language': language,
      'category': category,
      'logo': logo,
      'description': description,
      'votes': votes,
      'bitrate': bitrate,
      'codec': codec,
    };
  }

  /// 将 HTTP logo URL 升级为 HTTPS，避免 Web 端混合内容限制
  ///
  /// Web 浏览器在 HTTPS 页面上会阻止 HTTP 图片加载，
  /// 此方法自动将 HTTP URL 转换为 HTTPS，
  /// 已经是 HTTPS 的 URL 保持不变，空 URL 返回空字符串
  String get safeLogo {
    if (logo.isEmpty) return '';
    if (logo.startsWith('https://')) return logo;
    if (logo.startsWith('http://')) return 'https://${logo.substring(7)}';
    return logo;
  }

  /// 基于 streamUrl / logo 域名生成的 Google Favicon 备用 URL
  ///
  /// 当原始 logo 加载失败时作为回退方案，
  /// 使用 Google Favicon API 获取网站图标
  String get faviconFallback {
    String? domain;
    final src = streamUrl.isNotEmpty ? streamUrl : logo;
    final uri = Uri.tryParse(src);
    if (uri != null && uri.host.isNotEmpty) {
      domain = uri.host;
    }
    if (domain == null || domain.isEmpty) return '';
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
  }

  /// 根据 countryCode (ISO 3166-1 alpha-2) 生成国旗 emoji
  ///
  /// 使用 Unicode 区域指示符编码规则：
  /// - 基础码点为 0x1F1E6（区域指示符字母 A）
  /// - 每个字母偏移为字母 ASCII 码减去 0x41（字母 A）
  /// - 组合两个字母的区域指示符得到国旗 emoji
  ///
  /// 如果 countryCode 不是两位字符，返回空字符串
  String get flagEmoji {
    if (countryCode.length != 2) return '';
    final upper = countryCode.toUpperCase();
    final base = 0x1F1E6;
    final first = base + (upper.codeUnitAt(0) - 0x41);
    final second = base + (upper.codeUnitAt(1) - 0x41);
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}