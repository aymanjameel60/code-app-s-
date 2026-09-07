import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/api_config.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../models/banner_item.dart';
import '../../../models/category.dart';
import '../../../models/collection.dart';
import '../../../models/store.dart';
import '../../../widgets/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;

  @override void dispose() { _bannerController.dispose(); super.dispose(); }

  String _absolute(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/uploads/')) return '${ApiConfig.assetBaseUrl}$raw';
    return raw;
  }

  @override Widget build(BuildContext context) {
    final asyncHome = ref.watch(homeDataProvider);
    return SafeArea(
      child: asyncHome.when(
        loading: () => const SpikeLoading(),
        error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(homeDataProvider)),
        data: (data) => RefreshIndicator(
          onRefresh: () async { ref.invalidate(homeDataProvider); await ref.read(homeDataProvider.future); },
          child: ListView(padding: EdgeInsets.zero, children: [
            _Header(
              onSearch: () => context.push('/search'),
              onAddress: () => showSpikeToast(context, 'العناوين سيتم ربطها في مرحلة الحساب والدفع'),
              onNotifications: () => showSpikeToast(context, 'الإشعارات سيتم ربطها بالـ API في المرحلة التالية'),
              onCurrency: () => _openCurrencySheet(context),
            ),
            if (data.banners.isNotEmpty) _BannerCarousel(items: data.banners, controller: _bannerController, index: _bannerIndex, onPageChanged: (i) => setState(() => _bannerIndex = i), onTap: _openBanner),
            _SectionTitle(title: 'تسوق حسب الفئة', showAll: data.categories.isNotEmpty, onShowAll: () => context.push('/categories')),
            _CategoriesGrid(categories: data.categories.take(8).toList(), onTap: (c) => context.push('/products?category=${Uri.encodeComponent(c.id)}&title=${Uri.encodeComponent(c.name)}')),
            _SectionTitle(title: 'المنتجات', showAll: data.products.isNotEmpty, onShowAll: () => context.push('/products')),
            SizedBox(
              height: 246,
              child: data.products.isEmpty
                  ? const SpikeEmptyState(message: 'لا توجد منتجات منشورة بعد')
                  : ListView.separated(
                      reverse: true,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      itemCount: data.products.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final product = data.products[i];
                        return SpikeProductCard(
                          product: product,
                          onTap: () => context.push('/product/${product.id}'),
                          onAdd: !product.purchasable || product.cheapestVariant == null ? null : () async {
                            try {
                              await ref.read(cartRepositoryProvider).add(variantId: product.cheapestVariant!.id);
                              if (context.mounted) showSpikeToast(context, 'تمت إضافة المنتج إلى السلة');
                            } catch (e) {
                              if (context.mounted) showSpikeToast(context, e.toString());
                            }
                          },
                          onFavorite: () async {
                            try {
                              await ref.read(engagementRepositoryProvider).addWishlist(product.id);
                              if (context.mounted) showSpikeToast(context, 'تمت إضافة المنتج إلى المفضلة');
                            } catch (e) {
                              if (context.mounted) showSpikeToast(context, e.toString());
                            }
                          },
                          onStore: product.storeId == null ? null : () => context.push('/store/${product.storeId}'),
                        );
                      },
                    ),
            ),
            if (data.collections.isNotEmpty) ...[
              const _SectionTitle(title: 'المجموعات', showAll: false),
              _CollectionsStrip(collections: data.collections, onTap: (c) {
                final type = (c.destinationType ?? '').toLowerCase();
                final id = c.destinationId ?? '';
                if (id.isEmpty) return;
                if (type == 'product') context.push('/product/$id');
                else if (type == 'category') context.push('/products?category=${Uri.encodeComponent(id)}&title=${Uri.encodeComponent(c.name)}');
                else if (type == 'collection') context.push('/products?collection=${Uri.encodeComponent(id)}&title=${Uri.encodeComponent(c.name)}');
              }),
            ],
            _SectionTitle(title: 'المتاجر', showAll: data.stores.isNotEmpty, onShowAll: () => context.push('/stores')),
            _StoresStrip(stores: data.stores, onTap: (store) => context.push('/store/${store.id}')),
            const SizedBox(height: 18),
          ]),
        ),
      ),
    );
  }

  void _openBanner(BannerItem item) {
    if (item.actionType == 'none' || item.target.isEmpty) return;
    final type = item.actionType.toLowerCase();
    if (type == 'product') context.push('/product/${item.target}');
    else if (type == 'category') context.push('/products?category=${Uri.encodeComponent(item.target)}');
    else if (type == 'collection') context.push('/products?collection=${Uri.encodeComponent(item.target)}');
    else if (type == 'store') context.push('/store/${item.target}');
  }

  Future<void> _openCurrencySheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: spikeBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 10, 17, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 18),
            const Align(alignment: Alignment.centerRight, child: Text('اختر العملة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700))),
            const SizedBox(height: 10),
            for (final code in const ['SAR', 'USD'])
              ListTile(title: Text(code == 'SAR' ? 'الريال السعودي' : 'الدولار الأمريكي'), subtitle: Text(code), trailing: const Icon(LucideIcons.circle, size: 18), onTap: () { Navigator.pop(context); showSpikeToast(this.context, 'تغيير العملة سيُربط بإعدادات الـ API في مرحلة Settings'); }),
          ]),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearch, required this.onAddress, required this.onNotifications, required this.onCurrency});
  final VoidCallback onSearch, onAddress, onNotifications, onCurrency;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(17, 8, 17, 0),
    child: Column(children: [
      SizedBox(
        height: 64,
        child: Row(children: [
          const SizedBox(width: 53, height: 38, child: Center(child: Text('SPIKE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)))),
          Expanded(child: TextButton.icon(onPressed: onAddress, icon: const Icon(LucideIcons.chevronDown, size: 18, color: Colors.black), label: const Text('اختر عنوان التوصيل', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.black)))),
          IconButton(onPressed: onNotifications, icon: const Icon(LucideIcons.bell, size: 22)),
        ]),
      ),
      Row(children: [
        Expanded(
          child: InkWell(
            onTap: onSearch,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 39,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: spikeField, borderRadius: BorderRadius.circular(22)),
              child: const Row(children: [Icon(LucideIcons.search, size: 20), SizedBox(width: 10), Expanded(child: Text('ابحث عن المنتجات ...', style: TextStyle(fontSize: 12, color: Color(0xFFBDBDBD))))]),
            ),
          ),
        ),
        const SizedBox(width: 9),
        InkWell(onTap: onCurrency, borderRadius: BorderRadius.circular(22), child: Container(width: 53, height: 39, alignment: Alignment.center, decoration: BoxDecoration(color: spikeField, borderRadius: BorderRadius.circular(22)), child: const Text('ر.س', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)))),
      ]),
    ]),
  );
}

