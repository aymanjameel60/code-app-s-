import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});
  final String initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialQuery);
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(allProductsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final field = dark ? spikeDarkPanel : const Color(0xFFE7E7E7);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 8, 17, 8),
            child: Row(children: [
              SizedBox(
                width: 50,
                height: 40,
                child: Material(
                  color: dark ? spikeDarkPanel : const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: () => context.canPop() ? context.pop() : context.go('/'),
                    borderRadius: BorderRadius.circular(22),
                    child: const Icon(LucideIcons.arrowRight, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Container(
                  height: 39,
                  decoration: BoxDecoration(color: field, borderRadius: BorderRadius.circular(22)),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن المنتجات ...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBDBDBD)),
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(LucideIcons.x, size: 18),
                              onPressed: () {
                                _controller.clear();
                                setState(() => _query = '');
                              },
                            ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          Expanded(
            child: state.when(
              loading: () => const SpikeLoading(),
              error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(allProductsProvider)),
              data: (products) {
                if (_query.isEmpty) {
                  return const _SearchEmpty();
                }
                final q = _query.toLowerCase();
                final list = products.where((p) => p.name.toLowerCase().contains(q) || p.storeName.toLowerCase().contains(q) || (p.categoryName ?? '').toLowerCase().contains(q)).toList();
                if (list.isEmpty) {
                  return const _SearchEmpty(title: 'لا توجد نتائج', subtitle: 'جرّب كتابة اسم منتج أو متجر آخر.');
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(17, 10, 17, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = list[i];
                    return InkWell(
                      onTap: () => context.push('/product/${p.id}'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 72),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(color: dark ? spikeDarkPanel : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
                        child: Row(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: p.imageUrl == null || p.imageUrl!.isEmpty
                                  ? Container(color: spikePanel, child: const Icon(LucideIcons.image, size: 20))
                                  : CachedNetworkImage(imageUrl: p.imageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: spikePanel, child: const Icon(LucideIcons.image, size: 20))),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 3),
                              Text(p.storeName.isNotEmpty ? p.storeName : (p.categoryName ?? ''), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: spikeMuted)),
                            ]),
                          ),
                          const Icon(LucideIcons.chevronLeft, size: 18),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty({this.title = 'ابحث عن منتج أو متجر', this.subtitle = 'اكتب اسم المنتج أو الفئة أو المتجر.'});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.search, size: 28),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: spikeMuted)),
          ]),
        ),
      );
}
