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
              final list = all.where((p) => p.storeId == store.id && (_query.isEmpty || p.name.toLowerCase().contains(_query.toLowerCase()))).toList();
              if (_sort == 'price-low') list.sort((a,b) => a.price.compareTo(b.price));
              if (_sort == 'price-high') list.sort((a,b) => b.price.compareTo(a.price));
              if (_sort == 'rating') list.sort((a,b) => b.rating.compareTo(a.rating));
              return CustomScrollView(slivers: [
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(17, 0, 17, 14), child: Column(children: [
                  Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: spikePanel, borderRadius: BorderRadius.circular(24)), child: Row(children: [Container(width: 74, height: 74, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: store.logoUrl == null ? const Icon(Icons.storefront_outlined, size: 32) : CachedNetworkImage(imageUrl: store.logoUrl!, fit: BoxFit.contain)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(store.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text('${list.length} منتج', style: const TextStyle(fontWeight: FontWeight.w700))]))])),
                  const SizedBox(height: 12),
                  TextField(onChanged: (v) => setState(() => _query = v.trim()), decoration: InputDecoration(hintText: 'ابحث داخل ${store.name}', filled: true, fillColor: spikeField, prefixIcon: const Icon(Icons.search), suffixIcon: PopupMenuButton<String>(initialValue: _sort, onSelected: (v) => setState(() => _sort = v), itemBuilder: (_) => const [PopupMenuItem(value: 'relevance', child: Text('الأكثر صلة')), PopupMenuItem(value: 'price-low', child: Text('السعر الأقل')), PopupMenuItem(value: 'price-high', child: Text('السعر الأعلى')), PopupMenuItem(value: 'rating', child: Text('الأعلى تقييماً'))]), border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(22))))),
                ]))),
                if (list.isEmpty) const SliverToBoxAdapter(child: SpikeEmptyState(message: 'لا توجد منتجات مطابقة')) else SliverPadding(padding: const EdgeInsets.fromLTRB(17, 0, 17, 24), sliver: SliverGrid.builder(itemCount: list.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11, mainAxisExtent: 246), itemBuilder: (context, i) => SpikeProductCard(product: list[i], onTap: () => context.push('/product/${list[i].id}')))),
              ]);
            },
          );
        },
      ),
    );
  }
}
