import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(17, 8, 17, 32), children: [
        SizedBox(height: 56, child: Stack(alignment: Alignment.center, children: [
          const Text('سياسة الخصوصية', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
          Align(alignment: Alignment.centerRight, child: IconButton(onPressed: () => context.canPop() ? context.pop() : context.go('/profile'), icon: const Icon(LucideIcons.arrowRight))),
        ])),
        const SizedBox(height: 18),
        const Text('خصوصيتك مهمة لنا', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        const Text('نستخدم بيانات الحساب والعنوان وبيانات الطلب فقط لتشغيل خدمة Spike، متابعة الطلبات، وتقديم الدعم. لا نشارك بياناتك الشخصية خارج نطاق تقديم الخدمة إلا عندما يتطلب ذلك تنفيذ الطلب أو يفرضه القانون.', style: TextStyle(fontSize: 13, height: 1.8)),
        const SizedBox(height: 20),
        const Text('البيانات التي نديرها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        const Text('الاسم، رقم الهاتف، العناوين، الطلبات، والمفضلة. يمكنك تعديل بياناتك من الملف الشخصي أو التواصل مع الدعم بخصوص أي طلب متعلق بها.', style: TextStyle(fontSize: 13, height: 1.8)),
      ]),
    ),
  );
}
