import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  ThemeMode? _theme;
  String? _language;
  String? _currency;

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(appSettingsProvider);
    final theme = _theme ?? saved.themeMode;
    final language = _language ?? saved.language;
    final currency = _currency ?? saved.currency;
    final ar = language == 'ar';
    final currencies = ref.watch(currenciesProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

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
              SizedBox(height: 60, child: Align(alignment: Alignment.centerRight, child: Text(ar ? 'الإعدادات المتقدمة' : 'Advanced settings', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)))),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(17, 0, 17, 28),
              children: [
                _Section(
                  icon: LucideIcons.sunMoon,
                  title: ar ? 'المظهر' : 'Appearance',
                  subtitle: ar ? 'اختر الوضع المناسب لك' : 'Choose your preferred appearance',
                  child: Row(children: [
                    Expanded(child: _ThemeOption(title: ar ? 'الوضع الفاتح' : 'Light mode', selected: theme == ThemeMode.light, darkPreview: false, onTap: () => setState(() => _theme = ThemeMode.light))),
                    const SizedBox(width: 9),
                    Expanded(child: _ThemeOption(title: ar ? 'الوضع الداكن' : 'Dark mode', selected: theme == ThemeMode.dark, darkPreview: true, onTap: () => setState(() => _theme = ThemeMode.dark))),
                  ]),
                ),
                const SizedBox(height: 12),
                _Section(
                  icon: LucideIcons.languages,
                  title: ar ? 'اللغة' : 'Language',
                  subtitle: ar ? 'لغة واجهة التطبيق' : 'App interface language',
                  child: Row(children: [
                    Expanded(child: _Choice(title: 'العربية', subtitle: 'Arabic', selected: language == 'ar', onTap: () => setState(() => _language = 'ar'))),
                    const SizedBox(width: 9),
                    Expanded(child: _Choice(title: 'English', subtitle: 'الإنجليزية', selected: language == 'en', onTap: () => setState(() => _language = 'en'))),
                  ]),
                ),
                const SizedBox(height: 12),
                _Section(
                  icon: LucideIcons.coins,
                  title: ar ? 'العملة' : 'Currency',
                  subtitle: ar ? 'اختر العملة التي تريد عرض الأسعار بها' : 'Choose the currency used to display prices',
                  child: currencies.when(
                    loading: () => const Padding(padding: EdgeInsets.all(12), child: SpikeLoading()),
                    error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(currenciesProvider)),
                    data: (items) {
                      final selected = items.where((x) => x.code == currency).firstOrNull;
                      return InkWell(
                        onTap: items.isEmpty ? null : () => _currencySheet(items, currency, ar),
                        borderRadius: BorderRadius.circular(17),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 58),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(color: dark ? const Color(0xFF282828) : Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: Theme.of(context).dividerColor)),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(selected?.name ?? currency, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(currency, style: const TextStyle(fontSize: 8, color: spikeMuted)),
                            ])),
                            const Icon(LucideIcons.chevronDown, size: 18),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: dark ? spikeDarkPanel : spikePanel, borderRadius: BorderRadius.circular(24)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ar ? 'حذف الحساب' : 'Delete account', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(ar ? 'ميزة حذف الحساب غير مفعلة من الخادم حالياً.' : 'Account deletion is not enabled by the server yet.', style: const TextStyle(fontSize: 9, color: spikeMuted, height: 1.5)),
                    ])),
                    const SizedBox(width: 10),
                    OutlinedButton(onPressed: null, style: OutlinedButton.styleFrom(foregroundColor: spikeRed), child: Text(ar ? 'حذف الحساب' : 'Delete account')),
                  ]),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: spikeRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () async {
                      final ctrl = ref.read(appSettingsProvider.notifier);
                      await ctrl.setTheme(theme);
                      await ctrl.setLanguage(language);
                      await ctrl.setCurrency(currency);
                      if (mounted) {
                        setState(() { _theme = null; _language = null; _currency = null; });
                        showSpikeToast(context, ar ? 'تم حفظ التعديلات' : 'Changes saved');
                      }
                    },
                    child: Text(ar ? 'حفظ التعديلات' : 'Save changes', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _currencySheet(List items, String selectedCode, bool ar) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text(ar ? 'اختر العملة' : 'Choose currency', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(LucideIcons.x, size: 20)),
            ]),
            for (final item in items)
              InkWell(
                onTap: () { setState(() => _currency = item.code); Navigator.pop(sheetContext); },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 58),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), Text(item.code, style: const TextStyle(fontSize: 8, color: spikeMuted))])),
                    _Radio(selected: item.code == (_currency ?? selectedCode)),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.subtitle, required this.child});
  final IconData icon; final String title; final String subtitle; final Widget child;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: dark ? spikeDarkPanel : spikePanel, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: dark ? const Color(0xFF282828) : Colors.white, borderRadius: BorderRadius.circular(14)), child: Icon(icon, size: 18)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 9, color: spikeMuted, height: 1.5))])),
        ]),
        const SizedBox(height: 14), child,
      ]),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.title, required this.selected, required this.darkPreview, required this.onTap});
  final String title; final bool selected; final bool darkPreview; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF282828) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent)),
      child: Column(children: [
        Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))), _Radio(selected: selected)]),
        const SizedBox(height: 8),
        Container(height: 66, padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: darkPreview ? const Color(0xFF151515) : const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(13)), child: Column(children: [Container(height: 12, decoration: BoxDecoration(color: darkPreview ? const Color(0xFF303030) : Colors.white, borderRadius: BorderRadius.circular(6))), const SizedBox(height: 6), Expanded(child: Row(children: [Expanded(child: Container(decoration: BoxDecoration(color: darkPreview ? const Color(0xFF303030) : Colors.white, borderRadius: BorderRadius.circular(6)))), const SizedBox(width: 6), Expanded(child: Container(decoration: BoxDecoration(color: darkPreview ? const Color(0xFF303030) : Colors.white, borderRadius: BorderRadius.circular(6))))]))])),
      ]),
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({required this.title, required this.subtitle, required this.selected, required this.onTap});
  final String title; final String subtitle; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(17),
    child: Container(height: 54, padding: const EdgeInsets.symmetric(horizontal: 13), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF282828) : Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent)), child: Row(children: [Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), Text(subtitle, style: const TextStyle(fontSize: 8, color: spikeMuted))])), _Radio(selected: selected)])),
  );
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected}); final bool selected;
  @override
  Widget build(BuildContext context) { final c = Theme.of(context).colorScheme.onSurface; return Container(width: 17, height: 17, padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? c : spikeMuted, width: 1.5)), child: selected ? DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: c)) : null); }
}

extension _FirstOrNull<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
