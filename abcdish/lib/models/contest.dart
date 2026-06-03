class Contest {
  const Contest({
    required this.id,
    required this.title,
    required this.description,
    required this.prizeDescription,
    required this.status,
    required this.imageUrl,
    required this.endsAt,
  });

  final String id;
  final String title;
  final String description;
  final String prizeDescription;
  final String status;
  final String imageUrl;
  final DateTime? endsAt;

  factory Contest.fromJson(Map<String, dynamic> json) {
    return Contest(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      prizeDescription:
          json['prizeDescription']?.toString() ??
          json['prize']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'OPEN',
      imageUrl: json['imageUrl']?.toString() ?? '',
      endsAt: DateTime.tryParse(json['endsAt']?.toString() ?? ''),
    );
  }
}
