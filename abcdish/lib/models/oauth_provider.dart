class OAuthProviderOption {
  const OAuthProviderOption({
    required this.provider,
    required this.displayName,
    required this.authorizationUrl,
    required this.enabled,
  });

  final String provider;
  final String displayName;
  final String authorizationUrl;
  final bool enabled;

  factory OAuthProviderOption.fromJson(Map<String, dynamic> json) {
    final provider = json['provider']?.toString() ?? '';
    return OAuthProviderOption(
      provider: provider,
      displayName: json['displayName']?.toString() ?? _displayName(provider),
      authorizationUrl: json['authorizationUrl']?.toString() ?? '',
      enabled: json['enabled'] != false,
    );
  }

  static String _displayName(String provider) {
    switch (provider.toUpperCase()) {
      case 'GOOGLE':
        return 'Google';
      case 'APPLE':
        return 'Apple';
      case 'FACEBOOK':
        return 'Facebook';
      case 'MICROSOFT':
        return 'Microsoft';
      default:
        return provider;
    }
  }
}
