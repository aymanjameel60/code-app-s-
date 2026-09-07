import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../models/banner_item.dart';
import '../../../models/category.dart';
import '../../../models/collection.dart';
import '../../../models/product.dart';
import '../../../models/store.dart';
import '../../../widgets/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _bannerController = PageController();
  int _bannerIndex = 0;

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeDataProvider);
    final activeAddress = ref.watch(activeAddressProvider).valueOrNull;
    final settings = ref.watch(appSettingsProvider);

    return SafeArea(child: home.when(
      loading: () => const SpikeLoading(),
      error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(homeDataProvider)),
      data: (data) {
        final offers = data.products.where(_hasOffer).toList();
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeDataProvider);
            ref.invalidate(addressesProvider);
            await ref.read(homeDataProvider.future);
          },
          child: ListView(padding: EdgeInsets.zero, children: [
            _Header(
              address: activeAddress == null ? 'اختر عنوان التوصيل' : '${activeAddress.cityName} - ${activeAddress.label}',
              currency: _currencySymbol(settings.currency),
              onSearch: () => context.push('/search'),
              onAddress: () => context.push('/addresses'),
              onNotifications: () => context.push('/notifications'),
              onCurrency: _openCurrencySheet,
            ),
            if (data.banners.isNotEmpty) _BannerCarousel(items: data.banners, controller: _bannerController, index: _bannerIndex, onPageChanged: (i) => setState(() => _bannerIndex = i), onTap: _openBanner),
            _SectionTitle(title: 'تسوق حسب الفئة', showAll: data.categories.isNotEmpty, onShowAll: () => context.push('/categories')),
            _CategoriesGrid(categories: data.categories.take(8).toList(), onTap: (c) => context.push('/products?category=${Uri.encodeComponent(c.id)}&title=${Uri.encodeComponent(c.name)}')),
            _SectionTitle(title: 'مختارة لك', showAll: data.products.isNotEmpty, onShowAll: () => context.push('/products')),
            _productsStrip(products: data.products, emptyMessage: 'لا توجد منتجات منشورة بعد'),
            if (offers.isNotEmpty) ...[
              _SectionTitle(title: 'العروض والخصومات', showAll: true, onShowAll: () => context.push('/offers')),
              _productsStrip(products: offers, emptyMessage: 'لا توجد عروض حالياً'),
            ],
            if (data.collections.isNotEmpty) ...[
              const _SectionTitle(title: 'المجموعات', showAll: false),
              _CollectionsStrip(collections: data.collections, onTap: (c) {
                final type = (c.destinationType ?? '').toLowerCase(), id = c.destinationId ?? '';
                if (id.isEmpty) return;
                if (type == 'product') {
                  context.push('/product/$id');
                } else if (type == 'category') {
                  context.push('/products?category=${Uri.encodeComponent(id)}&title=${Uri.encodeComponent(c.name)}');
                } else if (type == 'collection') {
                  context.push('/products?collection=${Uri.encodeComponent(id)}&title=${Uri.encodeComponent(c.name)}');
                }
              }),
            ],
            _SectionTitle(title: 'المتاجر', showAll: data.stores.isNotEmpty, onShowAll: () => context.push('/stores')),
            _StoresStrip(stores: data.stores, onTap: (s) => context.push('/store/${s.id}')),
            const SizedBox(height: 18),
          ]),
        );
      },
    ));
  }

  bool _hasOffer(ProductModel p) {
    final v = p.cheapestVariant;
    return v != null && v.originalPrice != null && v.originalPrice! > v.price && v.price > 0;
  }

  String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'SAR': return 'ر.س';
      case 'USD': return '\$';
      case 'YER':
      case 'YER_OLD': return 'ر.ي';
      case 'TRY': return '₺';
      default: return code.toUpperCase();
    }
  }

  void _openBanner(BannerItem item) {
    if (item.actionType == 'none' || item.target.isEmpty) return;
    final t = item.actionType.toLowerCase();
    if (t == 'product') {
      context.push('/product/${item.target}');
    } else if (t == 'category') {
      context.push('/products?category=${Uri.encodeComponent(item.target)}');
    } else if (t == 'collection') {
      context.push('/products?collection=${Uri.encodeComponent(item.target)}');
    } else if (t == 'store') {
      context.push('/store/${item.target}');
    }
  }

  Future<void> _openCurrencySheet() async {
    final currencies = ref.read(currenciesProvider).valueOrNull ?? const [];
    final current = ref.read(appSettingsProvider).currency;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 10, 17, 22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 44, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .12), borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 14),
          Row(children: [const Expanded(child: Text('اختر العملة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700))), IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(LucideIcons.x))]),
          if (currencies.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Text('لا توجد عملات متاحة حالياً', style: TextStyle(color: spikeMuted))),
          for (final c in currencies) ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(c.code),
            trailing: Icon(current == c.code ? Icons.radio_button_checked : Icons.radio_button_off, color: current == c.code ? spikeRed : null),
            onTap: () async {
              await ref.read(appSettingsProvider.notifier).setCurrency(c.code);
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            },
          ),
        ]),
      )),
    );
  }

  Future<void> _add(ProductModel p) async {
    if (!p.purchasable || p.cheapestVariant == null) return;
    try {
      await ref.read(cartRepositoryProvider).add(variantId: p.cheapestVariant!.id);
      if (mounted) showSpikeToast(context, 'تمت إضافة المنتج إلى السلة');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    }
  }

  Future<void> _favorite(ProductModel p) async {
    try {
      await ref.read(engagementRepositoryProvider).addWishlist(p.id);
      if (mounted) showSpikeToast(context, 'تمت إضافة المنتج إلى المفضلة');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    }
  }

  Widget _productsStrip({required List<ProductModel> products, required String emptyMessage}) => SizedBox(
    height: 246,
    child: products.isEmpty
        ? SpikeEmptyState(message: emptyMessage)
        : ListView.separated(
            reverse: true,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 17),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final p = products[i];
              return SpikeProductCard(
                product: p,
                onTap: () => context.push('/product/${p.id}'),
                onAdd: !p.purchasable || p.cheapestVariant == null ? null : () => _add(p),
                onFavorite: () => _favorite(p),
                onStore: p.storeId == null ? null : () => context.push('/store/${p.storeId}'),
              );
            },
          ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.address, required this.currency, required this.onSearch, required this.onAddress, required this.onNotifications, required this.onCurrency});
  final String address, currency;
  final VoidCallback onSearch, onAddress, onNotifications, onCurrency;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(17, 8, 17, 0),
    child: Column(children: [
      SizedBox(height: 64, child: Row(children: [
        const SizedBox(width: 58, height: 38, child: Center(child: Text('SPIKE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -.5)))),
        Expanded(child: TextButton(onPressed: onAddress, style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface, padding: const EdgeInsets.symmetric(horizontal: 4)), child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.chevronDown, size: 17), const SizedBox(width: 3), Flexible(child: Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))]))),
        IconButton(onPressed: onNotifications, icon: const Icon(LucideIcons.bell, size: 22)),
      ])),
      Row(children: [
        Expanded(child: InkWell(onTap: onSearch, borderRadius: BorderRadius.circular(22), child: Container(height: 39, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : spikeField, borderRadius: BorderRadius.circular(22)), child: const Row(children: [Icon(LucideIcons.search, size: 20), SizedBox(width: 10), Expanded(child: Text('ابحث عن المنتجات ...', style: TextStyle(fontSize: 12, color: spikeMuted)))])))),
        const SizedBox(width: 9),
        InkWell(onTap: onCurrency, borderRadius: BorderRadius.circular(22), child: Container(width: 53, height: 39, alignment: Alignment.center, decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : spikeField, borderRadius: BorderRadius.circular(22)), child: Text(currency, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)))),
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

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
    child: Column(children: [
      SizedBox(height: 130, child: PageView.builder(controller: controller, itemCount: items.length, onPageChanged: onPageChanged, itemBuilder: (context, i) => GestureDetector(onTap: () => onTap(items[i]), child: ClipRRect(borderRadius: BorderRadius.circular(23), child: CachedNetworkImage(imageUrl: items[i].imageUrl, width: double.infinity, height: 130, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .08))))))),
      SizedBox(
        height: 22,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            items.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: i == index ? 17 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: i == index ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .4) : Theme.of(context).colorScheme.onSurface.withValues(alpha: .12),
              ),
            ),
          ),
        ),
      ),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.showAll, this.onShowAll});
  final String title;
  final bool showAll;
  final VoidCallback? onShowAll;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 17), child: SizedBox(height: 48, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)), if (showAll) TextButton(onPressed: onShowAll, child: const Text('عرض الكل', style: TextStyle(fontSize: 12)))])));
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({required this.categories, required this.onTap});
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onTap;
  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SpikeEmptyState(message: 'لا توجد أقسام منشورة بعد');
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 17), child: GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: categories.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 11, mainAxisSpacing: 13, childAspectRatio: .78), itemBuilder: (context, i) {
      final c = categories[i];
      return InkWell(onTap: () => onTap(c), borderRadius: BorderRadius.circular(21), child: Column(children: [Container(width: 81, height: 81, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(21)), child: c.imageUrl == null ? const Icon(LucideIcons.image, color: Colors.black26) : CachedNetworkImage(imageUrl: c.imageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(LucideIcons.image, color: Colors.black26))), const SizedBox(height: 7), Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.2))]));
    }));
  }
}

