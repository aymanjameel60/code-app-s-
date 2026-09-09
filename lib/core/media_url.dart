import 'api_config.dart';

/// Resolves backend image references: absolute URLs pass through, `/uploads/...`
/// is served by the API host, and bare storage object keys (`products/x.webp`,
/// `stores/y.png`, ...) live in the public Supabase bucket.
String? resolveMediaUrl(Object? value) {
  final raw = '${value ?? ''}'.trim();
  if (raw.isEmpty) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  if (raw.startsWith('/uploads/')) return '${ApiConfig.assetBaseUrl}$raw';
  if (RegExp(r'^(products|collections|categories|banners|stores|receipts|avatars|support|misc)/').hasMatch(raw)) {
    return '${ApiConfig.mediaBaseUrl}/$raw';
  }
  return raw;
}
