import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/providers.dart';
import '../../../core/media_url.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/async_state_widgets.dart';

class PersonalDataScreen extends ConsumerStatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  ConsumerState<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends ConsumerState<PersonalDataScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final code = TextEditingController();
  bool busy = false;
  bool seeded = false;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 1600);
    if (x == null) return;
    setState(() => busy = true);
    try {
      await ref.read(authRepositoryProvider).uploadAvatar(x.path);
      ref.invalidate(currentUserProvider);
      if (mounted) showSpikeToast(context, 'تم تحديث الصورة');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _saveName() async {
    if (name.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(name: name.text.trim());
      ref.invalidate(currentUserProvider);
      if (mounted) showSpikeToast(context, 'تم حفظ التعديلات');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _requestPhone() async {
    if (phone.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      await ref.read(authRepositoryProvider).requestPhoneChange(phone.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
      _showOtpSheet();
      showSpikeToast(context, 'تم إرسال رمز التحقق');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _verifyPhone() async {
    if (code.text.trim().length != 6) {
      showSpikeToast(context, 'أدخل رمز التحقق المكوّن من 6 أرقام');
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(authRepositoryProvider).verifyPhoneChange(code.text.trim());
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      Navigator.pop(context);
      showSpikeToast(context, 'تم تحديث رقم الجوال');
    } catch (e) {
      if (mounted) showSpikeToast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _showEditProfileSheet(String avatar, String email) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 22, 18, MediaQuery.viewInsetsOf(sheetContext).bottom + 28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Expanded(child: Text('تعديل الملف الشخصي', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700))),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : const Color(0xFFE7E7E7), shape: BoxShape.circle),
                child: IconButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(sheetContext), icon: const Icon(LucideIcons.x, size: 20)),
              ),
            ]),
            const SizedBox(height: 18),
            Center(
              child: Column(children: [
                Container(
                  width: 92,
                  height: 92,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF2C45D), width: 3)),
                  child: CircleAvatar(backgroundImage: avatar.isEmpty ? null : CachedNetworkImageProvider(avatar), child: avatar.isEmpty ? const Icon(LucideIcons.userRound) : null),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFF0C9), foregroundColor: const Color(0xFFB37B00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                    onPressed: busy ? null : _pickAvatar,
                    icon: const Icon(LucideIcons.camera, size: 17),
                    label: const Text('تغيير الصورة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            const Text('الاسم', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            SizedBox(height: 46, child: TextField(controller: name, decoration: const InputDecoration(hintText: 'الاسم الكامل'))),
            const SizedBox(height: 12),
            const Text('البريد الإلكتروني', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            SizedBox(height: 46, child: TextField(enabled: false, controller: TextEditingController(text: email))),
            const SizedBox(height: 16),
            SizedBox(
              height: 46,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: spikeRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: busy ? null : () async {
                  await _saveName();
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                icon: const Icon(LucideIcons.check, size: 18),
                label: const Text('حفظ التعديلات', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showPhoneSheet() {
    code.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 24, 18, MediaQuery.viewInsetsOf(sheetContext).bottom + 28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Center(child: Icon(LucideIcons.phone, size: 24)),
            const SizedBox(height: 12),
            const Text('تغيير رقم الجوال', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('أدخل رقم الجوال الجديد وسنرسل إليه رمز تحقق OTP لتأكيد الرقم.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: spikeMuted, height: 1.55)),
            const SizedBox(height: 16),
            SizedBox(height: 46, child: TextField(controller: phone, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: const InputDecoration(hintText: 'مثال: 967 700 000 000'))),
            const SizedBox(height: 14),
            SizedBox(height: 46, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: spikeRed), onPressed: busy ? null : _requestPhone, child: const Text('إرسال رمز التحقق'))),
          ]),
        ),
      ),
    );
  }

  void _showOtpSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 24, 18, MediaQuery.viewInsetsOf(sheetContext).bottom + 28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Center(child: Icon(LucideIcons.messageSquare, size: 24)),
            const SizedBox(height: 12),
            const Text('تأكيد رقم الجوال', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('أرسلنا رمز تحقق إلى ${phone.text.trim()}. أدخل الرمز المكوّن من 6 أرقام.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: spikeMuted, height: 1.55)),
            const SizedBox(height: 16),
            SizedBox(height: 50, child: TextField(controller: code, maxLength: 6, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: '••••••', counterText: ''))),
            const SizedBox(height: 14),
            SizedBox(height: 46, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: spikeRed), onPressed: busy ? null : _verifyPhone, child: const Text('تأكيد الرقم'))),
            TextButton(onPressed: busy ? null : _requestPhone, child: const Text('إعادة إرسال الرمز')),
          ]),
        ),
      ),
    );
  }

  String _avatarUrl(String raw) => resolveMediaUrl(raw) ?? raw;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(currentUserProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF1D1D1D) : Colors.white;

    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const SpikeLoading(),
          error: (e, _) => SpikeErrorState(message: e.toString(), onRetry: () => ref.invalidate(currentUserProvider)),
          data: (u) {
            if (u == null) return const SpikeEmptyState(message: 'سجّل الدخول أولاً');
            if (!seeded) {
              seeded = true;
              name.text = '${u['name'] ?? ''}';
              phone.text = '${u['phone'] ?? ''}';
            }
            final rawAvatar = '${u['avatar_url'] ?? u['avatarUrl'] ?? ''}'.trim();
            final avatar = _avatarUrl(rawAvatar);
            final email = '${u['email'] ?? ''}';
            final country = '${u['country'] ?? u['country_name'] ?? '—'}';

            return ListView(
              padding: const EdgeInsets.fromLTRB(17, 8, 17, 28),
              children: [
                _InnerHead(title: 'الملف الشخصي', onBack: () => context.canPop() ? context.pop() : context.go('/profile')),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 28, 18, 26),
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(25), border: Border.all(color: dark ? const Color(0xFF343434) : const Color(0xFFECECEC))),
                  child: Column(children: [
                    Container(
                      width: 108,
                      height: 108,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF2C45D), width: 3)),
                      child: CircleAvatar(backgroundImage: avatar.isEmpty ? null : CachedNetworkImageProvider(avatar), child: avatar.isEmpty ? const Icon(LucideIcons.userRound, size: 32) : null),
                    ),
                    const SizedBox(height: 17),
                    Text('${u['name'] ?? ''}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(email, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 13),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFEFF9EB), border: Border.all(color: const Color(0xFF9BD38D)), borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(LucideIcons.badgeCheck, size: 16, color: Color(0xFF58A94C)), SizedBox(width: 5), Text('تم التحقق', style: TextStyle(fontSize: 12, color: Color(0xFF58A94C)))]),
                    ),
                  ]),
                ),
                const SizedBox(height: 17),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: dark ? const Color(0xFF2A2A2A) : const Color(0xFFDEDEDE), foregroundColor: dark ? Colors.white70 : const Color(0xFF666666), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
                    onPressed: busy ? null : () => _showEditProfileSheet(avatar, email),
                    icon: const Icon(LucideIcons.pencil, size: 18),
                    label: const Text('تعديل الملف الشخصي', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 23),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('معلومات الحساب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                const SizedBox(height: 13),
                Container(
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(23), border: Border.all(color: dark ? const Color(0xFF343434) : const Color(0xFFECECEC))),
                  child: Column(children: [
                    _AccountRow(icon: LucideIcons.phone, label: 'الجوال', value: '${u['phone'] ?? '—'}', verified: true, onEdit: busy ? null : _showPhoneSheet),
                    Divider(height: 1, color: dark ? const Color(0xFF343434) : const Color(0xFFEEEEEE)),
                    _AccountRow(icon: LucideIcons.globe2, label: 'البلد', value: country),
                  ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InnerHead extends StatelessWidget {
  const _InnerHead({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
          height: 92,
          child: Stack(children: [
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 50,
                height: 40,
                child: Material(
                  color: Theme.of(context).brightness == Brightness.dark ? spikeDarkPanel : const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(borderRadius: BorderRadius.circular(22), onTap: onBack, child: const Icon(LucideIcons.arrowRight, size: 23)),
                ),
              ),
            ),
          ]),
        ),
        SizedBox(height: 60, child: Align(alignment: Alignment.centerRight, child: Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)))),
      ]);
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.icon, required this.label, required this.value, this.verified = false, this.onEdit});
  final IconData icon;
  final String label;
  final String value;
  final bool verified;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFFFF6DF), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 19, color: const Color(0xFFEDAE1E))),
            const SizedBox(width: 9),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11)), const SizedBox(height: 4), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))])),
            if (verified)
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFEFF9EB), border: Border.all(color: const Color(0xFFAAD99F)), borderRadius: BorderRadius.circular(15)), child: const Row(children: [Icon(LucideIcons.badgeCheck, size: 16, color: Color(0xFF5AAA4D)), SizedBox(width: 4), Text('تم التحقق', style: TextStyle(fontSize: 10, color: Color(0xFF5AAA4D)))])),
            if (onEdit != null) IconButton(onPressed: onEdit, icon: const Icon(LucideIcons.pencil, size: 17, color: Color(0xFFEDAE1E))),
          ]),
        ),
      );
}
