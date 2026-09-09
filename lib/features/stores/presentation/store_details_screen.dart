import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../models/product.dart';
import '../../../widgets/product_card.dart';

class StoreDetailsScreen extends ConsumerStatefulWidget {
  const StoreDetailsScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends ConsumerState<StoreDetailsScreen> {
  String _query = '';
  String _sort = 'relevance';
  final Set<String> _favoriteBusy = {};

  void _showSort() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 20, 17, 25),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Expanded(child: Text('ترتيب منتجات المتجر', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
              IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(LucideIcons.x, size: 20)),
            ]),
            const SizedBox(height: 12),
            for (final option in const [
              ('relevance', 'الترتيب الافتراضي'),
              ('rating', 'الأعلى تقييماً'),
              ('price-low', 'السعر: الأقل أولاً'),
              ('price-high', 'السعر: الأعلى أولاً'),
            ])
              _SortOption(
                label: option.$2,
                selected: _sort == option.$1,
                onTap: () {
                  setState(() => _sort = option.$1);
                  Navigator.pop(sheetContext);
                },
              ),
          ]),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(ProductModel p) async {
    if (_favoriteBusy.contains(p.id)) return;
    setState(() => _favoriteBusy.add(p.id));
    final ids = ref.read(wishlistIdsProvider).valueOrNull ?? <String>{};
    final active = ids.contains(p.id);
    try {
      if (active) {
        await ref.read(engagementRepositoryProvider).removeWishlist(p.id);
      } else {
        await ref.read(engagementRepositoryProvider).addWishlist(p.id);
      }
      ref.invalidate(wishlistIdsProvider);
      ref.invalidate(favoritesProvider);
      if (mounted) showSpikeToast(context, active ? 'تمت إزالة المنتج من المفضلة' : 'تمت إضافة المنتج إلى المفضلة');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _favoriteBusy.remove(p.id));
    }
  }

  Future<void> _add(ProductModel p) async {
    final v = p.cheapestVariant;
    if (v == null || !p.purchasable) return;
    try {
      await ref.read(cartRepositoryProvider).add(variantId: v.id, product: p);
      ref.invalidate(cartCountProvider);
      if (mounted) showSpikeToast(context, 'تمت إضافة المنتج إلى السلة');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storesProvider);
    final products = ref.watch(allProductsProvider);
    final reviewsState = ref.watch(storeReviewsProvider(widget.id));
    final favorites = ref.watch(wishlistIdsProvider).valueOrNull ?? <String>{};
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: stores.when(
          loading: () => const SpikeLoading(),
          error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(storesProvider)),
          data: (storeList) {
            final matching = storeList.where((s) => s.id == widget.id);
            if (matching.isEmpty) return const SpikeEmptyState(message: 'المتجر غير متاح حالياً');
            final store = matching.first;
            return products.when(
              loading: () => const SpikeLoading(),
              error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(allProductsProvider)),
              data: (all) {
                final q = _query.toLowerCase();
                final list = all.where((p) => p.storeId == store.id && (q.isEmpty || p.name.toLowerCase().contains(q) || (p.categoryName ?? '').toLowerCase().contains(q))).toList();
                if (_sort == 'price-low') list.sort((a, b) => a.price.compareTo(b.price));
                if (_sort == 'price-high') list.sort((a, b) => b.price.compareTo(a.price));
                if (_sort == 'rating') list.sort((a, b) => b.rating.compareTo(a.rating));

                final storeRating = reviewsState.valueOrNull;
                final rating = double.tryParse('${storeRating?['average'] ?? store.rating}') ?? store.rating;
                final reviewsCount = int.tryParse('${storeRating?['count'] ?? store.reviewCount}') ?? store.reviewCount;

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(storesProvider);
                    ref.invalidate(allProductsProvider);
                    ref.invalidate(storeReviewsProvider(widget.id));
                    ref.invalidate(wishlistIdsProvider);
                    await ref.read(allProductsProvider.future);
                  },
                  child: CustomScrollView(slivers: [
                    SliverToBoxAdapter(
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(17, 8, 17, 12),
                          child: Row(children: [
                            SizedBox(
                              width: 50,
                              height: 40,
                              child: Material(
                                color: dark ? spikeDarkPanel : const Color(0xFFE8E8E8),
                                borderRadius: BorderRadius.circular(22),
                                child: InkWell(borderRadius: BorderRadius.circular(22), onTap: () => context.canPop() ? context.pop() : context.go('/'), child: const Icon(LucideIcons.arrowRight, size: 23)),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Container(
                                height: 39,
                                decoration: BoxDecoration(color: dark ? spikeDarkPanel : spikeField, borderRadius: BorderRadius.circular(22)),
                                child: TextField(
                                  onChanged: (v) => setState(() => _query = v.trim()),
                                  decoration: InputDecoration(
                                    hintText: 'ابحث داخل ${store.name}',
                                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                        Container(
                          color: dark ? spikeDarkPanel : Colors.white,
                          child: Column(children: [
                            SizedBox(
                              height: 185,
                              width: double.infinity,
                              child: store.bannerUrl == null
                                  ? Container(color: dark ? Colors.white10 : Colors.black12)
                                  : CachedNetworkImage(imageUrl: store.bannerUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: dark ? Colors.white10 : Colors.black12)),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -24),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 17),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEEEEEE))),
                                    child: store.logoUrl == null
                                        ? const Icon(LucideIcons.store, color: Colors.black)
                                        : CachedNetworkImage(imageUrl: store.logoUrl!, fit: BoxFit.contain, errorWidget: (_, __, ___) => const Icon(LucideIcons.store, color: Colors.black)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Row(children: [
                                          Flexible(child: Text(store.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                                          if (store.isVerified) ...[const SizedBox(width: 4), const Icon(LucideIcons.badgeCheck, size: 15)],
                                        ]),
                                        const SizedBox(height: 3),
                                        if ((store.categoryName ?? '').isNotEmpty) Text(store.categoryName!, style: const TextStyle(fontSize: 9, color: spikeMuted)),
                                        Text(store.isVerified ? 'متجر موثوق ومميز على Spike' : 'متجر على Spike', style: const TextStyle(fontSize: 9, color: spikeMuted)),
                                      ]),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 17),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                                  _stat('${all.where((p) => p.storeId == store.id).length}', 'منتجات'),
                                  _stat('$reviewsCount', 'مراجعات'),
                                  Column(children: [
                                    Row(children: [Text(reviewsCount > 0 ? rating.toStringAsFixed(1) : '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(width: 3), const Icon(LucideIcons.star, size: 14, color: Color(0xFFF5B400))]),
                                    const SizedBox(height: 2),
                                    const Text('التقييم', style: TextStyle(fontSize: 9, color: spikeMuted)),
                                  ]),
                                ]),
                              ),
                            ),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(17, 16, 17, 12),
                          child: Row(children: [
                            const Expanded(child: Text('منتجات المتجر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                            IconButton(onPressed: () => Share.share('متجر ${store.name} على Spike'), icon: const Icon(LucideIcons.share2, size: 18), tooltip: 'مشاركة'),
                            IconButton(onPressed: _showSort, icon: const Icon(LucideIcons.arrowUpDown, size: 18), tooltip: 'ترتيب حسب'),
                          ]),
                        ),
                      ]),
                    ),
                    if (list.isEmpty)
                      const SliverToBoxAdapter(child: SpikeEmptyState(message: 'لا توجد منتجات مطابقة'))
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
                        sliver: SliverGrid.builder(
                          itemCount: list.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11, mainAxisExtent: 246),
                          itemBuilder: (context, i) {
                            final p = list[i];
                            return SpikeProductCard(
                              product: p,
                              isFavorite: favorites.contains(p.id),
                              onTap: () => context.push('/product/${p.id}'),
                              onAdd: p.purchasable && p.cheapestVariant != null ? () => _add(p) : null,
                              onFavorite: _favoriteBusy.contains(p.id) ? null : () => _toggleFavorite(p),
                            );
                          },
                        ),
                      ),
                  ]),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(children: [Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 9, color: spikeMuted))]);
}

class _SortOption extends StatelessWidget {
  const _SortOption({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
            Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5)),
              child: selected ? Center(child: Container(width: 11, height: 11, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface, shape: BoxShape.circle))) : null,
            ),
          ]),
        ),
      );
}
