import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../models/product.dart';
import '../../../widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});
  final String initialQuery;
  @override ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialQuery);
  String _query = '';
  String _sort = 'relevance';
  String _category = 'الكل';
  bool _offersOnly = false;
  @override void initState() { super.initState(); _query = widget.initialQuery.trim(); }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  double _discount(ProductModel p) {
    final original = p.originalPrice ?? 0;
    return original > p.price && original > 0 ? (original - p.price) / original : 0;
  }

  void _showSort() {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(12), child: Text('الترتيب حسب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
      for (final option in const [('relevance','الأكثر صلة'),('price-low','السعر الأقل'),('price-high','السعر الأعلى'),('rating','الأعلى تقييماً'),('discount','الأعلى خصماً')])
        RadioListTile<String>(value: option.$1, groupValue: _sort, title: Text(option.$2), onChanged: (v) { if (v != null) setState(() => _sort = v); Navigator.pop(context); }),
    ])));
  }

  @override Widget build(BuildContext context) {
    final state = ref.watch(allProductsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('البحث'), centerTitle: true, actions: [TextButton(onPressed: _showSort, child: const Text('ترتيب'))]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 0, 17, 8),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: const InputDecoration(hintText: 'ابحث عن المنتجات ...', filled: true, fillColor: spikeField, prefixIcon: Icon(Icons.search), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(22)))),
          ),
        ),
        SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 17), children: [
          FilterChip(label: const Text('العروض فقط'), selected: _offersOnly, onSelected: (v) => setState(() => _offersOnly = v)),
          const SizedBox(width: 7),
          ChoiceChip(label: const Text('الكل'), selected: _category == 'الكل', onSelected: (_) => setState(() => _category = 'الكل')),
          for (final category in categories) ...[
            const SizedBox(width: 7),
            ChoiceChip(label: Text(category.name), selected: _category == category.name, onSelected: (_) => setState(() => _category = category.name)),
          ],
        ])),
        Expanded(child: state.when(
          loading: () => const SpikeLoading(),
          error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(allProductsProvider)),
          data: (products) {
            final q = _query.toLowerCase();
            final list = products.where((p) {
              final textMatch = q.isEmpty || p.name.toLowerCase().contains(q) || p.storeName.toLowerCase().contains(q) || (p.categoryName ?? '').toLowerCase().contains(q);
              final categoryMatch = _category == 'الكل' || p.categoryName == _category;
              final offerMatch = !_offersOnly || _discount(p) > 0;
              return textMatch && categoryMatch && offerMatch;
            }).toList();
            if (_sort == 'price-low') list.sort((a, b) => a.price.compareTo(b.price));
            if (_sort == 'price-high') list.sort((a, b) => b.price.compareTo(a.price));
            if (_sort == 'rating') list.sort((a, b) => b.rating.compareTo(a.rating));
            if (_sort == 'discount') list.sort((a, b) => _discount(b).compareTo(_discount(a)));
            if (list.isEmpty) return const SpikeEmptyState(message: 'لا توجد نتائج مطابقة');
            return GridView.builder(padding: const EdgeInsets.all(17), itemCount: list.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11, mainAxisExtent: 246), itemBuilder: (context, i) => SpikeProductCard(product: list[i], onTap: () => context.push('/product/${list[i].id}'), onStore: list[i].storeId == null ? null : () => context.push('/store/${list[i].storeId}')));
          },
        )),
      ]),
    );
  }
}
