import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/api_config.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return SafeArea(
      child: user.when(
        loading: () => const SpikeLoading(),
        error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(currentUserProvider)),
        data: (u) {
          if (u == null) {
            return Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.userRound, size: 52),
                  const SizedBox(height: 16),
                  const Text('سجّل الدخول للوصول إلى حسابك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  SizedBox(width: double.infinity, height: 38, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: spikeRed), onPressed: () => context.push('/login'), child: const Text('تسجيل الدخول'))),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => context.push('/signup'), child: const Text('إنشاء حساب جديد')),
                ],
              ),
            );
          }

          final raw = '${u['avatar_url'] ?? u['avatarUrl'] ?? ''}';
          final avatar = raw.startsWith('/uploads/') ? '${ApiConfig.assetBaseUrl}$raw' : raw;
          final name = '${u['name'] ?? ''}';
          final phone = '${u['phone'] ?? ''}';
          final email = '${u['email'] ?? ''}';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const _SimpleTitle('الملف الشخصي'),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: spikeRed,
                      backgroundImage: avatar.isEmpty ? null : CachedNetworkImageProvider(avatar),
                      child: avatar.isEmpty ? const Icon(LucideIcons.userRound, size: 28, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'مرحباً $name${phone.isNotEmpty ? '\n$phone' : ''}${email.isNotEmpty ? '\n$email' : ''}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.7),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: Column(
                  children: [
                    _row(context, LucideIcons.userRound, 'البيانات الشخصية', () => context.push('/personal-data')),
                    const SizedBox(height: 16),
                    _row(context, LucideIcons.heart, 'المفضلة', () => context.push('/favorites')),
                    const SizedBox(height: 16),
                    _row(context, LucideIcons.packageCheck, 'طلباتي', () => context.push('/orders')),
                    const SizedBox(height: 16),
                    _row(context, LucideIcons.messagesSquare, 'خدمة العملاء', () => context.push('/support')),
                    const SizedBox(height: 16),
                    _row(context, LucideIcons.shieldCheck, 'سياسة الخصوصية', () => context.push('/privacy')),
                    const SizedBox(height: 16),
                    _row(context, LucideIcons.settings2, 'الإعدادات المتقدمة', () => context.push('/settings')),
                    const SizedBox(height: 16),
                    _row(
                      context,
                      LucideIcons.logOut,
                      'تسجيل الخروج',
                      () async {
                        await ref.read(authRepositoryProvider).logout();
                        ref.invalidate(currentUserProvider);
                        if (context.mounted) context.go('/profile');
                      },
                      danger: true,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? spikeDarkPanel : spikePanel,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 39,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Icon(icon, size: 21, color: danger ? spikeRed : Theme.of(context).colorScheme.onSurface),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: danger ? spikeRed : null))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleTitle extends StatelessWidget {
  const _SimpleTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => const SizedBox(height: 60, child: Center(child: Text('الملف الشخصي', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700))));
}
