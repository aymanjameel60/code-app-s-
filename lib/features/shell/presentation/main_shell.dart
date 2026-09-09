import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  int get _index {
    if (location.startsWith('/offers')) return 1;
    if (location.startsWith('/cart') || location.startsWith('/checkout') || location.startsWith('/success')) return 3;
    if (const ['/profile', '/personal-data', '/privacy', '/settings', '/favorites', '/orders', '/order/', '/returns-refunds', '/support', '/login', '/signup'].any(location.startsWith)) return 0;
    return 2;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cartCount = ref.watch(cartCountProvider).valueOrNull ?? 0;
    return Scaffold(
      endDrawer: const _SpikeDrawer(),
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: dark ? spikeDarkPanel : Colors.white,
            border: Border(top: BorderSide(color: dark ? Colors.white10 : const Color(0xFFEEEEEE))),
          ),
          child: Builder(builder: (shellContext) => Row(children: [
            _item(shellContext, 0, LucideIcons.userRound, '/profile'),
            _item(shellContext, 1, LucideIcons.badgePercent, '/offers'),
            _item(shellContext, 2, LucideIcons.home, '/'),
            _item(shellContext, 3, LucideIcons.shoppingBag, '/cart', badge: cartCount),
          ])),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, IconData icon, String route, {int badge = 0}) {
    final selected = _index == index;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: InkWell(
        onTap: () { if (!selected) context.go(route); },
        child: Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 24, color: selected ? onSurface : onSurface.withValues(alpha: .45)),
                if (badge > 0)
                  Positioned(
                    left: 1,
                    top: 1,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: spikeRed, borderRadius: BorderRadius.circular(10)),
                      child: Text(badge > 99 ? '99+' : '$badge', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700, height: 1)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpikeDrawer extends ConsumerWidget {
  const _SpikeDrawer();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = user == null ? 'مرحباً بك في Spike' : (user['name'] ?? 'حسابي').toString();
    return Drawer(backgroundColor: dark ? spikeDarkPanel : Colors.white, child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 14, 14, 20), child: Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, size: 22)), const Spacer(), const Text('SPIKE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.5))])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      if (user == null) Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 16), child: SizedBox(height: 39, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: spikeRed), onPressed: () { Navigator.pop(context); context.push('/login'); }, child: const Text('تسجيل الدخول')))) else const SizedBox(height: 16),
      Divider(color: Theme.of(context).dividerColor, height: 1), const SizedBox(height: 8),
      _DrawerItem(icon: LucideIcons.home, label: 'الرئيسية', onTap: () => _go(context, '/')),
      _DrawerItem(icon: LucideIcons.store, label: 'المتاجر', onTap: () => _go(context, '/stores')),
      _DrawerItem(icon: LucideIcons.badgePercent, label: 'العروض والخصومات', onTap: () => _go(context, '/offers')),
      _DrawerItem(icon: LucideIcons.heart, label: 'المفضلة', onTap: () => _protectedGo(context, user, '/favorites')),
      _DrawerItem(icon: LucideIcons.mapPin, label: 'عناويني', onTap: () => _protectedGo(context, user, '/addresses')),
      _DrawerItem(icon: LucideIcons.messageCircle, label: 'خدمة العملاء', onTap: () => _protectedGo(context, user, '/support')),
      const Spacer(),
      _DrawerItem(icon: LucideIcons.settings2, label: 'الإعدادات', onTap: () => _protectedGo(context, user, '/settings')),
      if (user != null) _DrawerItem(icon: LucideIcons.logOut, label: 'تسجيل الخروج', onTap: () => _logout(context, ref)),
      const SizedBox(height: 16),
    ])));
  }
  Future<void> _logout(BuildContext context, WidgetRef ref) async { Navigator.pop(context); await ref.read(authRepositoryProvider).logout(); ref.invalidate(currentUserProvider); if (context.mounted) context.go('/'); }
  void _go(BuildContext context, String route) { Navigator.pop(context); context.go(route); }
  void _protectedGo(BuildContext context, Map<String, dynamic>? user, String route) { Navigator.pop(context); if (user == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سجّل الدخول أولاً للمتابعة'))); context.push('/login'); } else { context.go(route); } }
}
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, size: 21),
    title: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 22),
    minTileHeight: 39,
  );
}
