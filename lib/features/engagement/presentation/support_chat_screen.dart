import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});
  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final text = TextEditingController();
  final scroll = ScrollController();
  String? threadId;
  List<Map<String, dynamic>> messages = [];
  bool loading = true, sending = false, chatOpen = false;
  Map<String, dynamic> service = const {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    text.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _bottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  Future<void> _loadSettings() async {
    if (mounted) setState(() => loading = true);
    try {
      service = await ref.read(engagementRepositoryProvider).publicSettings();
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openChat() async {
    setState(() {
      chatOpen = true;
      loading = true;
    });
    try {
      final repo = ref.read(engagementRepositoryProvider);
      threadId ??= await repo.ensureSupportThread();
      messages = await repo.supportMessages(threadId!);
      _bottom();
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openService(String scheme, String value) async {
    final cleaned = scheme == 'tel' ? value.replaceAll(RegExp(r'\s+'), '') : value.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(scheme == 'tel' ? 'tel:$cleaned' : 'https://wa.me/$cleaned');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) showSpikeToast(context, 'تعذر فتح وسيلة التواصل');
  }

  Future<void> _send() async {
    final body = text.text.trim();
    if (body.isEmpty || threadId == null || sending) return;
    setState(() => sending = true);
    try {
      final repo = ref.read(engagementRepositoryProvider);
      await repo.sendSupportMessage(threadId!, body);
      text.clear();
      messages = await repo.supportMessages(threadId!);
      if (mounted) setState(() {});
      _bottom();
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final phone = '${service['customer_service_phone'] ?? ''}'.trim();
    final whatsapp = '${service['customer_service_whatsapp'] ?? ''}'.trim();
    final chatEnabled = service['customer_service_chat_enabled'] != false;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
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
                        child: InkWell(borderRadius: BorderRadius.circular(22), onTap: () => context.canPop() ? context.pop() : context.go('/profile'), child: const Icon(LucideIcons.arrowRight, size: 23)),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 60, child: Align(alignment: Alignment.centerRight, child: Text('خدمة العملاء', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)))),
            ]),
          ),
          if (loading && !chatOpen) const Expanded(child: SpikeLoading()) else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 0, 17, 14),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _ServiceIcon(icon: LucideIcons.phone, enabled: phone.isNotEmpty, onTap: () => _openService('tel', phone)),
                const SizedBox(width: 14),
                _ServiceIcon(icon: LucideIcons.messageCircle, enabled: whatsapp.isNotEmpty, onTap: () => _openService('wa', whatsapp)),
                const SizedBox(width: 14),
                _ServiceIcon(icon: LucideIcons.messagesSquare, enabled: chatEnabled, onTap: _openChat),
              ]),
            ),
            Expanded(
              child: !chatOpen
                  ? const SizedBox.shrink()
                  : loading
                      ? const SpikeLoading()
                      : Column(children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 17),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(color: dark ? spikeDarkPanel : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).dividerColor)),
                            child: const Row(children: [
                              CircleAvatar(radius: 20, backgroundColor: spikePanel, child: Icon(LucideIcons.shieldCheck, size: 20)),
                              SizedBox(width: 10),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('إدارة Spike', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), Text('الدعم والمساعدة', style: TextStyle(fontSize: 10, color: spikeMuted))]),
                            ]),
                          ),
                          Expanded(
                            child: messages.isEmpty
                                ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 34), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('مرحباً 👋', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), SizedBox(height: 8), Text('اكتب رسالتك للإدارة وسيظهر الرد هنا في نفس المحادثة.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, height: 1.6, color: spikeMuted))])))
                                : RefreshIndicator(
                                    onRefresh: _openChat,
                                    child: ListView.builder(
                                      controller: scroll,
                                      padding: const EdgeInsets.fromLTRB(17, 14, 17, 18),
                                      itemCount: messages.length,
                                      itemBuilder: (context, i) {
                                        final m = messages[i];
                                        final mine = '${m['sender_role'] ?? ''}' == 'customer';
                                        return Align(
                                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                          child: Container(
                                            constraints: const BoxConstraints(maxWidth: 286),
                                            margin: const EdgeInsets.only(bottom: 9),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                            decoration: BoxDecoration(color: mine ? spikeRed : (dark ? spikeDarkPanel : spikePanel), borderRadius: BorderRadius.circular(18)),
                                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Text('${m['body'] ?? ''}', style: TextStyle(fontSize: 12, height: 1.5, color: mine ? Colors.white : null)),
                                              if ('${m['created_at'] ?? ''}'.isNotEmpty) ...[const SizedBox(height: 4), Text('${m['created_at']}', style: TextStyle(fontSize: 8, color: mine ? Colors.white70 : spikeMuted))],
                                            ]),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(17, 8, 17, 8),
                            child: SafeArea(
                              top: false,
                              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Expanded(child: TextField(controller: text, minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'اكتب رسالة...'))),
                                const SizedBox(width: 8),
                                SizedBox(width: 44, height: 44, child: IconButton.filled(style: IconButton.styleFrom(backgroundColor: spikeRed), onPressed: sending ? null : _send, icon: sending ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(LucideIcons.arrowUp, color: Colors.white, size: 19))),
                              ]),
                            ),
                          ),
                        ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 54,
        height: 44,
        child: OutlinedButton(
          onPressed: enabled ? onTap : null,
          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: Icon(icon, size: 21),
        ),
      );
}
