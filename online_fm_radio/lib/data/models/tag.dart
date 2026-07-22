class Tag {
  final String name;
  final int stationCount;

  const Tag({
    required this.name,
    required this.stationCount,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'] as String? ?? 'Unknown',
      stationCount: json['stationcount'] as int? ?? 0,
    );
  }
}
