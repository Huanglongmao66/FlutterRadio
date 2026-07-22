class Station {
  final String id;
  final String name;
  final String streamUrl;
  final String country;
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
      'language': language,
      'category': category,
      'logo': logo,
      'description': description,
    };
  }
}