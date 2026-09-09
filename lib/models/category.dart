import '../core/media_url.dart';

class CategoryModel {
  const CategoryModel({required this.id, required this.name, this.imageUrl, this.enabled = true, this.sortOrder = 0});
  final String id;
  final String name;
  final String? imageUrl;
  final bool enabled;
  final int sortOrder;

  factory CategoryModel.fromJson(Map<String, dynamic> j) {
    final image = resolveMediaUrl(j['image_url']);
    return CategoryModel(
      id: '${j['id'] ?? ''}',
      name: '${j['name'] ?? ''}',
      imageUrl: image,
      enabled: j['enabled'] != false,
      sortOrder: int.tryParse('${j['sort_order'] ?? 0}') ?? 0,
    );
  }
}
