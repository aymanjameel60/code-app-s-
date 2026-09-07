import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
  String? _quotedAddressId, _quotedVariantId;
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider(widget.id));
    return Scaffold(body: SafeArea(child: state.when(
      loading: () => const SpikeLoading(),
      error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(productProvider(widget.id))),
      data: (p) => p == null ? const SpikeEmptyState(message: 'المنتج غير متاح حالياً') : _body(context, p),
    )));
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

    return Stack(children: [
      ListView(padding: const EdgeInsets.only(bottom: 96), children: [
        Stack(children: [
          SizedBox(height: 350, child: PageView.builder(
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: (i) => setState(() => _galleryIndex = i),
            itemBuilder: (_, i) => Container(
              color: Theme.of(context).colorScheme.surface,
              alignment: Alignment.center,
              child: images.isEmpty
                  ? Icon(LucideIcons.image, size: 60, color: mutedIcon)
                  : CachedNetworkImage(imageUrl: images[i], fit: BoxFit.contain, width: double.infinity, errorWidget: (_, __, ___) => Icon(LucideIcons.image, size: 60, color: mutedIcon)),
            ),
          )),
          Positioned(top: SpikeSpacing.md, right: SpikeSpacing.page, child: _round(LucideIcons.arrowRight, () => context.canPop() ? context.pop() : context.go('/'))),
          Positioned(top: SpikeSpacing.md, left: SpikeSpacing.page, child: _round(LucideIcons.heart, _toggleFavorite, active: _favorite, busy: _favoriteBusy)),
          if (discount > 0) Positioned(bottom: SpikeSpacing.lg, right: SpikeSpacing.page, child: Container(padding: const EdgeInsets.symmetric(horizontal: SpikeSpacing.md, vertical: SpikeSpacing.sm), decoration: BoxDecoration(color: spikeRed, borderRadius: BorderRadius.circular(13)), child: Text('-$discount%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
        ]),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: SpikeSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: i == _galleryIndex ? 17 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: SpikeSpacing.xs / 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: i == _galleryIndex ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: .12),
                  ),
                ),
              ),
            ),
          ),
        _block(children: [
          if (product.storeId != null) InkWell(onTap: () => context.push('/store/${product.storeId}'), child: Row(children: [const Icon(LucideIcons.store, size: 16), const SizedBox(width: SpikeSpacing.sm), Expanded(child: Text(product.storeName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))), const Icon(LucideIcons.chevronLeft, size: 16)])),
          if (product.storeId != null) const SizedBox(height: SpikeSpacing.md),
          Text(product.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.45)),
          const SizedBox(height: SpikeSpacing.sm),
          Row(children: [const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF5B400)), const SizedBox(width: SpikeSpacing.xs), Text(product.reviewCount > 0 && product.rating > 0 ? product.rating.toStringAsFixed(1) : '—', style: const TextStyle(fontWeight: FontWeight.w800)), if (product.reviewCount > 0) Text('  (${product.reviewCount} تقييم)', style: const TextStyle(fontSize: 11, color: spikeMuted))]),
          const SizedBox(height: SpikeSpacing.md),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(_money(selected.price, selected.currency), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), if (old != null && old > selected.price) ...[const SizedBox(width: SpikeSpacing.sm), Text(_money(old, selected.currency), style: const TextStyle(fontSize: 11, color: spikeRed, decoration: TextDecoration.lineThrough))]]),
          const SizedBox(height: SpikeSpacing.sm),
          Row(children: [Icon(selected.stock > 0 ? LucideIcons.checkCircle2 : LucideIcons.xCircle, size: 16, color: selected.stock > 0 ? Colors.green : spikeRed), const SizedBox(width: SpikeSpacing.sm), Expanded(child: Text(selected.stock > 0 ? (selected.stock <= 5 ? 'متوفر — تبقى ${selected.stock} فقط' : 'متوفر في المخزون') : 'غير متوفر حالياً', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))]),
        ]),
        if (variants.length > 1) _block(children: [
          const Text('اختر الخيار', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: SpikeSpacing.md),
          Wrap(
            spacing: SpikeSpacing.sm,
            runSpacing: SpikeSpacing.sm,
            children: variants.map((v) => ChoiceChip(
              label: Text(v.title.isEmpty ? _money(v.price, v.currency) : v.title),
              selected: v.id == selected.id,
              onSelected: (_) => setState(() {
                _variantId = v.id;
                _deliveryQuote = null;
                _quotedVariantId = null;
              }),
            )).toList(),
          ),
        ]),
        _deliveryBlock(context, addresses, selected),
        _block(children: [const Text('تفاصيل المنتج', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)), const SizedBox(height: SpikeSpacing.sm), Text((product.description ?? '').trim().isEmpty ? 'لا توجد تفاصيل إضافية لهذا المنتج حالياً.' : product.description!, style: const TextStyle(fontSize: 12, height: 1.7)), if (product.returnable) const Padding(padding: EdgeInsets.only(top: SpikeSpacing.md), child: Row(children: [Icon(LucideIcons.rotateCcw, size: 16), SizedBox(width: SpikeSpacing.sm), Expanded(child: Text('هذا المنتج قابل للإرجاع حسب سياسة المتجر.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)))]))]),
        _reviewsBlock(product),
      ]),
      Positioned(left: 0, right: 0, bottom: 0, child: SafeArea(top: false, child: Container(padding: const EdgeInsets.fromLTRB(SpikeSpacing.page, SpikeSpacing.sm, SpikeSpacing.page, SpikeSpacing.md), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .08)))), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [const Text('السعر', style: TextStyle(fontSize: 9, color: spikeMuted)), Text(_money(selected.price, selected.currency), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))])), SizedBox(height: 48, child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: spikeRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpikeRadius.control))), onPressed: selected.id.isEmpty || selected.stock <= 0 ? null : () async { try { await ref.read(cartRepositoryProvider).add(variantId: selected.id); ref.invalidate(cartCountProvider); if (context.mounted) showSpikeToast(context, 'تمت إضافة المنتج إلى السلة'); } catch (e) { if (context.mounted) showSpikeToast(context, e.toString()); } }, icon: const Icon(LucideIcons.shoppingBag, size: 18), label: Text(selected.stock <= 0 ? 'غير متوفر' : 'إضافة إلى السلة', style: const TextStyle(fontWeight: FontWeight.w800))))])))),
    ]);
  }

  Widget _reviewsBlock(ProductModel product) => _block(children: [
    Row(children: [
      const Expanded(child: Text('تقييمات العملاء', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
      if (product.reviewCount > 0) Text('${product.rating.toStringAsFixed(1)} / 5', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
    ]),
    const SizedBox(height: SpikeSpacing.md),
    FutureBuilder<List<Map<String, dynamic>>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.symmetric(vertical: SpikeSpacing.md), child: LinearProgressIndicator(minHeight: 2));
        if (snapshot.hasError) return const Text('تعذر تحميل التقييمات حالياً.', style: TextStyle(fontSize: 11, color: spikeMuted));
        final reviews = snapshot.data ?? const [];
        if (reviews.isEmpty) return const Text('لا توجد تقييمات لهذا المنتج بعد.', style: TextStyle(fontSize: 11, color: spikeMuted));
        return Column(children: [
          for (final review in reviews.take(5)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SpikeSpacing.md),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(SpikeRadius.control)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${review['name'] ?? 'عميل'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                  Row(children: [const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5B400)), const SizedBox(width: SpikeSpacing.xs), Text('${review['rating'] ?? '—'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))]),
                ]),
                if ('${review['comment'] ?? ''}'.trim().isNotEmpty) ...[
                  const SizedBox(height: SpikeSpacing.sm),
                  Text('${review['comment']}', style: const TextStyle(fontSize: 11, height: 1.6)),
                ],
              ]),
            ),
            const SizedBox(height: SpikeSpacing.sm),
          ],
        ]);
      },
    ),
  ]);

  Widget _round(IconData icon, VoidCallback onTap, {bool active = false, bool busy = false}) => Material(
    color: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : Colors.white,
    shape: const CircleBorder(),
    elevation: 1,
    child: InkWell(onTap: busy ? null : onTap, customBorder: const CircleBorder(), child: SizedBox(width: 40, height: 40, child: busy ? const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, size: 20, color: active ? spikeRed : Theme.of(context).colorScheme.onSurface))),
  );

  Widget _deliveryBlock(BuildContext context, AsyncValue<List<AddressModel>> addresses, ProductVariant selected) => _block(children: [
    const Text('التوصيل', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)), const SizedBox(height: SpikeSpacing.sm),
    addresses.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (_, __) => Row(children: [const Expanded(child: Text('أضف عنواناً لمعرفة تكلفة التوصيل.')), TextButton(onPressed: () => context.push('/addresses'), child: const Text('العناوين'))]),
      data: (list) {
        if (list.isEmpty) return ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(LucideIcons.mapPin, size: 20), title: const Text('لا يوجد عنوان محفوظ'), trailing: TextButton(onPressed: () => context.push('/address-form'), child: const Text('إضافة')));
        final active = list.firstWhere((a) => a.isActive, orElse: () => list.first);
        final stale = _quotedAddressId != active.id || _quotedVariantId != selected.id;
        if (stale && !_quoting && selected.id.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuote(active.id, selected.id));
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(LucideIcons.mapPin, size: 20), title: Text(active.label.isEmpty ? active.cityName : active.label, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${active.cityName} • ${active.addressLine}', maxLines: 1, overflow: TextOverflow.ellipsis), trailing: TextButton(onPressed: () => context.push('/addresses'), child: const Text('تغيير'))),
          if (_quoting) const LinearProgressIndicator(minHeight: 2),
          if (!_quoting && _deliveryQuote != null) Container(padding: const EdgeInsets.all(SpikeSpacing.md), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(SpikeRadius.control)), child: Row(children: [const Icon(LucideIcons.truck, size: 18), const SizedBox(width: SpikeSpacing.sm), const Expanded(child: Text('تكلفة التوصيل التقديرية')), Text('${_deliveryQuote!.shippingYerOld.round()} ر.ي قديم', style: const TextStyle(fontWeight: FontWeight.w800))])),
        ]);
      },
    ),
  ]);

  Future<void> _loadQuote(String addressId, String variantId) async {
    if (_quoting) return;
    setState(() => _quoting = true);
    try {
      final q = await ref.read(commerceRepositoryProvider).quote(addressId: addressId, variantIds: [variantId]);
      if (!mounted) return;
      setState(() { _deliveryQuote = q; _quotedAddressId = addressId; _quotedVariantId = variantId; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _deliveryQuote = null; _quotedAddressId = addressId; _quotedVariantId = variantId; });
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  Widget _block({required List<Widget> children}) => Container(margin: const EdgeInsets.fromLTRB(SpikeSpacing.page, SpikeSpacing.md, SpikeSpacing.page, 0), padding: const EdgeInsets.all(SpikeSpacing.lg), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : spikePanel, borderRadius: BorderRadius.circular(SpikeRadius.card)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));

  String _money(double amount, String currency) {
    final c = currency.toUpperCase();
    if (c == 'USD') return '\$${amount.toStringAsFixed(2)}';
    if (c == 'SAR') return '${amount.toStringAsFixed(2)} ر.س';
    if (c.startsWith('YER')) return '${amount.round()} ر.ي';
    if (c == 'TRY') return '${amount.toStringAsFixed(2)} ₺';
    return '${amount.toStringAsFixed(2)} $c';
  }
}
