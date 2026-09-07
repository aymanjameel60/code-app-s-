import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class ReturnsRefundsScreen extends ConsumerWidget {
  const ReturnsRefundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returns = ref.watch(returnsHistoryProvider);
    final refunds = ref.watch(refundsHistoryProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(SpikeSpacing.page, SpikeSpacing.sm, SpikeSpacing.page, 0),
            child: SizedBox(height: 60, child: Stack(alignment: Alignment.center, children: [
              const Text('المرتجعات والاستردادات', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
              Align(alignment: Alignment.centerRight, child: IconButton(onPressed: () => context.pop(), icon: const Icon(LucideIcons.arrowRight, size: 22))),
            ])),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(returnsHistoryProvider);
                ref.invalidate(refundsHistoryProvider);
                await Future.wait([ref.read(returnsHistoryProvider.future), ref.read(refundsHistoryProvider.future)]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(SpikeSpacing.page, 0, SpikeSpacing.page, SpikeSpacing.xl),
                children: [
                  _title(LucideIcons.undo2, 'المرتجعات'),
                  returns.when(
                    loading: () => const SpikeLoading(),
                    error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(returnsHistoryProvider)),
                    data: (items) {
                      if (items.isEmpty) return const _Empty(text: 'لا توجد طلبات إرجاع');
                      return Column(children: items.map((x) {
                        final quantity = int.tryParse('${x['quantity'] ?? 0}') ?? 0;
                        final adminNote = '${x['admin_note'] ?? ''}'.trim();
                        final reason = '${x['reason'] ?? ''}'.trim();
                        final extra = [if (quantity > 0) 'الكمية: $quantity', if (reason.isNotEmpty) reason, if (adminNote.isNotEmpty) 'ملاحظة الإدارة: $adminNote'].join('\n');
                        return _card(context, icon: LucideIcons.rotateCcw, title: '${x['product_name'] ?? ''}', subtitle: '${x['store_name'] ?? ''}', status: '${x['status'] ?? ''}', note: extra, orderId: '${x['order_id'] ?? ''}');
                      }).toList());
                    },
                  ),
                  const SizedBox(height: 20),
                  _title(LucideIcons.badgeDollarSign, 'الاستردادات'),
                  refunds.when(
                    loading: () => const SpikeLoading(),
                    error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(refundsHistoryProvider)),
                    data: (items) {
                      if (items.isEmpty) return const _Empty(text: 'لا توجد مبالغ مستردة');
                      return Column(children: items.map((x) => _card(context, icon: LucideIcons.banknote, title: '${x['product_name'] ?? 'استرداد مبلغ'}', subtitle: '${x['store_name'] ?? ''}', status: '${x['status'] ?? ''}', note: '${x['amount'] ?? 0} ${x['currency_code'] ?? ''}', orderId: '${x['order_id'] ?? ''}')).toList());
                    },
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _title(IconData icon, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
        child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
      );

  Widget _card(BuildContext context, {required IconData icon, required String title, required String subtitle, required String status, required String note, required String orderId}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: orderId.isEmpty ? null : () => context.push('/order/$orderId'),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: dark ? spikeDarkPanel : const Color(0xFFE9E9E9), borderRadius: BorderRadius.circular(24)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 54, height: 54, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18)), child: Icon(icon, size: 21)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)), child: Text(_status(status), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color))),
              ]),
              if (subtitle.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, style: const TextStyle(fontSize: 10, color: spikeMuted))),
              if (note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 7), child: Text(note, style: const TextStyle(fontSize: 11, height: 1.5))),
              if (orderId.isNotEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Row(children: [Text('عرض الطلب', style: TextStyle(fontSize: 10, color: spikeRed, fontWeight: FontWeight.w800)), SizedBox(width: 4), Icon(LucideIcons.chevronLeft, size: 14, color: spikeRed)])),
            ])),
          ]),
        ),
      ),
    );
  }

  Color _statusColor(String s) => s == 'approved' || s == 'paid' || s == 'returned' ? Colors.green : s == 'rejected' ? spikeRed : Colors.orange;
  String _status(String s) => const {'pending': 'قيد المعالجة', 'pending_admin_review': 'قيد مراجعة الإدارة', 'approved': 'معتمد', 'rejected': 'مرفوض', 'paid': 'تم إعادة المبلغ', 'returned': 'مرتجع'}[s] ?? s;
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(height: 82, alignment: Alignment.center, decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : const Color(0xFFE9E9E9), borderRadius: BorderRadius.circular(24)), child: Text(text, style: const TextStyle(fontSize: 11, color: spikeMuted)));
}
