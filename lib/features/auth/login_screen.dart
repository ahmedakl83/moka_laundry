import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import 'auth_provider.dart';
import 'admin_setup_screen.dart';
// import '../home/home_screen.dart'; // سننشئها لاحقاً

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).login(
            _usernameController.text,
            _passwordController.text,
          );

      if (success) {
        final authState = ref.read(authProvider);
        if (authState.isFirstRun) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminSetupScreen()),
            );
          }
        } else {
          // التوجه للشاشة الرئيسية
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تسجيل الدخول بنجاح')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_car_wash,
                    size: 80,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'اسم المستخدم',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال اسم المستخدم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال كلمة المرور';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (authState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        authState.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authState.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('تسجيل الدخول', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (authState.isFirstRun)
                    const Text(
                      'ملاحظة: هذا هو التشغيل الأول للتطبيق. استخدم بيانات المسؤول الافتراضية.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
