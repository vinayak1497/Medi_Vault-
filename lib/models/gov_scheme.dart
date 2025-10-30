class GovScheme {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String websiteUrl;
  final DateTime launchDate;
  final String eligibility;
  final String benefits;
  final String coverage;

  GovScheme({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.websiteUrl,
    required this.launchDate,
    this.eligibility = '',
    this.benefits = '',
    this.coverage = '',
  });

  factory GovScheme.fromJson(Map<String, dynamic> json) {
    return GovScheme(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      websiteUrl: json['websiteUrl'] as String,
      launchDate:
          json['launchDate'] != null
              ? DateTime.parse(json['launchDate'] as String)
              : DateTime.now(),
      eligibility: json['eligibility'] as String? ?? '',
      benefits: json['benefits'] as String? ?? '',
      coverage: json['coverage'] as String? ?? '',
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
      'eligibility': eligibility,
      'benefits': benefits,
      'coverage': coverage,
    };
  }
}
