class VideoAccess {
  const VideoAccess({
    required this.allowed,
    required this.message,
    required this.usedViews,
    required this.remainingViews,
    required this.membershipStatus,
  });

  final bool allowed;
  final String message;
  final int usedViews;
  final int remainingViews;
  final String membershipStatus;

  factory VideoAccess.fromJson(Map<String, dynamic> json) {
    return VideoAccess(
      allowed: json['allowed'] ?? false,
      message: json['message'] ?? '',
      usedViews: json['usedViews'] ?? 0,
      remainingViews: json['remainingViews'] ?? 0,
      membershipStatus: json['membershipStatus'] ?? 'FREE',
    );
  }
}
