class Language {
  final String name;
  final int stationCount;

  const Language({
    required this.name,
    required this.stationCount,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      name: json['name'] as String? ?? '',
      stationCount: json['stationcount'] as int? ?? 0,
    );
  }
}