import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/media_url.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(unreadNotificationsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: user.when(
        loading: () => const SpikeLoading(),
        error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(currentUserProvider)),
        data: (u) {
          final current = u ?? <String, dynamic>{};
          final raw = '${current['avatar_url'] ?? current['avatarUrl'] ?? ''}';
          final avatar = resolveMediaUrl(raw) ?? '';
          final name = '${current['name'] ?? ''}';
          final phone = '${current['phone'] ?? ''}';
          final rawEmail = '${current['email'] ?? ''}';
          final email = rawEmail.endsWith('@customer.spike.local') ? '' : rawEmail;
          final logged = u != null;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 8, 17, 0),
                child: SizedBox(
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              onPressed: () => context.push('/notifications'),
                              icon: const Icon(LucideIcons.bell, size: 22),
                            ),
                            if (unread > 0)
                              Positioned(
                                left: -2,
                                top: -1,
                                child: Container(
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(color: spikeRed, shape: BoxShape.circle),
                                  child: Text(
                                    unread > 99 ? '99+' : '$unread',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 12, 17, 16),
                child: Row(children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: spikeRed,
                    backgroundImage: avatar.isEmpty ? null : CachedNetworkImageProvider(avatar),
                    child: avatar.isEmpty ? const Icon(LucideIcons.userRound, size: 28, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          logged ? 'مرحباً $name' : 'مرحباً بك في Spike',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.35),
                        ),
                        const SizedBox(height: 2),
                        if (logged && phone.isNotEmpty)
                          Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E8E), height: 1.45)),
                        if (logged && email.isNotEmpty)
                          Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E8E), height: 1.45)),
                        if (!logged)
                          const Text(
                            'سجّل الدخول لمتابعة طلباتك وبياناتك',
                            style: TextStyle(fontSize: 11, color: Color(0xFF8E8E8E), height: 1.45),
                          ),
                      ],
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: Column(children: [
                  _row(context, LucideIcons.userRound, 'البيانات الشخصية', () => context.push('/personal-data')),
                  const SizedBox(height: 12),
                  _row(context, LucideIcons.store, 'المتاجر', () => context.push('/stores')),
                  const SizedBox(height: 12),
                  _row(context, LucideIcons.walletCards, 'محفظتي', () => logged ? context.push('/wallet') : context.push('/login')),
                  const SizedBox(height: 12),
                  _row(context, LucideIcons.heart, 'المفضلة', () => context.push('/favorites')),
                  const SizedBox(height: 12),
                  _row(context, LucideIcons.packageCheck, 'طلباتي', () => context.push('/orders')),
                  const SizedBox(height: 12),
                  _row(context, LucideIcons.messagesSquare, 'خدمة العملاء', () => context.push('/support')),
                  const SizedBox(height: 12),
                  _row(context, LucideIcons.shieldCheck, 'سياسة الخصوصية', () => context.push('/privacy')),
                  const SizedBox(height: 12),
                  _row(context, LucideIcons.settings2, 'الإعدادات المتقدمة', () => context.push('/settings')),
                  const SizedBox(height: 12),
                  _row(context, LucideIcons.store, 'سجّل كتاجر', () => context.push('/vendor-registration'), featured: true),
                  const SizedBox(height: 12),
                  _row(
                    context,
                    logged ? LucideIcons.logOut : LucideIcons.logIn,
                    logged ? 'تسجيل الخروج' : 'تسجيل الدخول',
                    () async {
                      if (!logged) {
                        context.push('/login');
                        return;
                      }
                      await ref.read(authRepositoryProvider).logout();
                      ref.invalidate(currentUserProvider);
                      if (context.mounted) context.go('/profile');
                    },
                    danger: logged,
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool danger = false, bool featured = false}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? spikeDarkPanel : spikePanel,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: SizedBox(
          height: 39,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(children: [
              SizedBox(
                width: 21,
                height: 21,
                child: Icon(icon, size: 21, color: danger ? spikeRed : Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: danger ? spikeRed : null),
                ),
              ),
              if (featured)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: spikeRed, borderRadius: BorderRadius.circular(12)),
                  child: const Text('جديد', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
