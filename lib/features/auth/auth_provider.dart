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

  AuthState({this.user, this.isLoading = false, this.isFirstRun = true, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, bool? isFirstRun, String? error}) {
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
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('isFirstRun') ?? true;
    state = state.copyWith(isFirstRun: isFirstRun);
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final prefs = await SharedPreferences.getInstance();
    await Future.delayed(const Duration(milliseconds: 500));

    if (state.isFirstRun) {
      if (username == 'admin' && password == 'admin123') {
        state = state.copyWith(isLoading: false);
        return true;
      }
    } else {
      final savedUser = prefs.getString('admin_username');
      final savedPass = prefs.getString('admin_password');
      if (username == savedUser && password == savedPass) {
        state = state.copyWith(
          user: UserModel(
            id: 'admin_id',
            name: prefs.getString('admin_name') ?? 'المدير',
            username: username,
            email: prefs.getString('admin_email') ?? '',
            role: UserRole.admin,
          ),
          isLoading: false,
        );
        return true;
      }
    }
    state = state.copyWith(isLoading: false, error: 'خطأ في البيانات');
    return false;
  }

  void loginAsEmployee() {
    state = state.copyWith(
      user: UserModel(
        id: 'employee_id',
        name: 'موظف',
        username: 'employee',
        email: '',
        role: UserRole.dataEntry,
      ),
    );
  }

  Future<void> completeAdminSetup(String name, String email, String newUsername, String newPassword) async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false);
    await prefs.setString('admin_name', name);
    await prefs.setString('admin_email', email);
    await prefs.setString('admin_username', newUsername);
    await prefs.setString('admin_password', newPassword);

    state = state.copyWith(
      user: UserModel(id: 'admin_id', name: name, username: newUsername, email: email, role: UserRole.admin),
      isLoading: false,
      isFirstRun: false,
    );
  }

  void logout() {
    state = state.copyWith(user: null);
  }
}
