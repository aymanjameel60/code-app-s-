import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../widgets/product_card.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key, this.categoryId, this.collectionId, this.title = 'المنتجات'});
  final String? categoryId;
  final String? collectionId;
  final String title;
  @override ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _sort = 'newest';
  @override Widget build(BuildContext context) {
    final state = ref.watch(productsProvider((widget.categoryId, widget.collectionId)));
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(widget.title), centerTitle: true, actions: [PopupMenuButton<String>(tooltip: 'ترتيب حسب', initialValue: _sort, onSelected: (value) => setState(() => _sort = value), itemBuilder: (_) => const [PopupMenuItem(value: 'newest', child: Text('الأحدث')), PopupMenuItem(value: 'price-low', child: Text('السعر: من الأقل للأعلى')), PopupMenuItem(value: 'price-high', child: Text('السعر: من الأعلى للأقل')), PopupMenuItem(value: 'rating', child: Text('الأعلى تقييماً'))])]),
      body: state.when(
        loading: () => const SpikeLoading(),
        error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(productsProvider((widget.categoryId, widget.collectionId)))),
        data: (products) {
          final list = [...products];
          if (_sort == 'price-low') list.sort((a, b) => a.price.compareTo(b.price));
          if (_sort == 'price-high') list.sort((a, b) => b.price.compareTo(a.price));
          if (_sort == 'rating') list.sort((a, b) => b.rating.compareTo(a.rating));
          if (list.isEmpty) return const SpikeEmptyState(message: 'لا توجد منتجات منشورة بعد');
          return GridView.builder(padding: const EdgeInsets.all(17), itemCount: list.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11, mainAxisExtent: 246), itemBuilder: (context, i) => SpikeProductCard(product: list[i], onTap: () => context.push('/product/${list[i].id}'), onStore: list[i].storeId == null ? null : () => context.push('/store/${list[i].storeId}')));
        },
      ),
    );
  }
}
