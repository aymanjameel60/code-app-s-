import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../features/cart/data/cart_repository.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/engagement/data/engagement_repository.dart';
import '../features/home/data/home_repository.dart';
import '../models/product.dart';
import '../models/store.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
));
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage(ref.watch(secureStorageProvider)));
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(tokenStorage: ref.watch(tokenStorageProvider)));

final homeRepositoryProvider = Provider<HomeRepository>((ref) => HomeRepository(ref.watch(apiClientProvider)));
final homeDataProvider = FutureProvider<HomeData>((ref) => ref.watch(homeRepositoryProvider).load());

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) => CatalogRepository(ref.watch(apiClientProvider)));
final productsProvider = FutureProvider.family<List<ProductModel>, (String?, String?)>((ref, query) =>
    ref.watch(catalogRepositoryProvider).products(categoryId: query.$1, collectionId: query.$2));
final productProvider = FutureProvider.family<ProductModel?, String>((ref, id) =>
    ref.watch(catalogRepositoryProvider).product(id));
final storesProvider = FutureProvider<List<StoreModel>>((ref) => ref.watch(catalogRepositoryProvider).stores());
final allProductsProvider = FutureProvider<List<ProductModel>>((ref) => ref.watch(catalogRepositoryProvider).products());

final cartRepositoryProvider = Provider<CartRepository>((ref) => CartRepository(ref.watch(apiClientProvider)));
final engagementRepositoryProvider = Provider<EngagementRepository>((ref) => EngagementRepository(ref.watch(apiClientProvider)));
