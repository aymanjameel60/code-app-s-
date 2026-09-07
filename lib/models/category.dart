import '../core/api_config.dart';

class CategoryModel {
  const CategoryModel({required this.id, required this.name, this.imageUrl, this.enabled = true, this.sortOrder = 0});
  final String id;
  final String name;
  final String? imageUrl;
  final bool enabled;
  final int sortOrder;

  factory CategoryModel.fromJson(Map<String, dynamic> j) {
    final raw = '${j['image_url'] ?? ''}'.trim();
    final image = raw.isEmpty ? null : (raw.startsWith('http') ? raw : raw.startsWith('/uploads/') ? '${ApiConfig.assetBaseUrl}$raw' : raw);
    return CategoryModel(
      id: '${j['id'] ?? ''}',
      name: '${j['name'] ?? ''}',
      imageUrl: image,
      enabled: j['enabled'] != false,
      sortOrder: int.tryParse('${j['sort_order'] ?? 0}') ?? 0,
    );
  }
}
