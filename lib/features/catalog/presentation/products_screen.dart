import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../widgets/product_card.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key, this.categoryId, this.collectionId, this.title = 'المنتجات'});

  final String? categoryId;
  final String? collectionId;
  final String title;

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _sort = 'relevance';
  String? _selectedCategoryId;
  String _selectedCategoryName = 'الكل';
  final Set<String> _favoriteBusy = {};

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    if (widget.categoryId != null && widget.title.trim().isNotEmpty && widget.title != 'المنتجات') {
      _selectedCategoryName = widget.title;
    }
  }

  double _discount(ProductModel p) {
    final original = p.originalPrice ?? 0;
    return original > p.price && original > 0 ? (original - p.price) / original : 0;
  }

  void _showSort() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF6F6F6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 20, 17, 25),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('الترتيب حسب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  for (final option in const [
                    ('relevance', 'الأكثر صلة'),
                    ('price-low', 'السعر: من الأقل للأعلى'),
                    ('price-high', 'السعر: من الأعلى للأقل'),
                    ('rating', 'الأعلى تقييماً'),
                    ('discount', 'الأعلى خصماً'),
                  ])
                    InkWell(
                      onTap: () {
                        setState(() => _sort = option.$1);
                        Navigator.pop(sheetContext);
                      },
                      child: Container(
                        height: 48,
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5)))),
                        child: Row(children: [
                          Expanded(child: Text(option.$2, style: const TextStyle(fontSize: 12))),
                          Radio<String>(value: option.$1, groupValue: _sort, onChanged: (_) {
                            setState(() => _sort = option.$1);
                            Navigator.pop(sheetContext);
                          }),
                        ]),
                      ),
                    ),
                ],
              ),
              Positioned(
                top: -82,
                left: MediaQuery.sizeOf(context).width / 2 - 58,
                child: Material(
                  color: const Color(0xFFEEEEEE),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(sheetContext),
                    child: const SizedBox(width: 48, height: 48, child: Icon(LucideIcons.x, size: 20)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(ProductModel p) async {
    if (_favoriteBusy.contains(p.id)) return;
    setState(() => _favoriteBusy.add(p.id));
    final ids = ref.read(wishlistIdsProvider).valueOrNull ?? <String>{};
    final active = ids.contains(p.id);
    try {
      if (active) {
        await ref.read(engagementRepositoryProvider).removeWishlist(p.id);
      } else {
        await ref.read(engagementRepositoryProvider).addWishlist(p.id);
      }
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
      await ref.read(cartRepositoryProvider).add(variantId: variant.id, product: p);
      ref.invalidate(cartCountProvider);
      if (mounted) showSpikeToast(context, 'تمت إضافة المنتج إلى السلة');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    }
  }

  void _selectQuickCategory(String name, String? id) {
    setState(() {
      _selectedCategoryName = name;
      _selectedCategoryId = id;
    });
  }

  List<ProductModel> _filterAndSort(List<ProductModel> products) {
    var list = products.where((p) {
      if (_selectedCategoryName == 'الكل') return true;
      if (_selectedCategoryName == 'عروض') return _discount(p) > 0;
      if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
        return p.categoryId == _selectedCategoryId || p.categoryName == _selectedCategoryName;
      }
      return p.categoryName == _selectedCategoryName;
    }).toList();

    if (_sort == 'price-low') list.sort((a, b) => a.price.compareTo(b.price));
    if (_sort == 'price-high') list.sort((a, b) => b.price.compareTo(a.price));
    if (_sort == 'rating') list.sort((a, b) => b.rating.compareTo(a.rating));
    if (_sort == 'discount') list.sort((a, b) => _discount(b).compareTo(_discount(a)));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(wishlistIdsProvider).valueOrNull ?? <String>{};
    final unread = ref.watch(unreadNotificationsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final allProductsState = ref.watch(allProductsProvider);
    final scopedState = ref.watch(productsProvider((widget.categoryId, widget.collectionId)));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final displayTitle = widget.collectionId != null ? widget.title : 'المنتجات';
    final productsState = widget.collectionId != null ? scopedState : allProductsState;

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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => context.canPop() ? context.pop() : context.go('/'),
                          child: const Icon(LucideIcons.arrowRight, size: 23),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                        IconButton(onPressed: () => context.push('/notifications'), icon: const Icon(LucideIcons.bell, size: 22)),
                        if (unread > 0)
                          Positioned(
                            left: -2,
                            top: -1,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: spikeRed, shape: BoxShape.circle),
                              child: Text(unread > 99 ? '99+' : '$unread', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ]),
              ),
              SizedBox(
                height: 60,
                child: Stack(alignment: Alignment.centerRight, children: [
                  SizedBox(width: double.infinity, child: Text(displayTitle, textAlign: TextAlign.right, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700))),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 50,
                      height: 40,
                      child: Material(
                        color: dark ? spikeDarkPanel : const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          onTap: _showSort,
                          borderRadius: BorderRadius.circular(22),
                          child: const Icon(LucideIcons.arrowUpDown, size: 21),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(17, 0, 17, 14),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SizedBox(
              height: 45,
              child: categoriesState.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) {
                  final enabled = categories.where((c) => c.enabled && c.name.trim().isNotEmpty).toList();
                  final chips = <({String name, String? id})>[
                    (name: 'الكل', id: null),
                    ...enabled.map((CategoryModel c) => (name: c.name, id: c.id)),
                    (name: 'عروض', id: null),
                  ];
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final item = chips[i];
                      final active = _selectedCategoryName == item.name;
                      return InkWell(
                        onTap: () => _selectQuickCategory(item.name, item.id),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? (dark ? Colors.white : const Color(0xFF111111)) : (dark ? const Color(0xFF24252A) : const Color(0xFFE8E8E8)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(item.name, style: TextStyle(fontSize: 12, color: active ? (dark ? const Color(0xFF111111) : Colors.white) : null)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: productsState.when(
              loading: () => const SpikeLoading(),
              error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () {
                if (widget.collectionId != null) {
                  ref.invalidate(productsProvider((widget.categoryId, widget.collectionId)));
                } else {
                  ref.invalidate(allProductsProvider);
                }
              }),
              data: (products) {
                final list = widget.collectionId != null ? products : _filterAndSort(products);
                if (widget.collectionId != null) {
                  if (_sort == 'price-low') list.sort((a, b) => a.price.compareTo(b.price));
                  if (_sort == 'price-high') list.sort((a, b) => b.price.compareTo(a.price));
                  if (_sort == 'rating') list.sort((a, b) => b.rating.compareTo(a.rating));
                  if (_sort == 'discount') list.sort((a, b) => _discount(b).compareTo(_discount(a)));
                }
                if (list.isEmpty) return const SpikeEmptyState(message: 'لا توجد منتجات في هذا القسم حالياً');

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(17, 4, 17, 15),
                  itemCount: list.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 11,
                    mainAxisSpacing: 11,
                    mainAxisExtent: 246,
                  ),
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
            ),
          ),
        ]),
      ),
    );
  }
}
