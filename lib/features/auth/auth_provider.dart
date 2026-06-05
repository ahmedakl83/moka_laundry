import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../../models/user_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isFirstRun;
  final String? error;
  final String? clientInviteCode;

  AuthState({
    this.user,
    this.isLoading = false,
    this.isFirstRun = true,
    this.error,
    this.clientInviteCode,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isFirstRun,
    String? error,
    String? clientInviteCode,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isFirstRun: isFirstRun ?? this.isFirstRun,
      error: error,
      clientInviteCode: clientInviteCode ?? this.clientInviteCode,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('isFirstRun') ?? true;

    final savedUsername = prefs.getString('admin_username');
    final isClient = prefs.getBool('is_client_device') ?? false;

    if (isClient) {
      state = state.copyWith(
        user: UserModel(id: 'client_id', name: 'جهاز الموظف', username: 'client', email: '', role: UserRole.dataEntry),
        isFirstRun: false
      );
      return;
    }

    if (!isFirstRun && savedUsername != null) {
      final user = UserModel(
        id: 'admin_id',
        name: prefs.getString('admin_name') ?? 'المدير',
        username: savedUsername,
        email: prefs.getString('admin_email') ?? '',
        role: UserRole.admin,
      );
      state = state.copyWith(user: user, isFirstRun: false);
    } else {
      state = state.copyWith(isFirstRun: isFirstRun);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final prefs = await SharedPreferences.getInstance();

    await Future.delayed(const Duration(seconds: 1));

    // تسجيل دخول كـ Client عن طريق الكود
    if (username == 'code') {
      final activeCode = prefs.getString('active_invite_code');
      if (activeCode != null && password == activeCode) {
        await prefs.setBool('is_client_device', true);
        state = state.copyWith(
          user: UserModel(id: 'client_id', name: 'جهاز الموظف', username: 'client', email: '', role: UserRole.dataEntry),
          isLoading: false,
          isFirstRun: false
        );
        return true;
      }
    }

    if (state.isFirstRun) {
      if (username == 'admin' && password == 'admin123') {
        state = state.copyWith(isLoading: false);
        return true;
      }
    } else {
      final savedUser = prefs.getString('admin_username');
      final savedPass = prefs.getString('admin_password');

      if (username == savedUser && password == savedPass) {
        final user = UserModel(
          id: 'admin_id',
          name: prefs.getString('admin_name') ?? 'المدير',
          username: username,
          email: prefs.getString('admin_email') ?? '',
          role: UserRole.admin,
        );
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }
    }

    state = state.copyWith(isLoading: false, error: 'خطأ في البيانات أو الكود');
    return false;
  }

  Future<String> generateInviteCode() async {
    final code = (Random().nextInt(900000) + 100000).toString(); // كود من 6 أرقام
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_invite_code', code);
    state = state.copyWith(clientInviteCode: code);
    return code;
  }

  Future<void> completeAdminSetup(String name, String email, String newUsername, String newPassword) async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false);
    await prefs.setString('admin_name', name);
    await prefs.setString('admin_email', email);
    await prefs.setString('admin_username', newUsername);
    await prefs.setString('admin_password', newPassword);

    final user = UserModel(id: 'admin_id', name: name, username: newUsername, email: email, role: UserRole.admin);
    state = state.copyWith(user: user, isLoading: false, isFirstRun: false);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_client_device');
    state = state.copyWith(user: null);
  }
}