class _CollectionsStrip extends StatelessWidget {
  const _CollectionsStrip({required this.collections, required this.onTap});
  final List<CollectionModel> collections;
  final ValueChanged<CollectionModel> onTap;
  @override
  Widget build(BuildContext context) => SizedBox(height: 111, child: ListView.separated(reverse: true, scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 2), itemCount: collections.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (context, i) {
    final c = collections[i];
    return GestureDetector(onTap: () => onTap(c), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 153, height: 101, child: c.imageUrl == null ? Container(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .08)) : CachedNetworkImage(imageUrl: c.imageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .08))))));
  }));
}

class _StoresStrip extends StatelessWidget {
  const _StoresStrip({required this.stores, required this.onTap});
  final List<StoreModel> stores;
  final ValueChanged<StoreModel> onTap;
  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) return const SpikeEmptyState(message: 'لا توجد متاجر منشورة بعد');
    return SizedBox(height: 69, child: ListView.separated(reverse: true, scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 17), itemCount: stores.length, separatorBuilder: (_, __) => const SizedBox(width: 11), itemBuilder: (context, i) => InkWell(onTap: () => onTap(stores[i]), borderRadius: BorderRadius.circular(22), child: Container(width: 154, height: 69, alignment: Alignment.center, decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : spikePanel, borderRadius: BorderRadius.circular(22)), child: Text(stores[i].name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))))));
  }
}
