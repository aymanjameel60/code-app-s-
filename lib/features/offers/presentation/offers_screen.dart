import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../models/product.dart';
import '../../../widgets/product_card.dart';

class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});
  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  String sort = 'discount';
  int minDiscount = 0;
  String price = 'all';
  double minRating = 0;
  final Set<String> _favoriteBusy = {};

  int _discount(ProductModel p) {
    final o = p.originalPrice;
    final c = p.price;
    if (o == null || o <= c || c <= 0) return 0;
    return ((o - c) / o * 100).round();
  }

  List<ProductModel> _apply(List<ProductModel> all) {
    var x = all.where((p) => _discount(p) > 0).toList();
    if (minDiscount > 0) x = x.where((p) => _discount(p) >= minDiscount).toList();
    if (price == 'under5') x = x.where((p) => p.price < 5).toList();
    if (price == '5to25') x = x.where((p) => p.price >= 5 && p.price <= 25).toList();
    if (price == 'over25') x = x.where((p) => p.price > 25).toList();
    if (minRating > 0) x = x.where((p) => p.rating >= minRating).toList();
    if (sort == 'priceAsc') {
      x.sort((a, b) => a.price.compareTo(b.price));
    } else if (sort == 'priceDesc') {
      x.sort((a, b) => b.price.compareTo(a.price));
    } else if (sort == 'rating') {
      x.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      x.sort((a, b) => _discount(b).compareTo(_discount(a)));
    }
    return x;
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
      if (mounted) {
        showSpikeToast(context, active ? 'تمت إزالة المنتج من المفضلة' : 'تمت إضافة المنتج إلى المفضلة');
      }
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _favoriteBusy.remove(p.id));
    }
  }

  void _filters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
            SpikeSpacing.page,
            SpikeSpacing.xs,
            SpikeSpacing.page,
            MediaQuery.of(ctx).viewInsets.bottom + SpikeSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('فلترة وترتيب العروض', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: SpikeSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: sort,
                decoration: const InputDecoration(labelText: 'الترتيب'),
                items: const [
                  DropdownMenuItem(value: 'discount', child: Text('أعلى خصم')),
                  DropdownMenuItem(value: 'priceAsc', child: Text('السعر الأقل')),
                  DropdownMenuItem(value: 'priceDesc', child: Text('السعر الأعلى')),
                  DropdownMenuItem(value: 'rating', child: Text('الأعلى تقييماً')),
                ],
                onChanged: (v) {
                  if (v != null) setLocal(() => sort = v);
                },
              ),
              const SizedBox(height: SpikeSpacing.md),
              Wrap(
                spacing: SpikeSpacing.sm,
                runSpacing: SpikeSpacing.sm,
                children: [0, 10, 20, 30, 40]
                    .map((v) => ChoiceChip(
                          label: Text(v == 0 ? 'كل العروض' : 'خصم $v% فأكثر'),
                          selected: minDiscount == v,
                          onSelected: (_) => setLocal(() => minDiscount = v),
                        ))
                    .toList(),
              ),
              const SizedBox(height: SpikeSpacing.md),
              Wrap(
                spacing: SpikeSpacing.sm,
                runSpacing: SpikeSpacing.sm,
                children: <MapEntry<String, String>>[
                  const MapEntry('all', 'كل الأسعار'),
                  const MapEntry('under5', 'أقل من 5 دولار'),
                  const MapEntry('5to25', '5 – 25 دولار'),
                  const MapEntry('over25', 'أكثر من 25 دولار'),
                ]
                    .map((v) => ChoiceChip(
                          label: Text(v.value),
                          selected: price == v.key,
                          onSelected: (_) => setLocal(() => price = v.key),
                        ))
                    .toList(),
              ),
              const SizedBox(height: SpikeSpacing.md),
              Wrap(
                spacing: SpikeSpacing.sm,
                runSpacing: SpikeSpacing.sm,
                children: [0.0, 4.0, 4.5]
                    .map((v) => ChoiceChip(
                          label: Text(v == 0 ? 'كل التقييمات' : '$v نجوم فأعلى'),
                          selected: minRating == v,
                          onSelected: (_) => setLocal(() => minRating = v),
                        ))
                    .toList(),
              ),
              const SizedBox(height: SpikeSpacing.lg),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: spikeRed),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text('عرض النتائج'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(allProductsProvider);
    final favorites = ref.watch(wishlistIdsProvider).valueOrNull ?? <String>{};

    return SafeArea(
      child: state.when(
        loading: () => const SpikeLoading(),
        error: (e, _) => SpikeErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(allProductsProvider),
        ),
        data: (all) {
          final list = _apply(all);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SpikeSpacing.page,
                  SpikeSpacing.md,
                  SpikeSpacing.page,
                  SpikeSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('العروض والخصومات', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                    TextButton.icon(
                      onPressed: _filters,
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('فلترة وترتيب'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const SpikeEmptyState(message: 'لا توجد عروض فعالة حالياً')
                    : GridView.builder(
                        padding: SpikeSpacing.pageList,
                        itemCount: list.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: SpikeSpacing.md,
                          mainAxisSpacing: SpikeSpacing.md,
                          mainAxisExtent: 246,
                        ),
                        itemBuilder: (context, i) {
                          final p = list[i];
                          return SpikeProductCard(
                            product: p,
                            isFavorite: favorites.contains(p.id),
                            onTap: () => context.push('/product/${p.id}'),
                            onStore: p.storeId == null ? null : () => context.push('/store/${p.storeId}'),
                            onAdd: p.cheapestVariant == null
                                ? null
                                : () async {
                                    try {
                                      await ref.read(cartRepositoryProvider).add(variantId: p.cheapestVariant!.id);
                                      ref.invalidate(cartCountProvider);
                                      if (context.mounted) showSpikeToast(context, 'تمت إضافة المنتج إلى السلة');
                                    } catch (e) {
                                      if (context.mounted) showSpikeToast(context, e.toString());
                                    }
                                  },
                            onFavorite: _favoriteBusy.contains(p.id) ? null : () => _toggleFavorite(p),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
