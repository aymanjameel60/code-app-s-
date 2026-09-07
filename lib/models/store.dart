import '../core/api_config.dart';

class StoreModel {
  const StoreModel({required this.id, required this.name, this.logoUrl});
  final String id;
  final String name;
  final String? logoUrl;

  factory StoreModel.fromJson(Map<String, dynamic> j) {
    final raw = '${j['logo_url'] ?? ''}'.trim();
    return StoreModel(
      id: '${j['id'] ?? ''}',
      name: '${j['name'] ?? ''}',
      logoUrl: raw.isEmpty ? null : (raw.startsWith('http') ? raw : raw.startsWith('/uploads/') ? '${ApiConfig.assetBaseUrl}$raw' : raw),
    );
  }
}
