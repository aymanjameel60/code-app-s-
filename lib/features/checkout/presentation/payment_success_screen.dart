import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key, this.paymentMethod = ''});
  final String paymentMethod;

  @override
  Widget build(BuildContext context) {
    final transfer = paymentMethod.toLowerCase() == 'transfer';
    final dark = Theme.of(context).brightness == Brightness.dark;
    final message = transfer
        ? 'تم استلام طلبك. اذهب إلى طلباتي وارفع سند الحوالة حتى تتم مراجعته واعتماد الطلب.'
        : 'تم استلام طلبك. اذهب إلى طلباتي واضغط تأكيد الطلب لإكمال الطلب بالدفع عند الاستلام.';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 8, 17, 28),
          children: [
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => context.go('/'),
                        child: const Icon(LucideIcons.arrowRight, size: 23),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(
              height: 60,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('تم إنشاء الطلب', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
              decoration: BoxDecoration(
                color: dark ? spikeDarkPanel : spikePanel,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                  child: const Icon(LucideIcons.check, size: 30, color: Colors.white),
                ),
                const SizedBox(height: 18),
                const Text('تم استلام طلبك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.8)),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.onSurface,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => context.go('/orders'),
                    child: const Text('الذهاب لطلباتي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.onSurface,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => context.go('/'),
                    child: const Text('خروج', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
