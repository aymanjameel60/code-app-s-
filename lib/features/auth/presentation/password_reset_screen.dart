import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});
  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final email = TextEditingController();
  final code = TextEditingController();
  final password = TextEditingController();
  bool sent = false, busy = false;

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (email.text.trim().isEmpty) {
      showSpikeToast(context, 'أدخل البريد الإلكتروني');
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email.text);
      if (mounted) {
        setState(() => sent = true);
        showSpikeToast(context, 'تم إرسال رمز الاستعادة إذا كان الحساب موجوداً');
      }
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _confirm() async {
    if (code.text.trim().length != 6 || password.text.length < 8) {
      showSpikeToast(context, 'أدخل رمزاً من 6 أرقام وكلمة مرور من 8 أحرف على الأقل');
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(email: email.text, code: code.text, password: password.text);
      if (mounted) {
        showSpikeToast(context, 'تم تغيير كلمة المرور');
        context.pop();
      }
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : const Color(0xFFE7E7E7);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(SpikeSpacing.page, SpikeSpacing.sm, SpikeSpacing.page, 0),
            child: SizedBox(
              height: 60,
              child: Stack(alignment: Alignment.center, children: [
                const Text('استعادة كلمة المرور', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                Align(alignment: Alignment.centerRight, child: IconButton(onPressed: () => context.pop(), icon: const Icon(LucideIcons.arrowRight, size: 22))),
              ]),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(SpikeSpacing.page, SpikeSpacing.sm, SpikeSpacing.page, SpikeSpacing.xl),
              children: [
                _field(email, 'البريد الإلكتروني', LucideIcons.mail, fill, enabled: !sent, keyboard: TextInputType.emailAddress),
                if (sent) ...[
                  const SizedBox(height: 12),
                  _field(code, 'رمز التحقق', LucideIcons.shieldCheck, fill, keyboard: TextInputType.number, maxLength: 6),
                  const SizedBox(height: 12),
                  _field(password, 'كلمة المرور الجديدة', LucideIcons.lockKeyhole, fill, obscure: true),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  height: 39,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: spikeRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                    onPressed: busy ? null : (sent ? _confirm : _request),
                    child: busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(sent ? 'تأكيد كلمة المرور' : 'إرسال رمز الاستعادة'),
                  ),
                ),
                if (sent) TextButton(onPressed: busy ? null : _request, child: const Text('إعادة إرسال الرمز', style: TextStyle(fontSize: 12))),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, IconData icon, Color fill, {bool obscure = false, bool enabled = true, TextInputType? keyboard, int? maxLength}) => SizedBox(
        height: 39,
        child: TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          keyboardType: keyboard,
          maxLength: maxLength,
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            filled: true,
            fillColor: fill,
            border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(22)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(22)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(22)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            suffixIcon: Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: Icon(icon, size: 20)),
            suffixIconConstraints: const BoxConstraints(minWidth: 42),
          ),
        ),
      );
}
