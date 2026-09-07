import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../models/product.dart';
import '../../../widgets/product_card.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key, this.categoryId, this.collectionId, this.title = 'المنتجات'});
  final String? categoryId;
  final String? collectionId;
  final String title;
  @override ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _sort = 'relevance';
  String _category = 'الكل';
  final Set<String> _favoriteBusy = {};

  void _showSort() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(12), child: Text('الترتيب حسب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          for (final option in const [
            ('relevance', 'الأكثر صلة'),
            ('price-low', 'السعر: من الأقل للأعلى'),
            ('price-high', 'السعر: من الأعلى للأقل'),
            ('rating', 'الأعلى تقييماً'),
            ('discount', 'الأعلى خصماً'),
          ])
            RadioListTile<String>(
              value: option.$1,
              groupValue: _sort,
              title: Text(option.$2),
              onChanged: (value) { if (value != null) setState(() => _sort = value); Navigator.pop(context); },
            ),
        ]),
      ),
    );
  }

  double _discount(ProductModel p) {
    final original = p.originalPrice ?? 0;
    return original > p.price && original > 0 ? (original - p.price) / original : 0;
  }

  Future<void> _toggleFavorite(ProductModel p) async {
    if (_favoriteBusy.contains(p.id)) return;
    setState(() => _favoriteBusy.add(p.id));
    final ids = ref.read(wishlistIdsProvider).valueOrNull ?? <String>{};
    final active = ids.contains(p.id);
    try {
      if (active) await ref.read(engagementRepositoryProvider).removeWishlist(p.id);
      else await ref.read(engagementRepositoryProvider).addWishlist(p.id);
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
    final variant = p.cheapestVariant;
    if (variant == null || !p.purchasable) return;
    try {
      await ref.read(cartRepositoryProvider).add(variantId: variant.id);
      ref.invalidate(cartCountProvider);
      if (mounted) showSpikeToast(context, 'تمت إضافة المنتج إلى السلة');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    }
  }

  @override Widget build(BuildContext context) {
    final state = ref.watch(productsProvider((widget.categoryId, widget.collectionId)));
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final favorites = ref.watch(wishlistIdsProvider).valueOrNull ?? <String>{};
    final chips = <String>['الكل', ...categories.map((e) => e.name), 'عروض'];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.title),
        centerTitle: true,
        actions: [TextButton(onPressed: _showSort, child: const Text('ترتيب حسب'))],
      ),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, i) {
              final item = chips[i];
              final active = _category == item;
              return ChoiceChip(
                label: Text(item),
                selected: active,
                onSelected: (_) => setState(() => _category = item),
                selectedColor: spikeRed,
                labelStyle: TextStyle(color: active ? Colors.white : null, fontWeight: FontWeight.w700),
              );
            },
          ),
        ),
        Expanded(child: state.when(
          loading: () => const SpikeLoading(),
          error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(productsProvider((widget.categoryId, widget.collectionId)))),
          data: (products) {
            final list = products.where((p) {
              if (_category == 'الكل') return true;
              if (_category == 'عروض') return _discount(p) > 0;
              return p.categoryName == _category;
            }).toList();
            if (_sort == 'price-low') list.sort((a, b) => a.price.compareTo(b.price));
            if (_sort == 'price-high') list.sort((a, b) => b.price.compareTo(a.price));
            if (_sort == 'rating') list.sort((a, b) => b.rating.compareTo(a.rating));
            if (_sort == 'discount') list.sort((a, b) => _discount(b).compareTo(_discount(a)));
            if (list.isEmpty) return const SpikeEmptyState(message: 'لا توجد منتجات في هذا القسم حالياً');
            return GridView.builder(
              padding: const EdgeInsets.all(17),
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11, mainAxisExtent: 246),
              itemBuilder: (context, i) {
                final p = list[i];
                return SpikeProductCard(
                  product: p,
                  isFavorite: favorites.contains(p.id),
                  onTap: () => context.push('/product/${p.id}'),
                  onStore: p.storeId == null ? null : () => context.push('/store/${p.storeId}'),
                  onAdd: p.purchasable && p.cheapestVariant != null ? () => _add(p) : null,
                  onFavorite: _favoriteBusy.contains(p.id) ? null : () => _toggleFavorite(p),
                );
              },
            );
          },
        )),
      ]),
    );
  }
}
