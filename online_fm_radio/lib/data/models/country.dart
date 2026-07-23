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

  /// Converts the ISO 3166-1 alpha-2 country code into a flag emoji
  /// using regional indicator symbols. Returns an empty string when the
  /// code is missing or invalid (e.g. on Windows the emoji may not render).
  String get flagEmoji {
    if (countryCode.length != 2) return '';
    final upper = countryCode.toUpperCase();
    final base = 0x1F1E6; // regional indicator A
    final first = base + (upper.codeUnitAt(0) - 0x41);
    final second = base + (upper.codeUnitAt(1) - 0x41);
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}
