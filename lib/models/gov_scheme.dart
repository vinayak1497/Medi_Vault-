class GovScheme {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String websiteUrl;
  final DateTime launchDate;

  GovScheme({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.websiteUrl,
    required this.launchDate,
  });

  factory GovScheme.fromJson(Map<String, dynamic> json) {
    return GovScheme(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      websiteUrl: json['websiteUrl'] as String,
      launchDate: DateTime.parse(json['launchDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'websiteUrl': websiteUrl,
      'launchDate': launchDate.toIso8601String(),
    };
  }
}
