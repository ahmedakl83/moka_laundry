import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import 'auth_provider.dart';

class ClientInviteScreen extends ConsumerWidget {
  const ClientInviteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteCode = ref.watch(authProvider).clientInviteCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ربط جهاز إضافي'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, size: 100, color: AppColors.primaryBlue),
              const SizedBox(height: 24),
              const Text(
                'لربط جهاز الموظف، اختر "دخول بواسطة كود" من شاشة الدخول في الجهاز الآخر وأدخل الكود التالي:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (inviteCode != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryBlue),
                  ),
                  child: Text(
                    inviteCode,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => ref.read(authProvider.notifier).generateInviteCode(),
                  child: const Text('توليد كود الربط'),
                ),
              const SizedBox(height: 40),
              const Text(
                'ملاحظة: هذا الكود صالح لربط جهاز واحد فقط ويُستخدم لمرة واحدة.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
