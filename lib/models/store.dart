import '../core/api_config.dart';

class StoreModel {
  const StoreModel({required this.id, required this.name, this.logoUrl, this.rating = 0, this.reviewCount = 0});
  final String id;
  final String name;
  final String? logoUrl;
  final double rating;
  final int reviewCount;

  factory StoreModel.fromJson(Map<String, dynamic> j) {
    final raw = '${j['logo_url'] ?? ''}'.trim();
    return StoreModel(
      id: '${j['id'] ?? ''}',
      name: '${j['name'] ?? ''}',
      logoUrl: raw.isEmpty ? null : (raw.startsWith('http') ? raw : raw.startsWith('/uploads/') ? '${ApiConfig.assetBaseUrl}$raw' : raw),
      rating: double.tryParse('${j['review_average'] ?? 0}') ?? 0,
      reviewCount: int.tryParse('${j['review_count'] ?? 0}') ?? 0,
    );
  }
}
