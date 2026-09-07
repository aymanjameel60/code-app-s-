import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final ctrl = ref.read(appSettingsProvider.notifier);
    final currencies = ref.watch(currenciesProvider);
    final ar = settings.language == 'ar';

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 8, 17, 4),
            child: SizedBox(
              height: 46,
              child: Stack(alignment: Alignment.center, children: [
                Text(ar ? 'الإعدادات المتقدمة' : 'Advanced settings', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(onPressed: () => context.pop(), icon: const Icon(LucideIcons.arrowRight, size: 22)),
                ),
              ]),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(17, 8, 17, 28),
              children: [
                _SettingsSection(
                  icon: LucideIcons.sunMoon,
                  title: ar ? 'المظهر' : 'Appearance',
                  subtitle: ar ? 'اختر مظهر التطبيق' : 'Choose app appearance',
                  child: Row(children: [
                    Expanded(
                      child: _ThemeOption(
                        title: ar ? 'فاتح' : 'Light',
                        selected: settings.themeMode == ThemeMode.light,
                        darkPreview: false,
                        onTap: () => ctrl.setTheme(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _ThemeOption(
                        title: ar ? 'داكن' : 'Dark',
                        selected: settings.themeMode == ThemeMode.dark,
                        darkPreview: true,
                        onTap: () => ctrl.setTheme(ThemeMode.dark),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                _SettingsSection(
                  icon: LucideIcons.languages,
                  title: ar ? 'اللغة' : 'Language',
                  subtitle: ar ? 'لغة واجهة التطبيق' : 'App interface language',
                  child: Row(children: [
                    Expanded(
                      child: _ChoiceCard(
                        title: 'العربية',
                        subtitle: 'AR',
                        selected: settings.language == 'ar',
                        onTap: () => ctrl.setLanguage('ar'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _ChoiceCard(
                        title: 'English',
                        subtitle: 'EN',
                        selected: settings.language == 'en',
                        onTap: () => ctrl.setLanguage('en'),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                _SettingsSection(
                  icon: LucideIcons.coins,
                  title: ar ? 'العملة' : 'Currency',
                  subtitle: ar ? 'العملات المفعلة من النظام' : 'Backend-enabled currencies',
                  child: currencies.when(
                    loading: () => const Padding(padding: EdgeInsets.all(12), child: SpikeLoading()),
                    error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(currenciesProvider)),
                    data: (items) {
                      if (items.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Text(ar ? 'لا توجد عملات متاحة حالياً' : 'No currencies are available', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: spikeMuted)),
                        );
                      }
                      return Column(children: [
                        for (int i = 0; i < items.length; i++) ...[
                          _CurrencyOption(
                            name: items[i].name,
                            code: items[i].code,
                            selected: settings.currency == items[i].code,
                            onTap: () => ctrl.setCurrency(items[i].code),
                          ),
                          if (i < items.length - 1) const SizedBox(height: 8),
                        ],
                      ]);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : spikePanel,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(LucideIcons.info, size: 17, color: spikeMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ar
                            ? 'يتم حفظ اختياراتك على هذا الجهاز. العملة المختارة تستخدم في الدفع وتبقى مرتبطة بالعملات المفعلة من الخادم.'
                            : 'Your choices are saved on this device. Checkout uses the selected backend-enabled currency.',
                        style: const TextStyle(fontSize: 8.5, height: 1.55, color: spikeMuted),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.icon, required this.title, required this.subtitle, required this.child});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final panel = dark ? spikeDarkPanel : spikePanel;
    final inner = dark ? const Color(0xFF282828) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: inner, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 9, color: spikeMuted, height: 1.5)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.title, required this.selected, required this.darkPreview, required this.onTap});

  final String title;
  final bool selected;
  final bool darkPreview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inner = dark ? const Color(0xFF282828) : Colors.white;
    final border = selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: inner, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
            _RadioDot(selected: selected),
          ]),
          const SizedBox(height: 8),
          Container(
            height: 66,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: darkPreview ? const Color(0xFF151515) : const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(13)),
            child: Column(children: [
              Container(height: 12, decoration: BoxDecoration(color: darkPreview ? const Color(0xFF303030) : Colors.white, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 6),
              Expanded(
                child: Row(children: [
                  Expanded(child: Container(decoration: BoxDecoration(color: darkPreview ? const Color(0xFF303030) : Colors.white, borderRadius: BorderRadius.circular(6)))),
                  const SizedBox(width: 6),
                  Expanded(child: Container(decoration: BoxDecoration(color: darkPreview ? const Color(0xFF303030) : Colors.white, borderRadius: BorderRadius.circular(6)))),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.title, required this.subtitle, required this.selected, required this.onTap});

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inner = dark ? const Color(0xFF282828) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: inner,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent),
        ),
        child: Row(children: [
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 8, color: spikeMuted)),
            ]),
          ),
          _RadioDot(selected: selected),
        ]),
      ),
    );
  }
}

class _CurrencyOption extends StatelessWidget {
  const _CurrencyOption({required this.name, required this.code, required this.selected, required this.onTap});

  final String name;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inner = dark ? const Color(0xFF282828) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: inner,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: selected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).dividerColor),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(code, style: const TextStyle(fontSize: 8, color: spikeMuted)),
            ]),
          ),
          Text(code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(width: 9),
          _RadioDot(selected: selected),
        ]),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: 17,
      height: 17,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? color : spikeMuted, width: 1.5)),
      child: selected ? DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: color)) : null,
    );
  }
}
