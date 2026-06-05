import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import 'auth_provider.dart';

class AdminSetupScreen extends ConsumerStatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  ConsumerState<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends ConsumerState<AdminSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSetup() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).completeAdminSetup(
            _nameController.text,
            _emailController.text,
            _usernameController.text,
            _passwordController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إعداد حساب المدير بنجاح')),
        );
        // التوجه للشاشة الرئيسية سيتم تلقائياً عبر مراقبة حالة الـ Auth في main.dart
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد حساب المدير'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مرحباً بك! يرجى تحديث بياناتك لتعزيز أمان التطبيق وتفعيل ميزات النسخ الاحتياطي.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم الحقيقي للمدير',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال اسمك' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'بريد جوجل الإلكتروني',
                  hintText: 'example@gmail.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'يرجى إدخال بريد جوجل صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'تغيير بيانات تسجيل الدخول الافتراضية:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'اسم مستخدم جديد',
                  prefixIcon: const Icon(Icons.account_circle),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال اسم مستخدم جديد' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة مرور جديدة',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.length < 6 ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: authState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('حفظ البيانات والبدء', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
