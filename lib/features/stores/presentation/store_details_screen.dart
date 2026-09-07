import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../widgets/product_card.dart';

class StoreDetailsScreen extends ConsumerStatefulWidget {
  const StoreDetailsScreen({super.key, required this.id});
  final String id;
  @override ConsumerState<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends ConsumerState<StoreDetailsScreen> {
  String _query = '';
  String _sort = 'relevance';
  String _category = 'الكل';

  void _showSort() {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(12), child: Text('الترتيب حسب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
      for (final option in const [('relevance','الأكثر صلة'),('price-low','السعر: من الأقل للأعلى'),('price-high','السعر: من الأعلى للأقل'),('rating','الأعلى تقييماً')])
        ListTile(title: Text(option.$2), trailing: _sort == option.$1 ? const Icon(Icons.check, color: spikeRed) : null, onTap: () { setState(() => _sort = option.$1); Navigator.pop(context); }),
    ])));
  }

  @override Widget build(BuildContext context) {
    final stores = ref.watch(storesProvider);
    final products = ref.watch(allProductsProvider);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: stores.when(
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
              final storeProducts = all.where((p) => p.storeId == store.id).toList();
              final categories = <String>{for (final p in storeProducts) if ((p.categoryName ?? '').trim().isNotEmpty) p.categoryName!.trim()}.toList()..sort();
              final q = _query.toLowerCase();
              final list = storeProducts.where((p) {
                final matchesQuery = q.isEmpty || p.name.toLowerCase().contains(q) || (p.categoryName ?? '').toLowerCase().contains(q);
                final matchesCategory = _category == 'الكل' || p.categoryName == _category;
                return matchesQuery && matchesCategory;
              }).toList();
              if (_sort == 'price-low') list.sort((a,b) => a.price.compareTo(b.price));
              if (_sort == 'price-high') list.sort((a,b) => b.price.compareTo(a.price));
              if (_sort == 'rating') list.sort((a,b) => b.rating.compareTo(a.rating));
              final rated = storeProducts.where((p) => p.rating > 0).toList();
              final rating = rated.isEmpty ? 0.0 : rated.fold<double>(0, (sum, p) => sum + p.rating) / rated.length;
              final reviews = storeProducts.fold<int>(0, (sum, p) => sum + p.reviewCount);

              return CustomScrollView(slivers: [
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(17, 0, 17, 14),
                  child: Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : spikePanel, borderRadius: BorderRadius.circular(24)),
                      child: Row(children: [
                        Container(width: 74, height: 74, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: store.logoUrl == null ? const Icon(Icons.storefront_outlined, size: 32) : CachedNetworkImage(imageUrl: store.logoUrl!, fit: BoxFit.contain)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(store.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text('${storeProducts.length} منتج', style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (rating > 0) ...[
                            const SizedBox(height: 5),
                            Row(children: [const Icon(Icons.star, size: 15, color: Colors.amber), const SizedBox(width: 3), Text('${rating.toStringAsFixed(1)} ($reviews)', style: Theme.of(context).textTheme.bodySmall)]),
                          ],
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    TextField(onChanged: (v) => setState(() => _query = v.trim()), decoration: InputDecoration(hintText: 'ابحث داخل ${store.name}', filled: true, fillColor: spikeField, prefixIcon: const Icon(Icons.search), border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(22))))),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(onPressed: _showSort, icon: const Icon(Icons.swap_vert), label: const Text('ترتيب'))),
                    ]),
                    if (categories.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: [
                        ChoiceChip(label: const Text('الكل'), selected: _category == 'الكل', onSelected: (_) => setState(() => _category = 'الكل')),
                        for (final category in categories) ...[
                          const SizedBox(width: 7),
                          ChoiceChip(label: Text(category), selected: _category == category, onSelected: (_) => setState(() => _category = category)),
                        ],
                      ])),
                    ],
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('منتجات المتجر', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text('${list.length} منتج', style: Theme.of(context).textTheme.bodySmall)]),
                  ]),
                )),
                if (list.isEmpty)
                  const SliverToBoxAdapter(child: SpikeEmptyState(message: 'لا توجد منتجات مطابقة'))
                else
                  SliverPadding(padding: const EdgeInsets.fromLTRB(17, 0, 17, 24), sliver: SliverGrid.builder(itemCount: list.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11, mainAxisExtent: 246), itemBuilder: (context, i) => SpikeProductCard(product: list[i], onTap: () => context.push('/product/${list[i].id}')))),
              ]);
            },
          );
        },
      ),
    );
  }
}
