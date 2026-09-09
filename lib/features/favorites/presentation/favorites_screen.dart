import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../widgets/product_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  Future<void> _clearAll(BuildContext context, WidgetRef ref, List products) async {
    try {
      for (final p in products) {
        await ref.read(engagementRepositoryProvider).removeWishlist(p.id);
      }
      ref.invalidate(wishlistIdsProvider);
      ref.invalidate(favoritesProvider);
      if (context.mounted) showSpikeToast(context, 'تم إفراغ المفضلة');
    } catch (e) {
      if (context.mounted) showSpikeToast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoritesProvider);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const SpikeLoading(),
          error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(favoritesProvider)),
          data: (products) => Column(children: [
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
                    const Text('المفضلة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                    if (products.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(onPressed: () => _clearAll(context, ref, products), child: const Text('إفراغ المفضلة', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                      ),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: products.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(LucideIcons.heart, size: 38),
                        const SizedBox(height: 14),
                        const Text('المفضلة فارغة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('احفظ المنتجات التي أعجبتك لتجدها هنا بسرعة.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: spikeMuted)),
                        const SizedBox(height: 18),
                        SizedBox(height: 43, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: spikeRed, foregroundColor: Colors.white), onPressed: () => context.go('/'), child: const Text('استكشف المنتجات'))),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(wishlistIdsProvider);
                        ref.invalidate(favoritesProvider);
                        await ref.read(favoritesProvider.future);
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(17, 4, 17, 24),
                        itemCount: products.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11, mainAxisExtent: 246),
                        itemBuilder: (context, i) {
                          final p = products[i];
                          return SpikeProductCard(
                            product: p,
                            isFavorite: true,
                            onTap: () => context.push('/product/${p.id}'),
                            onStore: p.storeId == null ? null : () => context.push('/store/${p.storeId}'),
                            onFavorite: () async {
                              try {
                                await ref.read(engagementRepositoryProvider).removeWishlist(p.id);
                                ref.invalidate(wishlistIdsProvider);
                                ref.invalidate(favoritesProvider);
                                if (context.mounted) showSpikeToast(context, 'تمت إزالة المنتج من المفضلة');
                              } catch (e) {
                                if (context.mounted) showSpikeToast(context, e.toString());
                              }
                            },
                            onAdd: p.cheapestVariant == null
                                ? null
                                : () async {
                                    try {
                                      await ref.read(cartRepositoryProvider).add(variantId: p.cheapestVariant!.id, product: p);
                                      ref.invalidate(cartCountProvider);
                                      if (context.mounted) showSpikeToast(context, 'تمت إضافة المنتج إلى السلة');
                                    } catch (e) {
                                      if (context.mounted) showSpikeToast(context, e.toString());
                                    }
                                  },
                          );
                        },
                      ),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
