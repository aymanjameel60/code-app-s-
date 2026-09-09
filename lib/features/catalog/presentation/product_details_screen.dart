import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../models/product.dart';
import '../../checkout/data/commerce_repository.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _galleryIndex = 0;
  String? _variantId;
  DeliveryQuote? _deliveryQuote;
  bool _quoting = false;
  bool _favorite = false;
  bool _favoriteBusy = false;
  String? _quotedAddressId;
  String? _quotedVariantId;
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = ref.read(engagementRepositoryProvider).productReviews(widget.id);
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    try {
      final ids = await ref.read(engagementRepositoryProvider).wishlistIds();
      if (mounted) setState(() => _favorite = ids.contains(widget.id));
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteBusy) return;
    setState(() => _favoriteBusy = true);
    try {
      if (_favorite) {
        await ref.read(engagementRepositoryProvider).removeWishlist(widget.id);
      } else {
        await ref.read(engagementRepositoryProvider).addWishlist(widget.id);
      }
      ref.invalidate(wishlistIdsProvider);
      ref.invalidate(favoritesProvider);
      if (!mounted) return;
      setState(() => _favorite = !_favorite);
      showSpikeToast(context, _favorite ? 'تمت إضافة المنتج إلى المفضلة' : 'تمت إزالة المنتج من المفضلة');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  Future<void> _shareProduct(ProductModel product, ProductVariant selected) async {
    final text = '${product.name}\n${_money(selected.price, selected.currency)}';
    try {
      await Share.share(text, subject: product.name);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) showSpikeToast(context, 'تم نسخ بيانات المنتج للمشاركة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider(widget.id));
    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const SpikeLoading(),
          error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(productProvider(widget.id))),
          data: (p) => p == null ? const SpikeEmptyState(message: 'المنتج غير متاح حالياً') : _body(context, p),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ProductModel product) {
    final variants = product.variants;
    final selected = variants.firstWhere(
      (v) => v.id == _variantId,
      orElse: () => product.cheapestVariant ?? (variants.isNotEmpty ? variants.first : const ProductVariant(id: '', title: '', price: 0, stock: 0)),
    );
    _variantId ??= selected.id.isEmpty ? null : selected.id;
    final images = product.images.isNotEmpty ? product.images : [if (product.imageUrl != null) product.imageUrl!];
    final old = selected.originalPrice;
    final discount = old != null && old > selected.price && selected.price > 0 ? ((old - selected.price) / old * 100).round() : 0;
    final addresses = ref.watch(addressesProvider);
    final mutedIcon = Theme.of(context).colorScheme.onSurface.withValues(alpha: .24);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final blockColor = dark ? const Color(0xFF17181B) : Colors.white;

    return Stack(children: [
      ListView(
        padding: const EdgeInsets.only(bottom: 105),
        children: [
          _TopBar(onBack: () => context.canPop() ? context.pop() : context.go('/')),
          SizedBox(
            height: 320,
            child: Stack(children: [
              PageView.builder(
                itemCount: images.isEmpty ? 1 : images.length,
                onPageChanged: (i) => setState(() => _galleryIndex = i),
                itemBuilder: (_, i) => Container(
                  color: blockColor,
                  alignment: Alignment.center,
                  child: images.isEmpty
                      ? Icon(LucideIcons.image, size: 60, color: mutedIcon)
                      : FractionallySizedBox(
                          widthFactor: .82,
                          heightFactor: .82,
                          child: CachedNetworkImage(
                            imageUrl: images[i],
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => Icon(LucideIcons.image, size: 60, color: mutedIcon),
                          ),
                        ),
                ),
              ),
              Positioned(top: 16, right: 18, child: _CircleAction(icon: LucideIcons.heart, active: _favorite, busy: _favoriteBusy, onTap: _toggleFavorite)),
              Positioned(top: 16, left: 18, child: _CircleAction(icon: LucideIcons.share2, onTap: () => _shareProduct(product, selected))),
              if (images.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 15,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: i == _galleryIndex ? 18 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: i == _galleryIndex ? Theme.of(context).colorScheme.onSurface : const Color(0xFFD4D4D4),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          _ReferenceBlock(
            children: [
              if (product.storeId != null)
                InkWell(
                  onTap: () => context.push('/store/${product.storeId}'),
                  child: Row(children: [
                    const Icon(LucideIcons.store, size: 17, color: spikeMuted),
                    const SizedBox(width: 6),
                    Expanded(child: Text(product.storeName, style: const TextStyle(fontSize: 11, color: spikeMuted))),
                    const Icon(LucideIcons.arrowLeft, size: 16, color: spikeMuted),
                  ]),
                ),
              if (product.storeId != null) const SizedBox(height: 7),
              Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.35)),
              const SizedBox(height: 14),
              Row(children: [
                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5B400)),
                const SizedBox(width: 4),
                Text(product.reviewCount > 0 && product.rating > 0 ? product.rating.toStringAsFixed(1) : '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                if (product.reviewCount > 0) Text(' (${product.reviewCount} تقييم)', style: const TextStyle(fontSize: 11, color: spikeMuted)),
              ]),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (old != null && old > selected.price) ...[
                    Text(_money(old, selected.currency), style: const TextStyle(fontSize: 11, color: spikeMuted, decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: 10),
                  ],
                  Text(_money(selected.price, selected.currency), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  if (discount > 0) ...[
                    const SizedBox(width: 10),
                    Text('خصم $discount%', style: const TextStyle(fontSize: 12, color: Color(0xFF2EAA49), fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
              const SizedBox(height: 11),
              Row(children: [
                Icon(selected.stock > 0 ? LucideIcons.checkCircle2 : LucideIcons.xCircle, size: 16, color: selected.stock > 0 ? const Color(0xFF218A39) : spikeRed),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selected.stock > 0 ? (selected.stock <= 5 ? 'متوفر — ${selected.stock} قطعة' : 'متوفر في المخزون') : 'غير متوفر حالياً',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected.stock > 0 ? const Color(0xFF218A39) : spikeRed),
                  ),
                ),
              ]),
            ],
          ),
          if (variants.length > 1)
            _ReferenceBlock(
              children: [
                const Text('اختر الخيار', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: variants.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 95,
                  ),
                  itemBuilder: (context, i) {
                    final v = variants[i];
                    final active = v.id == selected.id;
                    return InkWell(
                      onTap: () => setState(() {
                        _variantId = v.id;
                        _deliveryQuote = null;
                        _quotedVariantId = null;
                      }),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFFFFF9E9) : blockColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: active ? const Color(0xFFF5A900) : Theme.of(context).dividerColor, width: active ? 2 : 1),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(v.title.isEmpty ? 'الخيار' : v.title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active && dark ? Colors.black : null)),
                          const SizedBox(height: 6),
                          Text(_money(v.price, v.currency), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: active && dark ? Colors.black : null)),
                        ]),
                      ),
                    );
                  },
                ),
              ],
            ),
          _deliveryBlock(context, addresses, selected),
          if (product.storeId != null)
            _ReferenceBlock(
              children: [
                Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.store, size: 21),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('يباع بواسطة', style: TextStyle(fontSize: 9, color: spikeMuted)),
                      const SizedBox(height: 2),
                      Text(product.storeName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/store/${product.storeId}'),
                      icon: const Icon(LucideIcons.store, size: 16),
                      label: const Text('زيارة المتجر', style: TextStyle(fontSize: 10)),
                    ),
                  ),
                ]),
              ],
            ),
          _ReferenceBlock(
            children: [
              const Text('تفاصيل المنتج', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Text(
                (product.description ?? '').trim().isEmpty ? 'لا توجد تفاصيل إضافية لهذا المنتج حالياً.' : product.description!,
                style: TextStyle(fontSize: 13, height: 1.8, color: dark ? const Color(0xFFBBBBBB) : const Color(0xFF555555)),
              ),
              if (product.returnable)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Row(children: [
                    Icon(LucideIcons.rotateCcw, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text('هذا المنتج قابل للإرجاع حسب سياسة المتجر.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                  ]),
                ),
            ],
          ),
          _reviewsBlock(product),
        ],
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: SafeArea(
          top: false,
          child: Container(
            constraints: const BoxConstraints(minHeight: 82),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
            decoration: BoxDecoration(color: blockColor, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
            child: Row(children: [
              Expanded(child: Text(_money(selected.price, selected.currency), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF5B400),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFFE0E0E0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                  ),
                  onPressed: selected.id.isEmpty || selected.stock <= 0
                      ? null
                      : () async {
                          try {
                            await ref.read(cartRepositoryProvider).add(variantId: selected.id, product: product);
                            ref.invalidate(cartCountProvider);
                            if (context.mounted) showSpikeToast(context, 'تمت إضافة المنتج إلى السلة');
                          } catch (e) {
                            if (context.mounted) showSpikeToast(context, e.toString());
                          }
                        },
                  icon: const Icon(LucideIcons.shoppingBag, size: 18),
                  label: Text(selected.stock <= 0 ? 'غير متوفر' : 'إضافة إلى السلة', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _reviewsBlock(ProductModel product) => _ReferenceBlock(
        children: [
          Row(children: [
            const Expanded(child: Text('التقييمات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            if (product.reviewCount > 0) Text('${product.rating.toStringAsFixed(1)} / 5', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _reviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator(minHeight: 2);
              if (snapshot.hasError) return const Text('تعذر تحميل التقييمات حالياً.', style: TextStyle(fontSize: 11, color: spikeMuted));
              final reviews = snapshot.data ?? const [];
              if (reviews.isEmpty) return const Text('لا توجد تقييمات من المشترين بعد', style: TextStyle(fontSize: 11, color: spikeMuted));
              return Column(children: [
                for (final review in reviews.take(10)) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${review['name'] ?? 'عميل'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), const Text('مشتري موثّق', style: TextStyle(fontSize: 9, color: spikeMuted))])),
                        Row(children: [const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF5B400)), const SizedBox(width: 4), Text('${review['rating'] ?? '—'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]),
                      ]),
                      if ('${review['comment'] ?? ''}'.trim().isNotEmpty) ...[const SizedBox(height: 8), Text('${review['comment']}', style: const TextStyle(fontSize: 11, height: 1.6))],
                    ]),
                  ),
                  const SizedBox(height: 8),
                ],
              ]);
            },
          ),
        ],
      );

  Widget _deliveryBlock(BuildContext context, AsyncValue<List<AddressModel>> addresses, ProductVariant selected) => _ReferenceBlock(
        children: [
          const Text('التوصيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          addresses.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, __) => _DeliveryAddress(title: 'أضف عنواناً لمعرفة تكلفة التوصيل', action: 'العناوين', onTap: () => context.push('/addresses')),
            data: (list) {
              if (list.isEmpty) return _DeliveryAddress(title: 'لا يوجد عنوان محفوظ', action: 'إضافة', onTap: () => context.push('/address-form'));
              final active = list.firstWhere((a) => a.isActive, orElse: () => list.first);
              final stale = _quotedAddressId != active.id || _quotedVariantId != selected.id;
              if (stale && !_quoting && selected.id.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuote(active.id, selected.id));
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _DeliveryAddress(title: active.label.isEmpty ? '${active.cityName} - ${active.addressLine}' : '${active.label} - ${active.cityName}', action: 'تغيير', onTap: () => context.push('/addresses')),
                if (_quoting) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator(minHeight: 2)),
                if (!_quoting && _deliveryQuote != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(color: const Color(0xFFEFFAF1), borderRadius: BorderRadius.circular(13)),
                    child: Row(children: [
                      const Icon(LucideIcons.truck, size: 18, color: Color(0xFF218A39)),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('تكلفة التوصيل التقديرية', style: TextStyle(fontSize: 11, color: Color(0xFF218A39)))),
                      Text('${_deliveryQuote!.shippingYerOld.round()} ر.ي قديم', style: const TextStyle(fontSize: 11, color: Color(0xFF218A39), fontWeight: FontWeight.w700)),
                    ]),
                  ),
              ]);
            },
          ),
        ],
      );

  Future<void> _loadQuote(String addressId, String variantId) async {
    if (_quoting) return;
    setState(() => _quoting = true);
    try {
      final q = await ref.read(commerceRepositoryProvider).quote(addressId: addressId, variantIds: [variantId]);
      if (!mounted) return;
      setState(() {
        _deliveryQuote = q;
        _quotedAddressId = addressId;
        _quotedVariantId = variantId;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deliveryQuote = null;
        _quotedAddressId = addressId;
        _quotedVariantId = variantId;
      });
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  String _money(double amount, String currency) {
    final c = currency.toUpperCase();
    if (c == 'USD') return '\$${amount.toStringAsFixed(2)}';
    if (c == 'SAR') return '${amount.toStringAsFixed(2)} ر.س';
    if (c.startsWith('YER')) return '${amount.round()} ر.ي';
    if (c == 'TRY') return '${amount.toStringAsFixed(2)} ₺';
    return '${amount.toStringAsFixed(2)} $c';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
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
                    color: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(onTap: onBack, borderRadius: BorderRadius.circular(22), child: const Icon(LucideIcons.arrowRight, size: 23)),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 60, child: Align(alignment: Alignment.centerRight, child: Text('تفاصيل المنتج', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)))),
        ]),
      );
}

class _ReferenceBlock extends StatelessWidget {
  const _ReferenceBlock({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 9),
        padding: const EdgeInsets.all(18),
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF17181B) : Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap, this.active = false, this.busy = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool busy;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF24252A) : Colors.white,
        shape: CircleBorder(side: BorderSide(color: Theme.of(context).dividerColor)),
        child: InkWell(
          onTap: busy ? null : onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 35, height: 35, child: busy ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, size: 20, color: active ? spikeRed : Theme.of(context).colorScheme.onSurface)),
        ),
      );
}

class _DeliveryAddress extends StatelessWidget {
  const _DeliveryAddress({required this.title, required this.action, required this.onTap});
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(LucideIcons.mapPin, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
            Text(action, style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
          ]),
        ),
      );
}
