import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 8, 17, 32),
          children: [
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
                        onTap: () => context.canPop() ? context.pop() : context.go('/profile'),
                        child: const Icon(LucideIcons.arrowRight, size: 23),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(
              height: 60,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('سياسة الخصوصية', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
              ),
            ),
            const _Section(
              title: 'سياسة الخصوصية',
              body: 'نحن في [اسم التطبيق] نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية والمحافظة على سريتها. توضح هذه السياسة كيفية جمع واستخدام وحماية المعلومات عند استخدامك للتطبيق.',
            ),
            const _Section(
              title: 'المعلومات التي نجمعها',
              body: 'قد نقوم بجمع بعض المعلومات اللازمة لتقديم خدماتنا، مثل الاسم، رقم الهاتف، البريد الإلكتروني، عنوان التوصيل، ومعلومات الطلبات، وبعض بيانات استخدام التطبيق والجهاز.',
            ),
            const _Section(
              title: 'كيفية استخدام المعلومات',
              body: 'نستخدم بياناتك لإنشاء وإدارة حسابك، معالجة الطلبات وتوصيلها، تحسين تجربة الاستخدام، تقديم الدعم، إرسال الإشعارات المتعلقة بطلبك، والوفاء بالمتطلبات القانونية عند الحاجة.',
            ),
            const _Section(
              title: 'معلومات الدفع',
              body: 'قد تتم معالجة عمليات الدفع من خلال مزودي خدمات دفع معتمدين. لا يقوم التطبيق بالضرورة بحفظ بيانات البطاقة البنكية الكاملة.',
            ),
            const _Section(
              title: 'مشاركة البيانات',
              body: 'لا نقوم ببيع بياناتك الشخصية. وقد تتم مشاركة البيانات الضرورية مع مزودي الخدمات مثل شركات التوصيل والدفع والاستضافة.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            Text(body, style: const TextStyle(fontSize: 12, height: 1.8)),
          ],
        ),
      );
}
