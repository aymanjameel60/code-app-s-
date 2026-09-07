import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final ctrl = ref.read(appSettingsProvider.notifier);
    final currencies = ref.watch(currenciesProvider);
    final ar = s.language == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'الإعدادات المتقدمة' : 'Advanced settings'), centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(17), children: [
        _section(context, title: ar ? 'المظهر' : 'Appearance', subtitle: ar ? 'اختر الوضع المناسب لك' : 'Choose your preferred appearance', child: Row(children: [
          Expanded(child: _choice(context, label: ar ? 'الوضع الفاتح' : 'Light mode', selected: s.themeMode == ThemeMode.light, onTap: () => ctrl.setTheme(ThemeMode.light))),
          const SizedBox(width: 8),
          Expanded(child: _choice(context, label: ar ? 'الوضع الداكن' : 'Dark mode', selected: s.themeMode == ThemeMode.dark, onTap: () => ctrl.setTheme(ThemeMode.dark))),
        ])),
        const SizedBox(height: 12),
        _section(context, title: ar ? 'اللغة' : 'Language', subtitle: ar ? 'لغة واجهة التطبيق' : 'App interface language', child: Column(children: [
          _radioRow('العربية', 'Arabic', s.language == 'ar', () => ctrl.setLanguage('ar')),
          _radioRow('English', 'الإنجليزية', s.language == 'en', () => ctrl.setLanguage('en')),
        ])),
        const SizedBox(height: 12),
        _section(
          context,
          title: ar ? 'العملة' : 'Currency',
          subtitle: ar ? 'اختر العملة التي تريد عرض الأسعار بها' : 'Choose the currency used to display prices',
          child: currencies.when(
            loading: () => const Padding(padding: EdgeInsets.all(12), child: SpikeLoading()),
            error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(currenciesProvider)),
            data: (items) => DropdownButtonFormField<String>(
              initialValue: items.any((x) => x.code == s.currency) ? s.currency : (items.isNotEmpty ? items.first.code : null),
              decoration: InputDecoration(filled: true, fillColor: Theme.of(context).colorScheme.surface, border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(18)))),
              items: items.map((c) => DropdownMenuItem(value: c.code, child: Text('${c.name} (${c.code})'))).toList(),
              onChanged: (v) { if (v != null) ctrl.setCurrency(v); },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(ar ? 'يتم حفظ هذه الإعدادات على الجهاز وتطبيق المظهر واللغة مباشرة. العملة المختارة تُستخدم في عملية الدفع وتبقى مرتبطة بالعملات المفعلة من الخادم.' : 'These settings are saved on this device. Theme and language apply immediately, and checkout uses the selected backend-enabled currency.', style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }

  Widget _section(BuildContext context, {required String title, required String subtitle, required Widget child}) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text(subtitle, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 12), child]));
  Widget _choice(BuildContext context, {required String label, required bool selected, required VoidCallback onTap}) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(height: 76, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: selected ? Border.all(color: spikeRed, width: 1.5) : null), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? spikeRed : null), const SizedBox(height: 5), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))])));
  Widget _radioRow(String title, String subtitle, bool selected, VoidCallback onTap) => ListTile(contentPadding: EdgeInsets.zero, onTap: onTap, title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? spikeRed : null));
}
