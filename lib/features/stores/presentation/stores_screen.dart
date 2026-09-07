import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class StoresScreen extends ConsumerStatefulWidget {
  const StoresScreen({super.key});
  @override ConsumerState<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends ConsumerState<StoresScreen> {
  String _query = '';
  String _sort = 'relevance';
  double _minRating = 0;

  void _showSort() {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: Padding(padding: SpikeSpacing.sheet, child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.only(bottom: SpikeSpacing.sm), child: Text('الترتيب حسب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
      for (final option in const [('relevance','الأكثر صلة'),('rating','الأعلى تقييماً'),('reviews','الأكثر مراجعات'),('name','الاسم أبجدياً')])
        ListTile(contentPadding: EdgeInsets.zero, title: Text(option.$2), trailing: _sort == option.$1 ? const Icon(Icons.check, color: spikeRed) : null, onTap: () { setState(() => _sort = option.$1); Navigator.pop(context); }),
    ]))));
  }

  void _showFilter() {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (context) => StatefulBuilder(builder: (context, setLocal) => SafeArea(child: Padding(
      padding: SpikeSpacing.sheet,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('فلترة المتاجر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: SpikeSpacing.lg),
        const Text('التقييم', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: SpikeSpacing.sm),
        Wrap(spacing: SpikeSpacing.sm, runSpacing: SpikeSpacing.sm, children: [
          for (final r in const [0.0, 4.0, 4.5])
            ChoiceChip(label: Text(r == 0 ? 'الكل' : '${r.toString()}+'), selected: _minRating == r, onSelected: (_) { setLocal(() => _minRating = r); setState(() => _minRating = r); }),
        ]),
        const SizedBox(height: SpikeSpacing.lg),
        SizedBox(height: 48, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: spikeRed), onPressed: () => Navigator.pop(context), child: const Text('تطبيق الفلتر'))),
      ]),
    ))));
  }

  @override Widget build(BuildContext context) {
    final storesState = ref.watch(storesProvider);
    final productsState = ref.watch(allProductsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('المتاجر'), centerTitle: true, actions: [Padding(padding: const EdgeInsetsDirectional.only(end: SpikeSpacing.sm), child: TextButton(onPressed: _showSort, child: const Text('ترتيب حسب')))]),
      body: Column(children: [
        Padding(
          padding: SpikeSpacing.pageHorizontal,
          child: Row(children: [
            Expanded(child: SizedBox(height: 46, child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: const InputDecoration(hintText: 'البحث عن متجر', prefixIcon: Icon(Icons.search)),
            ))),
            const SizedBox(width: SpikeSpacing.sm),
            SizedBox(width: 46, height: 46, child: IconButton.filledTonal(onPressed: _showFilter, icon: const Icon(Icons.tune))),
          ]),
        ),
        const SizedBox(height: SpikeSpacing.md),
        Expanded(child: storesState.when(
          loading: () => const SpikeLoading(),
          error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(storesProvider)),
          data: (stores) {
            final allProducts = productsState.valueOrNull ?? const [];
            final q = _query.toLowerCase();
            final list = stores.where((s) {
              final matchesQuery = q.isEmpty || s.name.toLowerCase().contains(q) || allProducts.any((p) => p.storeId == s.id && (p.categoryName ?? '').toLowerCase().contains(q));
              return matchesQuery && s.rating >= _minRating;
            }).toList();
            if (_sort == 'name') list.sort((a, b) => a.name.compareTo(b.name));
            if (_sort == 'rating') list.sort((a, b) => b.rating.compareTo(a.rating));
            if (_sort == 'reviews') list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
            if (list.isEmpty) return const SpikeEmptyState(message: 'لا توجد متاجر مطابقة للفلتر');

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(storesProvider);
                ref.invalidate(allProductsProvider);
                await ref.read(storesProvider.future);
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: SpikeSpacing.pageList,
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: SpikeSpacing.md),
                itemBuilder: (context, i) {
                  final store = list[i];
                  return InkWell(
                    onTap: () => context.push('/store/${store.id}'),
                    borderRadius: BorderRadius.circular(SpikeRadius.card),
                    child: Container(
                      padding: SpikeSpacing.card,
                      decoration: BoxDecoration(color: dark ? spikeDarkPanel : spikePanel, borderRadius: BorderRadius.circular(SpikeRadius.card)),
                      child: Row(children: [
                        Container(width: 68, height: 68, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(SpikeRadius.control)), child: store.logoUrl == null ? const Icon(Icons.storefront_outlined) : CachedNetworkImage(imageUrl: store.logoUrl!, fit: BoxFit.contain, errorWidget: (_, __, ___) => const Icon(Icons.storefront_outlined))),
                        const SizedBox(width: SpikeSpacing.md),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(store.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: SpikeSpacing.sm),
                          Row(children: [
                            const Icon(Icons.star, size: 15, color: Colors.amber),
                            const SizedBox(width: SpikeSpacing.xs),
                            Text(store.reviewCount > 0 ? store.rating.toStringAsFixed(1) : '—', style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(store.reviewCount > 0 ? ' (${store.reviewCount} تقييم)' : ' لا توجد تقييمات بعد', style: Theme.of(context).textTheme.bodySmall),
                          ]),
                        ])),
                        const Icon(Icons.arrow_back),
                      ]),
                    ),
                  );
                },
              ),
            );
          },
        )),
      ]),
    );
  }
}
