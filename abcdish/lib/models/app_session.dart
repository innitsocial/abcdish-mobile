class AppSession {
  const AppSession({
    required this.userId,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.emailVerified,
    required this.mobileVerified,
    required this.role,
    required this.membershipStatus,
    required this.monthlyVideoViews,
    required this.remainingViews,
    required this.features,
  });

  final int userId;
  final String? name;
  final String? email;
  final String? mobileNumber;
  final bool emailVerified;
  final bool mobileVerified;
  final String role;
  final String membershipStatus;
  final int monthlyVideoViews;
  final int remainingViews;
  final AppFeatures features;

  factory AppSession.fromJson(Map<String, dynamic> json) {
    return AppSession(
      userId: json['userId'] ?? 0,
      name: json['name'],
      email: json['email'],
      mobileNumber: json['mobileNumber'],
      emailVerified: json['emailVerified'] ?? false,
      mobileVerified: json['mobileVerified'] ?? false,
      role: json['role'] ?? 'USER',
      membershipStatus: json['membershipStatus'] ?? 'FREE',
      monthlyVideoViews: json['monthlyVideoViews'] ?? 0,
      remainingViews: json['remainingViews'] ?? 0,
      features: AppFeatures.fromJson(json['features'] ?? {}),
    );
  }
}

class AppFeatures {
  const AppFeatures({
    required this.canWatchUnlimitedVideos,
    required this.canUploadRecipes,
    required this.canAccessAdmin,
    required this.canManageMembership,
    required this.shouldShowUpgrade,
  });

  final bool canWatchUnlimitedVideos;
  final bool canUploadRecipes;
  final bool canAccessAdmin;
  final bool canManageMembership;
  final bool shouldShowUpgrade;

  factory AppFeatures.fromJson(Map<String, dynamic> json) {
    return AppFeatures(
      canWatchUnlimitedVideos: json['canWatchUnlimitedVideos'] ?? false,
      canUploadRecipes: json['canUploadRecipes'] ?? false,
      canAccessAdmin: json['canAccessAdmin'] ?? false,
      canManageMembership: json['canManageMembership'] ?? false,
      shouldShowUpgrade: json['shouldShowUpgrade'] ?? false,
    );
  }
}
