import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/providers.dart';
import '../../../core/media_url.dart';
import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../data/cart_repository.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _coupon = TextEditingController();
  CartSnapshot? _cart;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final c = await ref.read(cartRepositoryProvider).load();
      ref.invalidate(cartCountProvider);
      if (mounted) {
        setState(() {
          _cart = c;
          _coupon.text = c.couponCode ?? '';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _qty(CartItemModel item, int qty) async {
    try {
      final c = await ref.read(cartRepositoryProvider).update(variantId: item.variantId, quantity: qty);
      ref.invalidate(cartCountProvider);
      if (mounted) setState(() => _cart = c);
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    }
  }

  String _money(double value, String currency) {
    final rates = ref.watch(currencyRatesProvider).valueOrNull ?? const <String, double>{};
    return formatMoney(value, code: currency, rate: rates[currency.trim().toUpperCase()] ?? 1);
  }

  String _asset(String raw) => resolveMediaUrl(raw) ?? '';

  Future<void> _shareCart(CartSnapshot cart) async {
    final lines = cart.items.map((x) => '• ${x.productName} × ${x.quantity}').join('\n');
    await Share.share('حقيبة التسوق في Spike\n$lines');
  }

  void _openBanner(Map<String, dynamic> b) {
    final type = '${b['target_type'] ?? ''}';
    final id = '${b['target_id'] ?? ''}';
    final url = '${b['target_url'] ?? ''}';
    if (type == 'product' && id.isNotEmpty) {
      context.push('/product/$id');
    } else if (type == 'category' && id.isNotEmpty) {
      context.push('/products?category=$id&title=المنتجات');
    } else if (type == 'collection' && id.isNotEmpty) {
      context.push('/products?collection=$id&title=المنتجات');
    } else if (type == 'store' && id.isNotEmpty) {
      context.push('/store/$id');
    } else if (type == 'internal' && url.startsWith('/')) {
      context.push(url);
    }
  }

  Widget _banner() {
    final state = ref.watch(cartBannersProvider);
    return state.maybeWhen(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final b = items.first;
        final src = _asset('${b['image_url'] ?? ''}');
        if (src.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: InkWell(
            onTap: () => _openBanner(b),
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(src, width: double.infinity, height: 54, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Color _panel(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : spikePanel;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SafeArea(child: SpikeLoading());
    final cart = _cart;
    if (cart == null) return SafeArea(child: SpikeErrorState(message: _error ?? 'تعذر تحميل بيانات السلة', onRetry: _load));

    if (cart.items.isEmpty) {
      return SafeArea(
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(17, 8, 17, 0), child: _Title(onShare: () => _shareCart(cart))),
          const Expanded(child: _EmptyCart()),
        ]),
      );
    }

    final groups = <String, List<CartItemModel>>{};
    for (final item in cart.items) {
      (groups[item.storeName] ??= []).add(item);
    }
    String money(double v) => _money(v, cart.currencyCode);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      child: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(17, 8, 17, 12),
            children: [
              _Title(onShare: () => _shareCart(cart)),
              _banner(),
              for (final entry in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 6, 5, 10),
                  child: InkWell(
                    onTap: entry.value.first.storeId.isEmpty ? null : () => context.push('/store/${entry.value.first.storeId}'),
                    child: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                for (int i = 0; i < entry.value.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _Item(item: entry.value[i], onQty: (q) => _qty(entry.value[i], q), money: money),
                  ),
              ],
              _couponBox(context, onSurface),
              _summary(context, cart, money),
            ],
          ),
        ),
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(17, 10, 17, 8),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: spikeRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                onPressed: () async {
                  final user = await ref.read(currentUserProvider.future);
                  if (!context.mounted) return;
                  if (user == null) {
                    final login = await showDialog<bool>(
                      context: context,
                      builder: (d) => AlertDialog(
                        title: const Text('سجّل الدخول لإكمال الطلب'),
                        content: const Text('يمكنك الاحتفاظ بالمنتجات في السلة، لكن يلزم تسجيل الدخول للمتابعة إلى الدفع.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('تراجع')),
                          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('تسجيل الدخول')),
                        ],
                      ),
                    );
                    if (login == true && context.mounted) context.push('/login?next=%2Fcheckout');
                    return;
                  }
                  context.push('/checkout');
                },
                icon: const Icon(LucideIcons.creditCard, size: 18),
                label: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('المتابعة إلى الدفع', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Text(money(cart.subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _couponBox(BuildContext context, Color onSurface) => Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border.all(color: onSurface.withValues(alpha: .22)), borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('لديك كوبون؟', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 39,
                child: TextField(
                  controller: _coupon,
                  decoration: InputDecoration(
                    hintText: 'أدخل الكود',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 11),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: onSurface.withValues(alpha: .15))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: onSurface.withValues(alpha: .25))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 39,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF111827), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)), padding: const EdgeInsets.symmetric(horizontal: 18)),
                onPressed: () async {
                  try {
                    final c = await ref.read(cartRepositoryProvider).updateMeta(couponCode: _coupon.text);
                    if (!mounted) return;
                    setState(() => _cart = c);
                    if (!context.mounted) return;
                    showSpikeToast(context, _coupon.text.trim().isEmpty ? 'تم إزالة الكوبون' : 'تم تطبيق الكوبون');
                  } catch (e) {
                    if (!context.mounted) return;
                    showSpikeToast(context, e.toString());
                  }
                },
                child: const Text('تطبيق', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      );

  Widget _summary(BuildContext context, CartSnapshot cart, String Function(double) money) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _panel(context), borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('ملخص الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _invoiceLine('إجمالي المنتجات', money(cart.originalSubtotal)),
          if (cart.saving > 0) _invoiceLine('الخصم', '- ${money(cart.saving)}'),
          _invoiceTotal('المجموع قبل الشحن', money(cart.subtotal)),
          if (cart.saving > 0)
            Container(
              height: 43,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFDCEEE3), borderRadius: BorderRadius.circular(22)),
              child: Text('وفرت ${money(cart.saving)}', style: const TextStyle(color: Color(0xFF176B36), fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ]),
      );

  Widget _invoiceLine(String a, String b) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 36),
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .12)))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: const TextStyle(fontSize: 11)), Text(b, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]),
        ),
      );

  Widget _invoiceTotal(String a, String b) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), Text(b, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))]),
      );
}

