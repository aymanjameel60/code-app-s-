import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/api_config.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersProvider);
    return Scaffold(body: SafeArea(child: Column(children: [
      _head(context, 'طلباتي'),
      Expanded(child: state.when(
        loading: () => const SpikeLoading(),
        error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(ordersProvider)),
        data: (orders) {
          if (orders.isEmpty) return const SpikeEmptyState(message: 'لا توجد طلبات حتى الآن');
          return RefreshIndicator(
            onRefresh: () async { ref.invalidate(ordersProvider); await ref.read(ordersProvider.future); },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(17, 10, 17, 24),
              itemCount: orders.length,
              itemBuilder: (context, i) {
                final o = orders[i];
                return InkWell(
                  onTap: () => context.push('/order/${o.id}'),
                  borderRadius: BorderRadius.circular(20),
                  child: _box(context, Row(children: [
                    Container(width: 46, height: 46, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle), child: const Icon(LucideIcons.shoppingBag, size: 20)),
                    const SizedBox(width: 11),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('طلب #${_short(o.id)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                      if (o.displayDate.isNotEmpty) ...[const SizedBox(height: 2), Text(o.displayDate, style: const TextStyle(fontSize: 9, color: spikeMuted))],
                      const SizedBox(height: 5),
                      Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [_pill(_status(o.status), _statusColor(o.status)), Text(o.paymentMethod == 'cod' ? 'عند الاستلام' : 'حوالة مالية', style: const TextStyle(fontSize: 9, color: spikeMuted))]),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${o.total.toStringAsFixed(2)} ${o.currencyCode}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)), const SizedBox(height: 5), const Icon(LucideIcons.chevronLeft, size: 17, color: spikeMuted)]),
                  ])),
                );
              },
            ),
          );
        },
      )),
    ])));
  }
}

