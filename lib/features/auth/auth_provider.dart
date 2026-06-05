import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  AuthState({this.user, this.isLoading = false, this.isFirstRun = true, this.error, this.clientInviteCode});

  AuthState copyWith({UserModel? user, bool? isLoading, bool? isFirstRun, String? error, String? clientInviteCode}) {
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthNotifier() : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('isFirstRun') ?? true;
    final isClient = prefs.getBool('is_client_device') ?? false;

    if (isClient) {
      state = state.copyWith(
        user: UserModel(id: 'client_id', name: 'جهاز الموظف', username: 'client', email: '', role: UserRole.dataEntry),
        isFirstRun: false,
      );
      return;
    }

    state = state.copyWith(isFirstRun: isFirstRun);

    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        final doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
          state = state.copyWith(user: UserModel.fromMap(doc.data()!), isFirstRun: false);
        }
      } else {
        state = state.copyWith(user: null);
      }
    });
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final prefs = await SharedPreferences.getInstance();

    // تسجيل دخول جهاز الموظف بواسطة الكود
    if (username == 'code') {
      try {
        final doc = await _db.collection('settings').doc('invite').get();
        if (doc.exists) {
          final data = doc.data()!;
          final expiresAt = (data['expiresAt'] as Timestamp).toDate();
          if (data['code'] == password && expiresAt.isAfter(DateTime.now())) {
            await prefs.setBool('is_client_device', true);
            state = state.copyWith(
              user: UserModel(id: 'client_id', name: 'جهاز الموظف', username: 'client', email: '', role: UserRole.dataEntry),
              isLoading: false,
              isFirstRun: false,
            );
            return true;
          }
        }
      } catch (e) {
        state = state.copyWith(isLoading: false, error: 'كود الربط غير صحيح أو انتهت صلاحيته');
        return false;
      }
    }

    // تسجيل دخول المدير (admin/admin123) في المرة الأولى فقط
    if (state.isFirstRun && username == 'admin' && password == 'admin123') {
      state = state.copyWith(isLoading: false);
      return true;
    }

    // تسجيل دخول المدير الحقيقي بواسطة Email/Password
    try {
      // بما أن الـ PRD ذكر username، سنستخدم البريد المحفوظ أو نفترض أن الـ username هو الـ email للمدير
      final savedEmail = prefs.getString('admin_email');
      final emailToUse = username.contains('@') ? username : (savedEmail ?? username);

      await _auth.signInWithEmailAndPassword(email: emailToUse, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'خطأ في البريد أو كلمة المرور');
      return false;
    }
  }

  Future<String> generateInviteCode() async {
    final code = (Random().nextInt(900000) + 100000).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 30));

    await _db.collection('settings').doc('invite').set({
      'code': code,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdBy': _auth.currentUser?.uid,
    });

    state = state.copyWith(clientInviteCode: code);
    return code;
  }

  Future<void> completeAdminSetup(String name, String email, String newUsername, String newPassword) async {
    state = state.copyWith(isLoading: true);
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: newPassword);
      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        username: newUsername,
        email: email,
        role: UserRole.admin,
      );

      await _db.collection('users').doc(user.id).set({
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstRun', false);
      await prefs.setString('admin_name', name);
      await prefs.setString('admin_email', email);
      await prefs.setString('admin_username', newUsername);

      state = state.copyWith(user: user, isLoading: false, isFirstRun: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_client_device');
    await _auth.signOut();
    state = state.copyWith(user: null);
  }
}
