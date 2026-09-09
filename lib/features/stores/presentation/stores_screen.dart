import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class StoresScreen extends ConsumerStatefulWidget {
  const StoresScreen({super.key});
  @override
  ConsumerState<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends ConsumerState<StoresScreen> {
  String _query = '';
  String _sort = 'relevance';

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
              const Expanded(child: Text('الترتيب حسب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
              IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(LucideIcons.x, size: 20)),
            ]),
            const SizedBox(height: 12),
            for (final option in const [
              ('relevance', 'الأكثر صلة'),
              ('rating', 'الأعلى تقييماً'),
              ('reviews', 'الأكثر مراجعات'),
              ('name', 'الاسم أبجدياً'),
            ])
              _SheetOption(
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

  @override
  Widget build(BuildContext context) {
    final storesState = ref.watch(storesProvider);
    final productsState = ref.watch(allProductsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 8, 17, 0),
            child: Column(children: [
              SizedBox(
                height: 92,
                child: Stack(children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 50,
                      height: 40,
                      child: Material(
                        color: dark ? spikeDarkPanel : const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(borderRadius: BorderRadius.circular(22), onTap: () => context.canPop() ? context.pop() : context.go('/profile'), child: const Icon(LucideIcons.arrowRight, size: 23)),
                      ),
                    ),
                  ),
                ]),
              ),
              SizedBox(
                height: 60,
                child: Stack(alignment: Alignment.centerRight, children: [
                  const Text('المتاجر', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 50,
                      height: 40,
                      child: Material(
                        color: dark ? spikeDarkPanel : const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(borderRadius: BorderRadius.circular(22), onTap: _showSort, child: const Icon(LucideIcons.arrowUpDown, size: 18)),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Container(
              height: 39,
              decoration: BoxDecoration(color: dark ? spikeDarkPanel : spikeField, borderRadius: BorderRadius.circular(22)),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: const InputDecoration(
                  hintText: 'البحث عن متجر',
                  prefixIcon: Icon(LucideIcons.search, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: storesState.when(
              loading: () => const SpikeLoading(),
              error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(storesProvider)),
              data: (stores) {
                final allProducts = productsState.valueOrNull ?? const [];
                final q = _query.toLowerCase();
                final list = stores.where((s) {
                  if (q.isEmpty) return true;
                  return s.name.toLowerCase().contains(q) || (s.categoryName ?? '').toLowerCase().contains(q) || allProducts.any((p) => p.storeId == s.id && (p.categoryName ?? '').toLowerCase().contains(q));
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
                    padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final store = list[i];
                      return InkWell(
                        onTap: () => context.push('/store/${store.id}'),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: BoxDecoration(color: dark ? spikeDarkPanel : spikePanel, borderRadius: BorderRadius.circular(24)),
                          clipBehavior: Clip.antiAlias,
                          child: Column(children: [
                            SizedBox(
                              height: 150,
                              width: double.infinity,
                              child: Stack(fit: StackFit.expand, children: [
                                store.bannerUrl == null
                                    ? Container(color: dark ? Colors.white10 : Colors.black12)
                                    : CachedNetworkImage(imageUrl: store.bannerUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: dark ? Colors.white10 : Colors.black12)),
                                Positioned(
                                  left: 10,
                                  top: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(16)),
                                    child: Row(children: [
                                      Text(store.reviewCount > 0 ? store.rating.toStringAsFixed(1) : '—', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black)),
                                      const SizedBox(width: 3),
                                      const Icon(LucideIcons.star, size: 14, color: Color(0xFFF5B400)),
                                    ]),
                                  ),
                                ),
                              ]),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 82),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEEEEEE))),
                                    child: store.logoUrl == null
                                        ? const Icon(LucideIcons.store, size: 22, color: Colors.black)
                                        : CachedNetworkImage(imageUrl: store.logoUrl!, fit: BoxFit.contain, errorWidget: (_, __, ___) => const Icon(LucideIcons.store, size: 22, color: Colors.black)),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Row(children: [
                                        Flexible(child: Text(store.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                                        if (store.isVerified) ...[const SizedBox(width: 4), const Icon(LucideIcons.badgeCheck, size: 14)],
                                      ]),
                                      const SizedBox(height: 3),
                                      Text(store.categoryName ?? '', style: const TextStyle(fontSize: 9, color: spikeMuted)),
                                    ]),
                                  ),
                                  const Icon(LucideIcons.arrowLeft, size: 20, color: spikeMuted),
                                ]),
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({required this.label, required this.selected, required this.onTap});
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
