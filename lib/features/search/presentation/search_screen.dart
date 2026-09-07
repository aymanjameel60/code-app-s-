import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
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
  @override void initState() { super.initState(); _query = widget.initialQuery.trim(); }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final state = ref.watch(allProductsProvider);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('البحث'), centerTitle: true),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 0, 17, 10),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: InputDecoration(
              hintText: 'ابحث عن المنتجات ...', filled: true, fillColor: spikeField, prefixIcon: const Icon(Icons.search),
              suffixIcon: PopupMenuButton<String>(initialValue: _sort, onSelected: (v) => setState(() => _sort = v), itemBuilder: (_) => const [PopupMenuItem(value: 'relevance', child: Text('الأكثر صلة')), PopupMenuItem(value: 'price-low', child: Text('السعر الأقل')), PopupMenuItem(value: 'price-high', child: Text('السعر الأعلى')), PopupMenuItem(value: 'rating', child: Text('الأعلى تقييماً'))]),
              border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(22))),
            ),
          ),
        ),
        Expanded(
          child: state.when(
            loading: () => const SpikeLoading(),
            error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(allProductsProvider)),
            data: (products) {
              final q = _query.toLowerCase();
              final list = products.where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.storeName.toLowerCase().contains(q) || (p.categoryName ?? '').toLowerCase().contains(q)).toList();
              if (_sort == 'price-low') list.sort((a, b) => a.price.compareTo(b.price));
              if (_sort == 'price-high') list.sort((a, b) => b.price.compareTo(a.price));
              if (_sort == 'rating') list.sort((a, b) => b.rating.compareTo(a.rating));
              if (list.isEmpty) return const SpikeEmptyState(message: 'لا توجد نتائج مطابقة');
              return GridView.builder(padding: const EdgeInsets.all(17), itemCount: list.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11, mainAxisExtent: 246), itemBuilder: (context, i) => SpikeProductCard(product: list[i], onTap: () => context.push('/product/${list[i].id}')));
            },
          ),
        ),
      ]),
    );
  }
}
