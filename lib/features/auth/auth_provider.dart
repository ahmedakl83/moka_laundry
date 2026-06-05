import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isFirstRun;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.isFirstRun = true,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isFirstRun,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isFirstRun: isFirstRun ?? this.isFirstRun,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    checkFirstRun();
  }

  Future<void> checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('isFirstRun') ?? true;
    state = state.copyWith(isFirstRun: isFirstRun);
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    // محاكاة تسجيل الدخول للآن حتى نربط Firebase
    await Future.delayed(const Duration(seconds: 1));

    if (username == 'admin' && password == 'admin123') {
      if (state.isFirstRun) {
        state = state.copyWith(isLoading: false);
        return true; // يجب التوجه لشاشة الإعداد
      }

      final user = UserModel(
        id: 'admin_id',
        name: 'المدير',
        username: 'admin',
        email: 'admin@moka.com',
        role: UserRole.admin,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: 'خطأ في اسم المستخدم أو كلمة المرور');
      return false;
    }
  }

  Future<void> completeAdminSetup(String name, String email, String newUsername, String newPassword) async {
    state = state.copyWith(isLoading: true);

    // حفظ البيانات محلياً وتغيير حالة أول تشغيل
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false);
    await prefs.setString('admin_name', name);
    await prefs.setString('admin_email', email);
    await prefs.setString('admin_username', newUsername);
    await prefs.setString('admin_password', newPassword);

    final user = UserModel(
      id: 'admin_id',
      name: name,
      username: newUsername,
      email: email,
      role: UserRole.admin,
    );

    state = state.copyWith(user: user, isLoading: false, isFirstRun: false);
  }
}
