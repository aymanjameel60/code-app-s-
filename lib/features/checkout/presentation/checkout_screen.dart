import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../cart/data/cart_repository.dart';
import '../data/commerce_repository.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  CartSnapshot? cart;
  List<AddressModel> addresses = [];
  List<PaymentMethodModel> methods = [];
  List<CurrencyModel> currencies = [];
  AddressModel? address;
  PaymentMethodModel? payment;
  CurrencyModel? currency;
  DeliveryQuote? quote;
  bool loading = true, busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final cr = ref.read(commerceRepositoryProvider);
      final preferred = ref.read(appSettingsProvider).currency;
      final r = await Future.wait([
        ref.read(cartRepositoryProvider).load(),
        cr.addresses(),
        cr.paymentMethods(),
        cr.currencies(),
      ]);
      cart = r[0] as CartSnapshot;
      addresses = r[1] as List<AddressModel>;
      methods = r[2] as List<PaymentMethodModel>;
      currencies = r[3] as List<CurrencyModel>;
      address = addresses.where((a) => a.isActive).cast<AddressModel?>().firstOrNull ?? (addresses.isNotEmpty ? addresses.first : null);
      payment = methods.isNotEmpty ? methods.first : null;
      currency = currencies.where((c) => c.code == preferred).cast<CurrencyModel?>().firstOrNull ?? currencies.where((c) => c.code == (cart?.currencyCode ?? 'USD')).cast<CurrencyModel?>().firstOrNull ?? (currencies.isNotEmpty ? currencies.first : null);
      if (currency != null) cart = await ref.read(cartRepositoryProvider).updateMeta(currencyCode: currency!.code);
      if (address != null && cart!.items.isNotEmpty) {
        quote = await cr.quote(addressId: address!.id, variantIds: cart!.items.map((e) => e.variantId).toList());
      }
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _chooseAddress() async {
    await context.push('/addresses');
    final list = await ref.read(commerceRepositoryProvider).addresses();
    final selected = list.where((a) => a.isActive).cast<AddressModel?>().firstOrNull;
    if (selected != null) {
      setState(() => address = selected);
      quote = await ref.read(commerceRepositoryProvider).quote(addressId: selected.id, variantIds: cart!.items.map((e) => e.variantId).toList());
      if (mounted) setState(() {});
    }
  }

  Future<void> _currency(String? v) async {
    if (v == null) return;
    final x = currencies.where((c) => c.code == v).firstOrNull;
    if (x == null) return;
    setState(() => currency = x);
    await ref.read(appSettingsProvider.notifier).setCurrency(x.code);
    cart = await ref.read(cartRepositoryProvider).updateMeta(currencyCode: x.code);
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (busy || cart == null || address == null || payment == null || currency == null) return;
    setState(() => busy = true);
    try {
      final order = await ref.read(commerceRepositoryProvider).createOrder(cart: cart!, addressId: address!.id, paymentMethod: payment!.method, currencyCode: currency!.code);
      ref.invalidate(cartCountProvider);
      ref.invalidate(ordersProvider);
      if (mounted) {
        showSpikeToast(context, 'تم إنشاء الطلب بنجاح');
        context.go('/order/${order.id}');
      }
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: SpikeLoading());
    if (cart == null) return Scaffold(body: SpikeErrorState(onRetry: _load));

    if (cart!.items.isEmpty) {
      final onSurface = Theme.of(context).colorScheme.onSurface;
      final surface = Theme.of(context).colorScheme.surface;
      return Scaffold(body: SafeArea(child: Column(children: [
        const Padding(padding: EdgeInsets.fromLTRB(SpikeSpacing.page, SpikeSpacing.sm, SpikeSpacing.page, SpikeSpacing.xs), child: _CheckoutHead()),
        const Expanded(child: SpikeEmptyState(message: 'السلة فارغة، أضف منتجات قبل إتمام الطلب')),
        Padding(
          padding: const EdgeInsets.all(SpikeSpacing.page),
          child: SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: onSurface, foregroundColor: surface), onPressed: () => context.go('/'), child: const Text('العودة للتسوق'))),
        ),
      ])));
    }

    final panel = Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : spikePanel;
    final ready = address != null && payment != null && currency != null && !busy;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(body: SafeArea(child: Column(children: [
      const Padding(padding: EdgeInsets.fromLTRB(SpikeSpacing.page, SpikeSpacing.sm, SpikeSpacing.page, SpikeSpacing.xs), child: _CheckoutHead()),
      Expanded(child: ListView(padding: SpikeSpacing.pageList, children: [
        _step(context, panel, LucideIcons.mapPin, 'عنوان التوصيل', InkWell(
          onTap: _chooseAddress,
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(address?.label ?? 'اختر عنوان التوصيل', style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: SpikeSpacing.xs),
              Text(address?.addressLine ?? 'مطلوب لحساب تكلفة التوصيل', style: const TextStyle(fontSize: 10, color: spikeMuted)),
            ])),
            const Icon(LucideIcons.chevronLeft, size: 18),
          ]),
        )),
        const SizedBox(height: SpikeSpacing.md),
        _step(context, panel, LucideIcons.walletCards, 'طريقة الدفع', Column(children: [
          for (final m in methods) RadioListTile<String>(
            dense: true,
            title: Text(m.label, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: m.instructions.isEmpty ? null : Text(m.instructions, style: const TextStyle(fontSize: 10)),
            value: m.method,
            groupValue: payment?.method,
            onChanged: (_) => setState(() => payment = m),
          ),
        ])),
        const SizedBox(height: SpikeSpacing.md),
        _step(context, panel, LucideIcons.coins, 'العملة', DropdownButtonFormField<String>(
          initialValue: currency?.code,
          items: currencies.map((c) => DropdownMenuItem(value: c.code, child: Text('${c.name} (${c.code})'))).toList(),
          onChanged: _currency,
        )),
        const SizedBox(height: SpikeSpacing.md),
        Container(
          padding: const EdgeInsets.all(SpikeSpacing.lg),
          decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(SpikeRadius.card)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('ملخص الطلب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: SpikeSpacing.md),
            _line('المنتجات', '${cart!.subtotal.toStringAsFixed(2)} ${cart!.currencyCode}'),
            if (cart!.saving > 0) _line('التوفير', '- ${cart!.saving.toStringAsFixed(2)} ${cart!.currencyCode}', red: true),
            _line('التوصيل', quote == null ? 'يُحسب بعد اختيار العنوان' : '${quote!.shippingYerOld.toStringAsFixed(2)} YER_OLD'),
            const Divider(height: SpikeSpacing.xl),
            const Text('الإجمالي النهائي وسعر الصرف يتم اعتمادهما من الخادم عند إنشاء الطلب.', style: TextStyle(fontSize: 9, height: 1.5, color: spikeMuted)),
          ]),
        ),
      ])),
      Container(
        padding: const EdgeInsets.fromLTRB(SpikeSpacing.page, SpikeSpacing.sm, SpikeSpacing.page, SpikeSpacing.md),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(top: BorderSide(color: onSurface.withValues(alpha: .08)))),
        child: SafeArea(top: false, child: SizedBox(width: double.infinity, child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: spikeRed),
          onPressed: ready ? _submit : null,
          child: busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('تأكيد وإنشاء الطلب', style: TextStyle(fontWeight: FontWeight.w900)),
        ))),
      ),
    ])));
  }

  Widget _step(BuildContext context, Color panel, IconData icon, String title, Widget child) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: SpikeSpacing.card,
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(SpikeRadius.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: dark ? Colors.white : Colors.black, shape: BoxShape.circle), child: Icon(icon, size: 17, color: dark ? Colors.black : Colors.white)),
          const SizedBox(width: SpikeSpacing.sm),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: SpikeSpacing.sm),
        child,
      ]),
    );
  }

  Widget _line(String a, String b, {bool red = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: SpikeSpacing.xs),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a), Text(b, style: TextStyle(fontWeight: FontWeight.w800, color: red ? spikeRed : null))]),
  );
}

class _CheckoutHead extends StatelessWidget {
  const _CheckoutHead();
  @override
  Widget build(BuildContext context) => SizedBox(height: 46, child: Stack(alignment: Alignment.center, children: [
    const Text('تأكيد الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
    Align(alignment: Alignment.centerRight, child: IconButton(onPressed: () => context.pop(), icon: const Icon(LucideIcons.arrowRight, size: 22))),
  ]));
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
