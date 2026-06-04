class OAuthProviderInfo {
  const OAuthProviderInfo({
    required this.provider,
    required this.authorizationUrl,
    required this.message,
  });

  final String provider;
  final String authorizationUrl;
  final String message;

  factory OAuthProviderInfo.fromJson(Map<String, dynamic> json) {
    return OAuthProviderInfo(
      provider: json['provider']?.toString() ?? '',
      authorizationUrl: json['authorizationUrl']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}
