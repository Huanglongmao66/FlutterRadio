class Station {
  final String id;
  final String name;
  final String streamUrl;
  final String country;
  final String countryCode;
  final String language;
  final String category;
  final String logo;
  final String description;
  final int votes;
  final int bitrate;
  final String codec;

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
    );
  }

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
    };
  }

  /// 根据 countryCode (ISO 3166-1 alpha-2) 生成国旗 emoji。
  /// 没有 countryCode 时返回空字符串。
  String get flagEmoji {
    if (countryCode.length != 2) return '';
    final upper = countryCode.toUpperCase();
    final base = 0x1F1E6;
    final first = base + (upper.codeUnitAt(0) - 0x41);
    final second = base + (upper.codeUnitAt(1) - 0x41);
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}