class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool receiptBusy = false;
  String? returnBusyId;

  String _asset(String raw) => raw.startsWith('/uploads/') ? '${ApiConfig.assetBaseUrl}$raw' : raw;

  Future<void> _receipt() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 1800);
    if (x == null) return;
    setState(() => receiptBusy = true);
    try {
      await ref.read(commerceRepositoryProvider).uploadReceipt(widget.id, x.path);
      ref.invalidate(orderDetailsProvider(widget.id));
      if (mounted) showSpikeToast(context, 'تم رفع سند الحوالة وإرساله للمراجعة');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => receiptBusy = false);
    }
  }

  Future<void> _requestReturn(Map<String, dynamic> item) async {
    final maxQty = int.tryParse('${item['quantity'] ?? 1}') ?? 1;
    final reason = TextEditingController();
    int qty = 1;
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(17, 14, 17, MediaQuery.of(context).viewInsets.bottom + 22),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [const Expanded(child: Text('طلب إرجاع', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))), IconButton(onPressed: () => Navigator.pop(sheetContext, false), icon: const Icon(LucideIcons.x))]),
          Text('${item['product_name'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          const Text('الكمية', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(children: [
            IconButton(onPressed: qty > 1 ? () => setSheetState(() => qty--) : null, icon: const Icon(Icons.remove_circle_outline)),
            Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            IconButton(onPressed: qty < maxQty ? () => setSheetState(() => qty++) : null, icon: const Icon(Icons.add_circle_outline)),
            Text('من $maxQty', style: const TextStyle(fontSize: 10, color: spikeMuted)),
          ]),
          const SizedBox(height: 8),
          TextField(controller: reason, maxLines: 4, decoration: InputDecoration(labelText: 'سبب الإرجاع', hintText: 'اكتب سبب الإرجاع بوضوح', filled: true, fillColor: Theme.of(context).colorScheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          const SizedBox(height: 12),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: spikeRed, minimumSize: const Size.fromHeight(48)), onPressed: () {
            if (reason.text.trim().length < 3) { showSpikeToast(context, 'اكتب سبب الإرجاع'); return; }
            Navigator.pop(sheetContext, true);
          }, child: const Text('إرسال طلب الإرجاع')),
        ])),
      )),
    );
    if (submitted != true) { reason.dispose(); return; }
    final text = reason.text.trim();
    reason.dispose();
    final id = '${item['id'] ?? ''}';
    setState(() => returnBusyId = id);
    try {
      await ref.read(commerceRepositoryProvider).requestReturn(orderItemId: id, quantity: qty, reason: text);
      ref.invalidate(orderDetailsProvider(widget.id));
      ref.invalidate(returnsHistoryProvider);
      if (mounted) showSpikeToast(context, 'تم إرسال طلب الإرجاع للإدارة');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => returnBusyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(orderDetailsProvider(widget.id));
    final timeline = ref.watch(orderTimelineProvider(widget.id));
    return Scaffold(body: SafeArea(child: Column(children: [
      _head(context, 'تفاصيل الطلب'),
      Expanded(child: details.when(
        loading: () => const SpikeLoading(),
        error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(orderDetailsProvider(widget.id))),
        data: (d) {
          final order = Map<String, dynamic>.from(d['order'] as Map? ?? const {});
          final subs = (d['suborders'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          final items = (d['items'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          final transfer = order['payment_method'] == 'transfer';
          final needsReceipt = transfer && order['status'] == 'pending_admin_review' && (order['receipt_url'] == null || '${order['receipt_url']}'.isEmpty);
          final orderDate = _dateTime(order['created_at']);
          return RefreshIndicator(
            onRefresh: () async { ref.invalidate(orderDetailsProvider(widget.id)); ref.invalidate(orderTimelineProvider(widget.id)); await ref.read(orderDetailsProvider(widget.id).future); },
            child: ListView(padding: const EdgeInsets.fromLTRB(17, 10, 17, 24), children: [
              _box(context, Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('طلب #${_short(widget.id)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Align(alignment: Alignment.centerRight, child: _pill(_status('${order['status'] ?? ''}'), _statusColor('${order['status'] ?? ''}')))])),
                  Text('${order['total'] ?? 0} ${order['currency_code'] ?? ''}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                ]),
                const Divider(height: 24),
                if (orderDate.isNotEmpty) _info(LucideIcons.calendarDays, 'تاريخ الطلب', orderDate),
                _info(LucideIcons.walletCards, 'الدفع', '${transfer ? 'حوالة مالية' : 'عند الاستلام'} • ${_payment('${order['payment_status'] ?? ''}')}'),
                if (order['address_line'] != null) _info(LucideIcons.mapPin, 'التوصيل', '${order['address_line']}'),
              ])),
              if (transfer) ...[
                const SizedBox(height: 2),
                _box(context, Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Row(children: [Icon(LucideIcons.receipt, size: 18), SizedBox(width: 7), Text('سند الحوالة', style: TextStyle(fontWeight: FontWeight.w900))]),
                  const SizedBox(height: 7),
                  Text(needsReceipt ? 'ارفع صورة سند الحوالة ليتمكن الأدمن من مراجعة الطلب.' : 'حالة السند: ${_payment('${order['payment_status'] ?? ''}')}', style: const TextStyle(fontSize: 11, height: 1.5)),
                  if (needsReceipt) ...[const SizedBox(height: 9), FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: spikeRed), onPressed: receiptBusy ? null : _receipt, icon: const Icon(LucideIcons.upload, size: 17), label: Text(receiptBusy ? 'جاري الرفع...' : 'رفع سند الحوالة'))],
                ])),
              ],
              const SizedBox(height: 12),
              _sectionTitle(LucideIcons.route, 'تتبع الطلب'),
              timeline.when(
                loading: () => const Padding(padding: EdgeInsets.all(12), child: SpikeLoading()),
                error: (e, _) => Text(e.toString()),
                data: (rows) => rows.isEmpty ? const _MiniEmpty('لا توجد تحديثات بعد') : Column(children: List.generate(rows.length, (i) {
                  final x = rows[i], last = i == rows.length - 1;
                  final status = '${x['status'] ?? ''}';
                  final date = _dateTime(x['created_at']);
                  final store = '${x['store_name'] ?? ''}'.trim();
                  final meta = [if (store.isNotEmpty) store, if (date.isNotEmpty) date].join(' • ');
                  final color = _statusColor(status);
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 28, child: Column(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), if (!last) Container(width: 2, height: 45, color: color.withValues(alpha: .18))])),
                    Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_status(status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)), if (meta.isNotEmpty) Text(meta, style: const TextStyle(fontSize: 9, color: spikeMuted))]))),
                  ]);
                })),
              ),
              if (subs.isNotEmpty) ...[
                const SizedBox(height: 10),
                _sectionTitle(LucideIcons.store, 'طلبات المتاجر'),
                for (final s in subs) _box(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text('${s['store_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900))), _pill(_status('${s['status'] ?? ''}'), _statusColor('${s['status'] ?? ''}'))]),
                  if (s['delivery_office_name'] != null) Padding(padding: const EdgeInsets.only(top: 7), child: _info(LucideIcons.truck, 'مكتب التوصيل', '${s['delivery_office_name']}')),
                  if (s['shipping_total'] != null) _info(LucideIcons.banknote, 'تكلفة التوصيل', '${s['shipping_total']} ${s['currency_code'] ?? ''}'),
                ])),
              ],
              const SizedBox(height: 10),
              _sectionTitle(LucideIcons.package, 'المنتجات'),
              for (final item in items) _box(context, Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  InkWell(
                    onTap: '${item['product_id']??''}'.isEmpty ? null : () => context.push('/product/${item['product_id']}'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 52,
                      height: 52,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
                      child: '${item['image_url']??''}'.trim().isEmpty
                          ? const Icon(LucideIcons.package, size: 18)
                          : CachedNetworkImage(imageUrl: _asset('${item['image_url']}'), fit: BoxFit.cover, errorWidget: (_,__,___)=>const Icon(LucideIcons.package,size:18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: InkWell(onTap: '${item['product_id']??''}'.isEmpty ? null : () => context.push('/product/${item['product_id']}'), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${item['product_name'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)), Text('${item['store_name'] ?? ''}${'${item['variant_title'] ?? ''}'.isEmpty ? '' : ' • ${item['variant_title']}'}', style: const TextStyle(fontSize: 9, color: spikeMuted))]))),
                  Text('×${item['quantity'] ?? 1}', style: const TextStyle(fontWeight: FontWeight.w900)),
                ]),
                if (item['can_return'] == true) Padding(padding: const EdgeInsets.only(top: 10), child: OutlinedButton.icon(onPressed: returnBusyId == '${item['id']}' ? null : () => _requestReturn(item), icon: const Icon(LucideIcons.rotateCcw, size: 16), label: Text(returnBusyId == '${item['id']}' ? 'جاري الإرسال...' : 'طلب إرجاع'))),
                if (item['has_return_request'] == true) const Padding(padding: EdgeInsets.only(top: 9), child: Row(children: [Icon(LucideIcons.clock3, size: 15, color: Colors.orange), SizedBox(width: 6), Text('تم تسجيل طلب إرجاع لهذا المنتج', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange))])),
              ])),
            ]),
          );
        },
      )),
    ])));
  }
}