class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({required this.items, required this.controller, required this.index, required this.onPageChanged, required this.onTap});
  final List<BannerItem> items;
  final PageController controller;
  final int index;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<BannerItem> onTap;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
    child: Column(children: [
      SizedBox(
        height: 130,
        child: PageView.builder(
          controller: controller,
          itemCount: items.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => onTap(items[i]),
            child: ClipRRect(borderRadius: BorderRadius.circular(23), child: CachedNetworkImage(imageUrl: items[i].imageUrl, width: double.infinity, height: 130, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Colors.black12))),
          ),
        ),
      ),
      SizedBox(height: 22, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(items.length, (i) => Container(width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(shape: BoxShape.circle, color: i == index ? Colors.black38 : Colors.black12))))),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.showAll, this.onShowAll});
  final String title;
  final bool showAll;
  final VoidCallback? onShowAll;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(17, 0, 17, 0),
    child: SizedBox(height: 48, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)), if (showAll) TextButton(onPressed: onShowAll, child: const Text('عرض الكل', style: TextStyle(fontSize: 12, color: Colors.black)))])),
  );
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({required this.categories, required this.onTap});
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onTap;
  @override Widget build(BuildContext context) {
    if (categories.isEmpty) return const SpikeEmptyState(message: 'لا توجد أقسام منشورة بعد');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 11, mainAxisSpacing: 13, childAspectRatio: .78),
        itemBuilder: (context, i) {
          final c = categories[i];
          return InkWell(
            onTap: () => onTap(c),
            borderRadius: BorderRadius.circular(21),
            child: Column(children: [
              Container(width: 81, height: 81, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21)), child: c.imageUrl == null ? const Icon(LucideIcons.image, color: Colors.black26) : CachedNetworkImage(imageUrl: c.imageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(LucideIcons.image, color: Colors.black26))),
              const SizedBox(height: 7),
              Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.2)),
            ]),
          );
        },
      ),
    );
  }
}

class _CollectionsStrip extends StatelessWidget {
  const _CollectionsStrip({required this.collections, required this.onTap});
  final List<CollectionModel> collections;
  final ValueChanged<CollectionModel> onTap;
  @override Widget build(BuildContext context) => SizedBox(
    height: 111,
    child: ListView.separated(
      reverse: true,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 2),
      itemCount: collections.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, i) {
        final c = collections[i];
        return GestureDetector(
          onTap: () => onTap(c),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 153, height: 101, child: c.imageUrl == null ? Container(color: Colors.black12) : CachedNetworkImage(imageUrl: c.imageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Colors.black12))),
          ),
        );
      },
    ),
  );
}

class _StoresStrip extends StatelessWidget {
  const _StoresStrip({required this.stores, required this.onTap});
  final List<StoreModel> stores;
  final ValueChanged<StoreModel> onTap;
  @override Widget build(BuildContext context) {
    if (stores.isEmpty) return const SpikeEmptyState(message: 'لا توجد متاجر منشورة بعد');
    return SizedBox(
      height: 69,
      child: ListView.separated(
        reverse: true,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 17),
        itemCount: stores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (context, i) => InkWell(onTap: () => onTap(stores[i]), borderRadius: BorderRadius.circular(22), child: Container(width: 154, height: 69, alignment: Alignment.center, decoration: BoxDecoration(color: spikePanel, borderRadius: BorderRadius.circular(22)), child: Text(stores[i].name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
      ),
    );
  }
}
