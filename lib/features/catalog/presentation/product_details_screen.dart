import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../models/product.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key, required this.id});
  final String id;
  @override ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _galleryIndex = 0;
  String? _variantId;

  @override Widget build(BuildContext context) {
    final state = ref.watch(productProvider(widget.id));
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('تفاصيل المنتج'), centerTitle: true),
      body: state.when(loading: () => const SpikeLoading(), error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(productProvider(widget.id))), data: (product) => product == null ? const SpikeEmptyState(message: 'المنتج غير متاح حالياً') : _body(context, product)),
    );
  }

  Widget _body(BuildContext context, ProductModel product) {
    final variants = product.variants;
    final selected = variants.firstWhere((v) => v.id == _variantId, orElse: () => product.cheapestVariant ?? (variants.isNotEmpty ? variants.first : const ProductVariant(id: '', title: '', price: 0, stock: 0)));
    _variantId ??= selected.id.isEmpty ? null : selected.id;
    final images = product.images.isNotEmpty ? product.images : [if (product.imageUrl != null) product.imageUrl!];
    final old = selected.originalPrice;
    final discount = old != null && old > selected.price && selected.price > 0 ? ((old - selected.price) / old * 100).round() : 0;

    return Stack(children: [
      ListView(padding: const EdgeInsets.only(bottom: 92), children: [
        SizedBox(height: 330, child: PageView.builder(itemCount: images.isEmpty ? 1 : images.length, onPageChanged: (i) => setState(() => _galleryIndex = i), itemBuilder: (_, i) => Container(color: Colors.white, alignment: Alignment.center, child: images.isEmpty ? const Icon(Icons.image_outlined, size: 60, color: Colors.black26) : CachedNetworkImage(imageUrl: images[i], fit: BoxFit.contain, width: double.infinity)))),
        if (images.length > 1) Padding(padding: const EdgeInsets.only(top: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(images.length, (i) => Container(width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(shape: BoxShape.circle, color: i == _galleryIndex ? Colors.black45 : Colors.black12))))),
        _block(children: [
          if (product.storeId != null) TextButton.icon(onPressed: () => context.push('/store/${product.storeId}'), icon: const Icon(LucideIcons.store, size: 17, color: Colors.black), label: Text(product.storeName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700))),
          Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF5B400)), const SizedBox(width: 4), Text((product.reviewCount > 0 && product.rating > 0 ? product.rating : 4.5).toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)), if (product.reviewCount > 0) Text(' (${product.reviewCount} تقييم)', style: const TextStyle(color: Colors.black54))]),
          const SizedBox(height: 10),
          Row(children: [Text(_money(selected.price, selected.currency), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), if (old != null && old > selected.price) ...[const SizedBox(width: 8), Text(_money(old, selected.currency), style: const TextStyle(fontSize: 11, color: Colors.red, decoration: TextDecoration.lineThrough)), const SizedBox(width: 8), Text('خصم $discount%', style: const TextStyle(color: spikeRed, fontWeight: FontWeight.w700))]]),
          const SizedBox(height: 8),
          Row(children: [Icon(selected.stock > 0 ? LucideIcons.checkCircle2 : LucideIcons.xCircle, size: 16), const SizedBox(width: 6), Text(selected.stock > 0 ? 'متوفر — ${selected.stock} قطعة' : 'غير متوفر حالياً')]),
        ]),
        if (variants.length > 1) _block(children: [const Text('اختر الخيار', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)), const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: variants.map((variant) => ChoiceChip(label: Text('${variant.title}  ${_money(variant.price, variant.currency)}'), selected: variant.id == selected.id, onSelected: (_) => setState(() => _variantId = variant.id))).toList())]),
        _block(children: [const Text('التوصيل', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(LucideIcons.mapPin, size: 20), title: const Text('اختر عنوان التوصيل'), trailing: const Text('اختيار', style: TextStyle(decoration: TextDecoration.underline)))]),
        _block(children: [const Text('تفاصيل المنتج', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text((product.description ?? '').trim().isEmpty ? 'لا توجد تفاصيل إضافية لهذا المنتج حالياً.' : product.description!), if (product.returnable) const Padding(padding: EdgeInsets.only(top: 8), child: Text('هذا المنتج قابل للإرجاع حسب سياسة المتجر.', style: TextStyle(fontWeight: FontWeight.w600)))]),
      ]),
      Positioned(left: 0, right: 0, bottom: 0, child: SafeArea(top: false, child: Container(padding: const EdgeInsets.fromLTRB(17, 10, 17, 10), color: Colors.white, child: Row(children: [
        Expanded(child: Text(_money(selected.price, selected.currency), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), onPressed: selected.id.isEmpty || selected.stock <= 0 ? null : () async { try { await ref.read(cartRepositoryProvider).add(variantId: selected.id); if (context.mounted) showSpikeToast(context, 'تمت إضافة المنتج إلى السلة'); } catch (e) { if (context.mounted) showSpikeToast(context, e.toString()); } }, icon: const Icon(LucideIcons.shoppingBag, size: 18), label: Text(selected.stock <= 0 ? 'غير متوفر' : 'إضافة إلى السلة')),
      ])))),
    ]);
  }

  Widget _block({required List<Widget> children}) => Container(margin: const EdgeInsets.fromLTRB(17, 10, 17, 0), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: spikePanel, borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));

  String _money(double amount, String currency) {
    final code = currency.toUpperCase();
    if (code == 'USD') return '\$${amount.toStringAsFixed(2)}';
    if (code == 'SAR') return '${amount.toStringAsFixed(2)} ر.س';
    if (code.startsWith('YER')) return '${amount.round()} ر.ي';
    return '${amount.toStringAsFixed(2)} $code';
  }
}
