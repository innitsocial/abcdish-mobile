class PartnerStore {
  const PartnerStore({
    required this.id,
    required this.storeName,
    required this.postcode,
    required this.websiteUrl,
  });

  final int id;
  final String storeName;
  final String postcode;
  final String websiteUrl;

  factory PartnerStore.fromJson(Map<String, dynamic> json) {
    return PartnerStore(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      storeName:
          json['storeName']?.toString() ?? json['name']?.toString() ?? '',
      postcode: json['postcode']?.toString() ?? '',
      websiteUrl:
          json['websiteUrl']?.toString() ?? json['url']?.toString() ?? '',
    );
  }
}
