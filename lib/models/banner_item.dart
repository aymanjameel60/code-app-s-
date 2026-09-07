class BannerItem {
  const BannerItem({required this.id, required this.imageUrl, required this.actionType, required this.target});
  final String id;
  final String imageUrl;
  final String actionType;
  final String target;

  factory BannerItem.fromJson(Map<String, dynamic> json) => BannerItem(
    id: '${json['id'] ?? ''}',
    imageUrl: '${json['image_url'] ?? ''}',
    actionType: '${json['action_type'] ?? 'none'}',
    target: '${json['target'] ?? ''}',
  );
}
