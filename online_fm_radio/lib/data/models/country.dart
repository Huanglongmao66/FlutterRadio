class Country {
  final String name;
  final String countryCode;
  final int stationCount;

  const Country({
    required this.name,
    required this.countryCode,
    required this.stationCount,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'] as String? ?? 'Unknown',
      countryCode: json['iso_3166_1'] as String? ?? '',
      stationCount: json['stationcount'] as int? ?? 0,
    );
  }
}
