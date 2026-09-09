import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool unreadOnly = false;

  Future<void> _readOne(String id) async {
    try {
      await ref.read(engagementRepositoryProvider).readNotification(id);
      ref.invalidate(notificationsDataProvider);
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    }
  }

  Future<void> _open(Map<String, dynamic> notification) async {
    final id = '${notification['id'] ?? ''}';
    if (notification['read_at'] == null && id.isNotEmpty) await _readOne(id);
    if (!mounted) return;
    final data = notification['data'];
    final payload = data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{};
    final orderId = '${payload['order_id'] ?? notification['entity_id'] ?? ''}';
    final type = '${notification['entity_type'] ?? ''}';
    if (orderId.isNotEmpty && (payload['order_id'] != null || type == 'order')) {
      context.push('/order/$orderId');
      return;
    }
    final route = '${payload['route'] ?? notification['route'] ?? ''}';
    final known = RegExp(r'^/(order|orders|product|products|store|stores|categories|offers|cart|profile|favorites|notifications|reviews|support|settings|privacy|personal-data|returns-refunds|search|checkout)(/|$|\?)');
    context.push(known.hasMatch(route) ? route : '/orders');
  }

  Future<void> _readAll() async {
    try {
      await ref.read(engagementRepositoryProvider).readAllNotifications();
      ref.invalidate(notificationsDataProvider);
      if (mounted) showSpikeToast(context, 'تم تحديد الإشعارات كمقروءة');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(notificationsDataProvider);

    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const SpikeLoading(),
          error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(notificationsDataProvider)),
          data: (data) {
            final raw = data['notifications'];
            final all = (raw is List ? raw : const <dynamic>[]).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
            final items = unreadOnly ? all.where((n) => n['read_at'] == null).toList() : all;

            return Column(children: [
              _NotificationsHead(dark: dark),
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 0, 17, 14),
                child: Row(children: [
                  Expanded(
                    child: Row(children: [
                      _NotificationTab(label: 'الكل', active: !unreadOnly, onTap: () => setState(() => unreadOnly = false)),
                      const SizedBox(width: 8),
                      _NotificationTab(label: 'غير المقروءة', active: unreadOnly, onTap: () => setState(() => unreadOnly = true)),
                    ]),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'خيارات الإشعارات',
                    padding: EdgeInsets.zero,
                    icon: const Icon(LucideIcons.moreHorizontal, size: 22),
                    onSelected: (value) {
                      if (value == 'read-all') _readAll();
                    },
                    itemBuilder: (_) => const [PopupMenuItem(value: 'read-all', child: Text('تحديد الكل كمقروء'))],
                  ),
                ]),
              ),
              Expanded(
                child: items.isEmpty
                    ? const _NotificationsEmpty()
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(notificationsDataProvider);
                          await ref.read(notificationsDataProvider.future);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(17, 0, 17, 20),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final n = items[i];
                            final isUnread = n['read_at'] == null;
                            final data = n['data'];
                            final hasOrder = data is Map && data['order_id'] != null;
                            return InkWell(
                              onTap: () => _open(n),
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: dark ? spikeDarkPanel : (isUnread ? Colors.white : spikePanel),
                                  borderRadius: BorderRadius.circular(22),
                                  border: isUnread ? Border.all(color: const Color(0xFFE8E8E8)) : null,
                                ),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: dark ? const Color(0xFF282828) : const Color(0xFFEFEFEF),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(hasOrder ? LucideIcons.package : LucideIcons.bell, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(children: [
                                        Expanded(child: Text('${n['title'] ?? 'إشعار'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.35))),
                                        if (isUnread) const CircleAvatar(radius: 4, backgroundColor: spikeRed),
                                      ]),
                                      const SizedBox(height: 5),
                                      Text('${n['body'] ?? n['message'] ?? ''}', style: TextStyle(fontSize: 10, height: 1.55, color: dark ? const Color(0xFFBBBBBB) : const Color(0xFF666666))),
                                      if ('${n['created_at'] ?? ''}'.isNotEmpty) ...[
                                        const SizedBox(height: 7),
                                        Text('${n['created_at']}', style: const TextStyle(fontSize: 9, color: spikeMuted)),
                                      ],
                                    ]),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _NotificationsHead extends StatelessWidget {
  const _NotificationsHead({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(17, 8, 17, 0),
        child: Column(children: [
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
                      onTap: () => context.canPop() ? context.pop() : context.go('/'),
                      child: const Icon(LucideIcons.arrowRight, size: 23),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(
            height: 60,
            child: Align(alignment: Alignment.centerRight, child: Text('الإشعارات', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700))),
          ),
        ]),
      );
}

class _NotificationTab extends StatelessWidget {
  const _NotificationTab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 37,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Theme.of(context).colorScheme.onSurface : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFE7E7E7)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(fontSize: 11, color: active ? Theme.of(context).colorScheme.surface : null)),
        ),
      );
}

class _NotificationsEmpty extends StatelessWidget {
  const _NotificationsEmpty();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 55, height: 55, decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : spikePanel, shape: BoxShape.circle), child: const Icon(LucideIcons.check, size: 24)),
            const SizedBox(height: 12),
            const Text('لا توجد إشعارات هنا', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            const Text('ستظهر تحديثات طلباتك ورسائل النظام في هذه الصفحة.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: spikeMuted)),
          ]),
        ),
      );
}
