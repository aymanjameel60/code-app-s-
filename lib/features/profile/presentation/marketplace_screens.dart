import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      data = await ref.read(apiClientProvider).get('/wallet/me', auth: true);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _shortId(Object? value) {
    final id = '${value ?? ''}';
    return id.length > 8 ? id.substring(0, 8) : id;
  }

  String _money(Object? value) {
    final number = double.tryParse('${value ?? 0}') ?? 0;
    return '\$${number.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: SpikeLoading());
    if (error != null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const _Head('محفظتي'),
              Expanded(child: SpikeErrorState(message: error!, onRetry: _load)),
            ],
          ),
        ),
      );
    }

    final d = data ?? const <String, dynamic>{};
    final wallet = Map<String, dynamic>.from(d['wallet'] as Map? ?? const {});
    final transactions = (d['transactions'] as List? ?? const []).whereType<Map>().toList();
    final purchases = (d['purchases'] as List? ?? const []).whereType<Map>().take(8).toList();
    final summary = Map<String, dynamic>.from(d['summary'] as Map? ?? const {});
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = dark ? spikeDarkPanel : Colors.white;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _Head('محفظتي'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الرصيد المتاح', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(_money(wallet['balance']), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text(
                          'رصيدك في Spike للمبالغ المستردة والرصيد المضاف والمشتريات المدعومة بالمحفظة.',
                          style: TextStyle(fontSize: 11, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _stat('عدد المشتريات', '${summary['orders_count'] ?? 0}')),
                      const SizedBox(width: 10),
                      Expanded(child: _stat('إجمالي المشتريات', _money(summary['purchases_total']))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('آخر الحركات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  if (transactions.isEmpty)
                    _empty('لا توجد حركات في المحفظة حتى الآن.')
                  else
                    ...transactions.map((raw) {
                      final x = Map<String, dynamic>.from(raw);
                      final prefix = x['direction'] == 'credit' ? '+' : '-';
                      return _row(
                        '${x['note'] ?? 'حركة رصيد'}',
                        '${x['created_at'] ?? ''}',
                        '$prefix${_money(x['amount'])}',
                      );
                    }),
                  const SizedBox(height: 18),
                  const Text('مشترياتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  if (purchases.isEmpty)
                    _empty('لا توجد مشتريات حتى الآن.')
                  else
                    ...purchases.map((raw) {
                      final x = Map<String, dynamic>.from(raw);
                      return _row(
                        'طلب #${_shortId(x['id'])}',
                        '${x['status'] ?? ''}',
                        _money(x['total']),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: spikePanel, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _empty(String text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: spikePanel, borderRadius: BorderRadius.circular(18)),
        child: Text(text, style: const TextStyle(fontSize: 11)),
      );

  Widget _row(String title, String subtitle, String value) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: spikePanel, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 9, color: spikeMuted)),
                ],
              ),
            ),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class VendorRegistrationScreen extends ConsumerStatefulWidget {
  const VendorRegistrationScreen({super.key});

  @override
  ConsumerState<VendorRegistrationScreen> createState() => _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends ConsumerState<VendorRegistrationScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final store = TextEditingController();
  final note = TextEditingController();
  bool busy = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(currentUserProvider).valueOrNull;
    if (u != null) {
      name.text = '${u['name'] ?? ''}';
      phone.text = '${u['phone'] ?? ''}';
      final rawEmail = '${u['email'] ?? ''}';
      email.text = rawEmail.endsWith('@customer.spike.local') ? '' : rawEmail;
    }
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    store.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (name.text.trim().isEmpty || phone.text.trim().isEmpty || store.text.trim().isEmpty) {
      showSpikeToast(context, 'أكمل الحقول المطلوبة');
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(apiClientProvider).post(
        '/vendor-registration',
        data: {
          'applicant_name': name.text.trim(),
          'phone': phone.text.trim(),
          'email': email.text.trim(),
          'store_name': store.text.trim(),
          'note': note.text.trim(),
        },
      );
      if (!mounted) return;
      showSpikeToast(context, 'تم إرسال طلب التسجيل كتاجر');
      context.pop();
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const _Head('سجّل كتاجر'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
                  children: [
                    const Text(
                      'ابدأ البيع على Spike. أرسل بياناتك وسيتم مراجعة الطلب من الإدارة.',
                      style: TextStyle(fontSize: 12, height: 1.6),
                    ),
                    const SizedBox(height: 16),
                    _field(name, 'الاسم الكامل', LucideIcons.user),
                    const SizedBox(height: 10),
                    _field(phone, 'رقم الجوال', LucideIcons.phone, keyboard: TextInputType.phone),
                    const SizedBox(height: 10),
                    _field(email, 'البريد الإلكتروني - اختياري', LucideIcons.mail, keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _field(store, 'اسم المتجر', LucideIcons.store),
                    const SizedBox(height: 10),
                    TextField(controller: note, maxLines: 4, decoration: _dec('ملاحظة عن نشاط المتجر', LucideIcons.fileText)),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 46,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: spikeRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: busy ? null : submit,
                        child: busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('إرسال طلب التسجيل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _field(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboard}) => SizedBox(
        height: 54,
        child: TextField(controller: controller, keyboardType: keyboard, decoration: _dec(hint, icon)),
      );

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : Colors.white,
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(15)),
        suffixIcon: Icon(icon, size: 19),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

class _Head extends StatelessWidget {
  const _Head(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 8, 17, 0),
      child: Column(
        children: [
          SizedBox(
            height: 92,
            child: Stack(
              children: [
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
                        onTap: () => context.canPop() ? context.pop() : context.go('/profile'),
                        child: const Icon(LucideIcons.arrowRight, size: 23),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 60,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