Widget _head(BuildContext context, String title) => Padding(padding: const EdgeInsets.fromLTRB(17, 8, 17, 4), child: SizedBox(height: 46, child: Stack(alignment: Alignment.center, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Align(alignment: Alignment.centerRight, child: IconButton(onPressed: () => context.pop(), icon: const Icon(LucideIcons.arrowRight, size: 22)))])));
Widget _box(BuildContext context, Widget child) => Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : spikePanel, borderRadius: BorderRadius.circular(20)), child: child);
Widget _sectionTitle(IconData icon, String title) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 7), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))]));
Widget _info(IconData icon, String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 15, color: spikeMuted), const SizedBox(width: 6), Text('$label: ', style: const TextStyle(fontSize: 10, color: spikeMuted)), Expanded(child: Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)))]));
Widget _pill(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)));
String _short(String s) => s.length > 8 ? s.substring(0, 8) : s;
String _dateTime(dynamic raw) { final value = '${raw ?? ''}'.trim(); if (value.isEmpty) return ''; final parsed = DateTime.tryParse(value); if (parsed == null) return value; final d = parsed.toLocal(); String two(int n) => n.toString().padLeft(2, '0'); return '${d.year}/${two(d.month)}/${two(d.day)} • ${two(d.hour)}:${two(d.minute)}'; }
Color _statusColor(String s) { if (s == 'delivered' || s == 'approved' || s == 'accepted') return Colors.green; if (s == 'rejected' || s == 'returned') return spikeRed; if (s == 'assigned' || s == 'picked_up' || s == 'with_courier' || s == 'ready_for_delivery') return Colors.blue; return Colors.orange; }
String _status(String s) => const {'pending_admin_review':'قيد مراجعة الإدارة','accepted':'مقبول','approved':'تمت الموافقة','processing':'قيد التجهيز','ready_for_delivery':'جاهز للتوصيل','assigned':'تم تعيين مكتب التوصيل','picked_up':'تم استلامه من المتجر','with_courier':'مع المندوب','delivered':'تم التوصيل','rejected':'مرفوض','returned':'مرتجع'}[s] ?? s;
String _payment(String s) => const {'pending_review':'قيد مراجعة السند','approved':'تم اعتماد الدفع','pending_collection':'يُحصّل عند الاستلام','paid':'مدفوع','rejected':'مرفوض'}[s] ?? s;

class _MiniEmpty extends StatelessWidget {
  const _MiniEmpty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(text, style: const TextStyle(fontSize: 11, color: spikeMuted)));
}
