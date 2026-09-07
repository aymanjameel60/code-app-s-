class CollectionModel {
  const CollectionModel({required this.id, required this.name, this.imageUrl, this.destinationType, this.destinationId, this.sortOrder = 0});
  final String id;
  final String name;
  final String? imageUrl;
  final String? destinationType;
  final String? destinationId;
  final int sortOrder;

  factory CollectionModel.fromJson(Map<String, dynamic> json) => CollectionModel(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? ''}',
    imageUrl: json['image_url']?.toString(),
    destinationType: json['destination_type']?.toString(),
    destinationId: json['destination_id']?.toString(),
    sortOrder: int.tryParse('${json['sort_order'] ?? 0}') ?? 0,
  );
}