class _Title extends StatelessWidget {
  const _Title({required this.onShare});
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
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
                child: InkWell(borderRadius: BorderRadius.circular(22), onTap: () => context.canPop() ? context.pop() : context.go('/'), child: const Icon(LucideIcons.arrowRight, size: 23)),
              ),
            ),
          ),
        ]),
      ),
      SizedBox(
        height: 60,
        child: Stack(alignment: Alignment.centerRight, children: [
          const Text('حقيبة التسوق', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(onPressed: onShare, icon: const Icon(LucideIcons.share2, size: 21)),
          ),
        ]),
      ),
    ]);
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.shoppingBag, size: 38),
            const SizedBox(height: 14),
            const Text('حقيبة التسوق فارغة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('أضف منتجاتك المفضلة وارجع هنا لإتمام الطلب.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: spikeMuted)),
            const SizedBox(height: 18),
            SizedBox(height: 43, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: spikeRed), onPressed: () => context.go('/'), child: const Text('ابدأ التسوق'))),
          ]),
        ),
      );
}

class _Item extends StatelessWidget {
  const _Item({required this.item, required this.onQty, required this.money});
  final CartItemModel item;
  final ValueChanged<int> onQty;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final discount = item.originalPrice > item.unitPrice && item.unitPrice > 0 ? ((1 - item.unitPrice / item.originalPrice) * 100).round() : 0;
    final placeholder = Theme.of(context).colorScheme.onSurface.withValues(alpha: .22);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: dark ? spikeDarkPanel : Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => context.push('/product/${item.productId}'),
          borderRadius: BorderRadius.circular(22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 100,
              height: 95,
              color: dark ? spikeDarkPanel : const Color(0xFFF6F6F6),
              child: item.imageUrl == null ? Icon(LucideIcons.image, color: placeholder) : Image.network(item.imageUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(LucideIcons.image, color: placeholder)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(onTap: () => context.push('/product/${item.productId}'), child: Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
            if (item.storeName.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: InkWell(onTap: item.storeId.isEmpty ? null : () => context.push('/store/${item.storeId}'), child: Text(item.storeName, style: const TextStyle(fontSize: 9, color: spikeMuted)))),
            const SizedBox(height: 7),
            Text(money(item.unitPrice), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            if (discount > 0)
              Row(children: [
                Text(money(item.originalPrice), style: const TextStyle(fontSize: 8, color: spikeMuted, decoration: TextDecoration.lineThrough)),
                const SizedBox(width: 6),
                Text('خصم $discount%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: spikeRed)),
              ]),
          ]),
        ),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: spikeRed, padding: EdgeInsets.zero, minimumSize: const Size(0, 28), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: () => onQty(0),
            icon: const Icon(LucideIcons.trash2, size: 15),
            label: const Text('حذف', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 22),
          Container(
            height: 31,
            decoration: BoxDecoration(color: dark ? Colors.white10 : const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 27, child: IconButton(padding: EdgeInsets.zero, onPressed: () => onQty(item.quantity - 1), icon: const Icon(Icons.remove, size: 14))),
              SizedBox(width: 24, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
              SizedBox(width: 27, child: IconButton(padding: EdgeInsets.zero, onPressed: item.quantity < item.stock ? () => onQty(item.quantity + 1) : null, icon: const Icon(Icons.add, size: 14))),
            ]),
          ),
        ]),
      ]),
    );
  }
}
