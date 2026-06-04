class Contest {
  const Contest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.prize,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String? prize;
  final String? startsAt;
  final String? endsAt;

  factory Contest.fromJson(Map<String, dynamic> json) {
    return Contest(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Cooking Challenge',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      prize: json['prize']?.toString(),
      startsAt: json['startsAt']?.toString(),
      endsAt: json['endsAt']?.toString(),
    );
  }
}
