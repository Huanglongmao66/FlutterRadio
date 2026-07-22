class Station {
  final String id;
  final String name;
  final String streamUrl;
  final String country;
  final String category;
  final String logo;
  final String description;

  const Station({
    required this.id,
    required this.name,
    required this.streamUrl,
    required this.country,
    required this.category,
    required this.logo,
    required this.description,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      streamUrl: json['streamUrl'] as String,
      country: json['country'] as String,
      category: json['category'] as String,
      logo: json['logo'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'streamUrl': streamUrl,
      'country': country,
      'category': category,
      'logo': logo,
      'description': description,
    };
  }
}