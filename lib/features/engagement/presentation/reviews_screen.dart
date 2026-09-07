import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});
  @override ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    try { items = await ref.read(engagementRepositoryProvider).reviewable(); }
    catch (e) { if (mounted) showSpikeToast(context, e.toString()); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _rate({required bool store, required Map<String, dynamic> item}) async {
    int rating = 5;
    final comment = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: Text(store ? 'تقييم المتجر' : 'تقييم المنتج'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(onPressed: () => setLocal(() => rating = i + 1), icon: Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber)))),
            TextField(controller: comment, maxLines: 3, decoration: const InputDecoration(hintText: 'اكتب تعليقك (اختياري)')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: spikeRed), onPressed: () => Navigator.pop(dialogContext, true), child: const Text('إرسال')),
          ],
        ),
      ),
    );
    if (ok != true) { comment.dispose(); return; }
    try {
      final repo = ref.read(engagementRepositoryProvider);
      if (store) { await repo.reviewStore(suborderId: '${item['suborder_id']}', rating: rating, comment: comment.text); }
      else { await repo.reviewProduct(orderItemId: '${item['order_item_id']}', rating: rating, comment: comment.text); }
      if (mounted) { showSpikeToast(context, 'تم إرسال تقييمك'); await _load(); }
    } catch (e) { if (mounted) showSpikeToast(context, e.toString()); }
    finally { comment.dispose(); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('التقييمات'), centerTitle: true),
    body: loading
        ? const SpikeLoading()
        : items.isEmpty
            ? const SpikeEmptyState(message: 'لا توجد منتجات قابلة للتقييم حالياً')
            : ListView.builder(
                padding: const EdgeInsets.all(17),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final x = items[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: spikePanel, borderRadius: BorderRadius.circular(20)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${x['product_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${x['store_name'] ?? ''}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: [
                        if (x['can_review_product'] == true) OutlinedButton.icon(onPressed: () => _rate(store: false, item: x), icon: const Icon(Icons.star_outline), label: const Text('تقييم المنتج')),
                        if (x['can_review_store'] == true) OutlinedButton.icon(onPressed: () => _rate(store: true, item: x), icon: const Icon(Icons.storefront_outlined), label: const Text('تقييم المتجر')),
                      ]),
                    ]),
                  );
                },
              ),
  );
}
