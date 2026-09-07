import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});
  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      items = await ref.read(engagementRepositoryProvider).reviewable();
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _rate({required bool store, required Map<String, dynamic> item}) async {
    int rating = 5;
    final comment = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(SpikeSpacing.page, 20, SpikeSpacing.page, MediaQuery.viewInsetsOf(sheetContext).bottom + 25),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(store ? 'تقييم المتجر' : 'تقييم المنتج', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(store ? '${item['store_name'] ?? ''}' : '${item['product_name'] ?? ''}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: spikeMuted)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.ltr,
                children: List.generate(5, (i) => IconButton(iconSize: 30, visualDensity: VisualDensity.compact, onPressed: () => setLocal(() => rating = i + 1), icon: Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFFF5B400)))),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 78,
                child: TextField(
                  controller: comment,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: 'تعليقك - اختياري', filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : const Color(0xFFE7E7E7), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(18))),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(height: 39, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: spikeRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))), onPressed: () => Navigator.pop(sheetContext, true), child: const Text('إرسال التقييم', style: TextStyle(fontWeight: FontWeight.w800)))),
            ]),
          ),
        ),
      ),
    );
    if (ok != true) {
      comment.dispose();
      return;
    }
    try {
      final repo = ref.read(engagementRepositoryProvider);
      if (store) {
        await repo.reviewStore(suborderId: '${item['suborder_id']}', rating: rating, comment: comment.text);
      } else {
        await repo.reviewProduct(orderItemId: '${item['order_item_id']}', rating: rating, comment: comment.text);
      }
      if (mounted) {
        showSpikeToast(context, 'تم إرسال تقييمك');
        await _load();
      }
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      comment.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(SpikeSpacing.page, SpikeSpacing.sm, SpikeSpacing.page, 0),
            child: SizedBox(height: 60, child: Stack(alignment: Alignment.center, children: [
              const Text('التقييمات', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
              Align(alignment: Alignment.centerRight, child: IconButton(onPressed: () => context.pop(), icon: const Icon(LucideIcons.arrowRight, size: 22))),
            ])),
          ),
          Expanded(
            child: loading
                ? const SpikeLoading()
                : items.isEmpty
                    ? const SpikeEmptyState(message: 'بعد استلام طلبك ستظهر المنتجات القابلة للتقييم هنا')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(SpikeSpacing.page, 0, SpikeSpacing.page, SpikeSpacing.xl),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final x = items[i];
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: dark ? spikeDarkPanel : const Color(0xFFE9E9E9), borderRadius: BorderRadius.circular(22)),
                              child: Column(children: [
                                Row(children: [
                                  Container(width: 78, height: 78, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18)), child: const Icon(LucideIcons.packageCheck, size: 24)),
                                  const SizedBox(width: 11),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${x['product_name'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 3),
                                    Text('${x['store_name'] ?? ''}', style: const TextStyle(fontSize: 9, color: spikeMuted)),
                                    const SizedBox(height: 7),
                                    Row(textDirection: TextDirection.ltr, mainAxisSize: MainAxisSize.min, children: List.generate(5, (_) => const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF5B400)))),
                                  ])),
                                ]),
                                if (x['can_review_product'] == true || x['can_review_store'] == true) ...[
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    if (x['can_review_product'] == true) Expanded(child: SizedBox(height: 39, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))), onPressed: () => _rate(store: false, item: x), icon: const Icon(Icons.star_outline_rounded, size: 17), label: const Text('تقييم المنتج', style: TextStyle(fontSize: 11))))),
                                    if (x['can_review_product'] == true && x['can_review_store'] == true) const SizedBox(width: 8),
                                    if (x['can_review_store'] == true) Expanded(child: SizedBox(height: 39, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))), onPressed: () => _rate(store: true, item: x), icon: const Icon(LucideIcons.store, size: 16), label: const Text('تقييم المتجر', style: TextStyle(fontSize: 11))))),
                                  ]),
                                ],
                              ]),
                            );
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}
