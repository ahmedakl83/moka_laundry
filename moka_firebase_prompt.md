# بروبمت هجرة Firebase — مشروع مغسلة Moka
> الصق هذا البرومبت كاملاً في Gemini داخل Android Studio (أو أي AI assistant)

---

## السياق الكامل للمشروع

أنا أعمل على تطبيق Flutter اسمه **مغسلة Moka** (`package: com.moka.wash.moka`).  
التطبيق مصمم لجهازين: **جهاز المدير (Admin)** وـ**جهاز الموظف (DataEntry)**.  
المشكلة الجوهرية: كل البيانات محفوظة محلياً بـ SharedPreferences فقط، والجهازان لا يتشاركان أي بيانات.  
المطلوب: هجرة كاملة إلى Firebase (Firestore + Auth) مع الإبقاء على نفس بنية الـ Providers.

---

## بنية الملفات الحالية

```
lib/
├── main.dart
├── core/constants.dart
├── models/
│   ├── user_model.dart       (UserRole: admin | dataEntry)
│   ├── order_model.dart      (OrderStatus, PaymentMethod)
│   ├── customer_model.dart
│   ├── service_model.dart
│   ├── expense_model.dart
│   ├── expense_category_model.dart
│   └── employee_model.dart   (+ AttendanceRecord)
└── features/
    ├── auth/
    │   ├── auth_provider.dart       ← يستخدم SharedPreferences
    │   └── employees_provider.dart  ← يستخدم SharedPreferences
    ├── orders/orders_provider.dart  ← يستخدم SharedPreferences
    ├── customers/customers_provider.dart ← يستخدم SharedPreferences
    ├── expenses/expenses_provider.dart   ← يستخدم SharedPreferences
    └── services/services_provider.dart  ← لا يحفظ أصلاً
```

---

## الكود الحالي لكل ملف يحتاج تعديلاً

### lib/main.dart (الحالي)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/auth_provider.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MokaApp(),
    ),
  );
}
```

### lib/features/auth/auth_provider.dart (الحالي)
```dart
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

  AuthState({this.user, this.isLoading = false, this.isFirstRun = true, this.error, this.clientInviteCode});

  AuthState copyWith({UserModel? user, bool? isLoading, bool? isFirstRun, String? error, String? clientInviteCode}) {
    return AuthState(user: user ?? this.user, isLoading: isLoading ?? this.isLoading,
        isFirstRun: isFirstRun ?? this.isFirstRun, error: error, clientInviteCode: clientInviteCode ?? this.clientInviteCode);
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) { _init(); }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('isFirstRun') ?? true;
    final savedUsername = prefs.getString('admin_username');
    final isClient = prefs.getBool('is_client_device') ?? false;

    if (isClient) {
      state = state.copyWith(
        user: UserModel(id: 'client_id', name: 'جهاز الموظف', username: 'client', email: '', role: UserRole.dataEntry),
        isFirstRun: false);
      return;
    }
    if (!isFirstRun && savedUsername != null) {
      state = state.copyWith(user: UserModel(id: 'admin_id', name: prefs.getString('admin_name') ?? 'المدير',
          username: savedUsername, email: prefs.getString('admin_email') ?? '', role: UserRole.admin), isFirstRun: false);
    } else {
      state = state.copyWith(isFirstRun: isFirstRun);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final prefs = await SharedPreferences.getInstance();
    await Future.delayed(const Duration(seconds: 1));

    if (username == 'code') {
      final activeCode = prefs.getString('active_invite_code');
      if (activeCode != null && password == activeCode) {
        await prefs.setBool('is_client_device', true);
        state = state.copyWith(
          user: UserModel(id: 'client_id', name: 'جهاز الموظف', username: 'client', email: '', role: UserRole.dataEntry),
          isLoading: false, isFirstRun: false);
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
        state = state.copyWith(user: UserModel(id: 'admin_id', name: prefs.getString('admin_name') ?? 'المدير',
            username: username, email: prefs.getString('admin_email') ?? '', role: UserRole.admin), isLoading: false);
        return true;
      }
    }
    state = state.copyWith(isLoading: false, error: 'خطأ في البيانات أو الكود');
    return false;
  }

  Future<String> generateInviteCode() async {
    final code = (Random().nextInt(900000) + 100000).toString();
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
    state = state.copyWith(user: UserModel(id: 'admin_id', name: name, username: newUsername, email: email, role: UserRole.admin),
        isLoading: false, isFirstRun: false);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_client_device');
    state = state.copyWith(user: null);
  }
}
```

### lib/features/orders/orders_provider.dart (الحالي)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/order_model.dart';
import '../../models/service_model.dart';

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<OrderModel>>((ref) => OrdersNotifier());

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  OrdersNotifier() : super([]) { _loadOrders(); }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getString('orders_history');
    if (ordersJson != null) {
      final List decoded = json.decode(ordersJson);
      state = decoded.map((o) => OrderModel.fromMap(o)).toList();
    }
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('orders_history', json.encode(state.map((o) => o.toMap()).toList()));
  }

  void addOrder(OrderModel order) { state = [order, ...state]; _saveOrders(); }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    state = [for (final o in state) if (o.id == orderId)
      OrderModel(id: o.id, serialNumber: o.serialNumber, customerId: o.customerId, customerName: o.customerName,
        carNumber: o.carNumber, carPlateImagePath: o.carPlateImagePath, services: o.services, totalPrice: o.totalPrice,
        status: newStatus, paymentMethod: o.paymentMethod, notes: o.notes, userId: o.userId, createdAt: o.createdAt)
      else o];
    _saveOrders();
  }

  List<OrderModel> getOrdersByDateRange(DateTime start, DateTime end) {
    return state.where((o) => o.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
        o.createdAt.isBefore(end.add(const Duration(days: 1)))).toList();
  }

  String generateSerialNumber() {
    final now = DateTime.now();
    return "${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}${state.length + 1}";
  }
}
```

### lib/features/customers/customers_provider.dart (الحالي)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/customer_model.dart';

final customersProvider = StateNotifierProvider<CustomersNotifier, List<CustomerModel>>((ref) => CustomersNotifier());

class CustomersNotifier extends StateNotifier<List<CustomerModel>> {
  CustomersNotifier() : super([]) { _init(); }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final json_ = prefs.getString('customers_list');
    if (json_ != null) {
      state = (json.decode(json_) as List).map((c) => CustomerModel.fromMap(c)).toList();
    } else {
      state = [CustomerModel(id: '1', name: 'عميل نقدي', phone: '0000000000', balance: 0)];
      _saveCustomers();
    }
  }

  Future<void> _saveCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customers_list', json.encode(state.map((c) => c.toMap()).toList()));
  }

  CustomerModel addCustomer(String name, String phone) {
    final c = CustomerModel(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, phone: phone);
    state = [...state, c]; _saveCustomers(); return c;
  }

  void updateCustomer(CustomerModel updated) {
    state = [for (final c in state) if (c.id == updated.id) updated else c]; _saveCustomers();
  }

  void deleteCustomer(String id) { state = state.where((c) => c.id != id).toList(); _saveCustomers(); }
}
```

### lib/features/expenses/expenses_provider.dart (الحالي)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/expense_model.dart';
import '../../models/expense_category_model.dart';

final expenseCategoriesProvider = StateNotifierProvider<ExpenseCategoriesNotifier, List<ExpenseCategoryModel>>((ref) => ExpenseCategoriesNotifier());

class ExpenseCategoriesNotifier extends StateNotifier<List<ExpenseCategoryModel>> {
  ExpenseCategoriesNotifier() : super([]) { _loadCategories(); }
  void _loadCategories() {
    state = [ExpenseCategoryModel(id: '1', name: 'إيجار'), ExpenseCategoryModel(id: '2', name: 'كهرباء ومياه'),
      ExpenseCategoryModel(id: '3', name: 'مواد تنظيف'), ExpenseCategoryModel(id: '4', name: 'رواتب'),
      ExpenseCategoryModel(id: '5', name: 'أخرى')];
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<ExpenseModel>>((ref) => ExpensesNotifier());

class ExpensesNotifier extends StateNotifier<List<ExpenseModel>> {
  ExpensesNotifier() : super([]) { _loadExpenses(); }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final json_ = prefs.getString('expenses_history');
    if (json_ != null) state = (json.decode(json_) as List).map((e) => ExpenseModel.fromMap(e)).toList();
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expenses_history', json.encode(state.map((e) => e.toMap()).toList()));
  }

  void addExpense(ExpenseModel expense) { state = [expense, ...state]; _saveExpenses(); }

  List<ExpenseModel> getExpensesByDateRange(DateTime start, DateTime end) {
    return state.where((e) => e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        e.date.isBefore(end.add(const Duration(days: 1)))).toList();
  }
}
```

### lib/features/services/services_provider.dart (الحالي)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/service_model.dart';

final servicesProvider = StateNotifierProvider<ServicesNotifier, List<ServiceModel>>((ref) => ServicesNotifier());

class ServicesNotifier extends StateNotifier<List<ServiceModel>> {
  ServicesNotifier() : super([]) { _loadServices(); }

  void _loadServices() {
    state = [ServiceModel(id: '1', name: 'غسيل خارجي', price: 20),
      ServiceModel(id: '2', name: 'غسيل كامل', price: 50),
      ServiceModel(id: '3', name: 'تلميع ساطع', price: 150)];
  }

  void addService(String name, double price) {
    state = [...state, ServiceModel(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, price: price)];
  }

  void updateService(ServiceModel updated) {
    state = [for (final s in state) if (s.id == updated.id) updated else s];
  }

  void deleteService(String id) { state = state.where((s) => s.id != id).toList(); }
}
```

### lib/features/auth/employees_provider.dart (الحالي)
```dart
// [محذوف للإيجاز — هو أيضاً يستخدم SharedPreferences لحفظ employees_list و attendance_list]
// نفس النمط: _loadData() من SharedPreferences، _saveEmployees() و _saveAttendance() إليه
```

---

## المطلوب منك: اكتب الكود الكامل لكل الملفات التالية

### الشروط والقيود المهمة:
1. **حافظ على نفس واجهة الـ API** — نفس أسماء الـ methods، نفس الـ return types، حتى لا تتكسر الـ screens
2. **استخدم `cloud_firestore` فقط** (موجود بالفعل في pubspec.yaml) — لا تضف packages جديدة إلا `firebase_auth`
3. **لا تستخدم `google_sign_in`** — المصادقة بـ email/password فقط
4. **الجهاز الثاني (DataEntry)** يدخل بكود 6 أرقام يُولَّد من جهاز المدير
5. **الـ invite code** يجب أن يُخزَّن في Firestore حتى يتمكن الجهاز الثاني من التحقق منه
6. **أضف `Timestamp.now()`** لكل document عند الكتابة بدلاً من `DateTime.now().toIso8601String()`
7. **استخدم `.snapshots().listen()`** (real-time) وليس `.get()` للـ orders والـ customers
8. **الـ IDs** يجب أن تُولَّد بـ `_db.collection('x').doc().id` وليس millisecondsSinceEpoch

### الملفات المطلوبة:

**1. `lib/main.dart`**  
أضف `Firebase.initializeApp()` واستورد `firebase_options.dart`

**2. `lib/features/auth/auth_provider.dart`**  
- استبدل SharedPreferences بـ Firebase Auth للمدير
- `completeAdminSetup()` → ينشئ حساب بـ `createUserWithEmailAndPassword` ويحفظ الـ role في Firestore `users/{uid}`
- `login()` → `signInWithEmailAndPassword` للمدير
- `login('code', inviteCode)` → يقرأ الكود من Firestore `settings/invite` ويقارنه
- `generateInviteCode()` → يكتب الكود في Firestore `settings/invite` مع `expiresAt` (30 دقيقة)
- `_init()` → يراقب `FirebaseAuth.instance.authStateChanges()` ويقرأ الـ role من Firestore

**3. `lib/features/orders/orders_provider.dart`**  
- `_loadOrders()` → `.snapshots().listen()` على collection `orders` مرتبة بـ `createdAt desc`
- `addOrder()` → `_db.collection('orders').doc(order.id).set(order.toMap())`
- `updateOrderStatus()` → `_db.collection('orders').doc(orderId).update({'status': newStatus.name})`
- `generateSerialNumber()` → احتفظ بنفس المنطق لكن استخدم `state.length + 1`

**4. `lib/features/customers/customers_provider.dart`**  
- real-time listener على collection `customers`
- `addCustomer()` → يستخدم doc ID من Firestore
- عند أول تشغيل إذا كانت collection فارغة → أضف `عميل نقدي` تلقائياً

**5. `lib/features/expenses/expenses_provider.dart`**  
- `ExpensesNotifier` → real-time listener على `expenses`
- `ExpenseCategoriesNotifier` → احتفظ بالقائمة الثابتة في الكود (لا تحتاج Firestore)
- `addExpense()` → يكتب في Firestore

**6. `lib/features/services/services_provider.dart`**  
- `_loadServices()` → يقرأ من Firestore `services`، إذا كانت فارغة يكتب الافتراضية
- `addService()`, `updateService()`, `deleteService()` → يكتبون في Firestore

**7. `lib/features/auth/employees_provider.dart`**  
- `employees` و `attendance` → real-time listeners على collections `employees` و `attendance`
- `addEmployee()`, `markAttendance()` → يكتبون في Firestore
- احتفظ بنفس منطق `getEmployeeHistory()` و `calculateWeeklySalary()`

**8. `android/app/build.gradle.kts`**  
أضف Google Services Plugin

**9. `android/build.gradle.kts`**  
أضف classpath Google Services

**10. `firestore.rules`** (ملف جديد في root المشروع)  
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // المدير يقرأ ويكتب كل شيء
    // DataEntry يقرأ كل شيء ويكتب orders فقط
    // settings/invite: يقرأها غير المسجلين لإتمام ربط الجهاز
  }
}
```

---

## بنية Firestore المتوقعة (للمرجع)

```
firestore/
├── users/
│   └── {uid}/  →  { name, email, role: 'admin'|'dataEntry', createdAt }
├── orders/
│   └── {orderId}/  →  OrderModel.toMap() + { createdAt: Timestamp }
├── customers/
│   └── {customerId}/  →  CustomerModel.toMap()
├── services/
│   └── {serviceId}/  →  ServiceModel.toMap()
├── expenses/
│   └── {expenseId}/  →  ExpenseModel.toMap() + { date: Timestamp }
├── employees/
│   └── {employeeId}/  →  EmployeeModel.toMap()
├── attendance/
│   └── {employeeId_YYYY-MM-DD}/  →  AttendanceRecord.toMap()
└── settings/
    └── invite/  →  { code: '123456', expiresAt: Timestamp, createdBy: uid }
```

---

## ملاحظة نهائية

بعد كتابة الكود، أخبرني بالخطوات اليدوية المطلوبة:
1. تشغيل `flutterfire configure` 
2. ضبط Firebase Console (Authentication → Email/Password)
3. نشر Firestore Rules
4. أي خطوة لا يمكن للكود تنفيذها تلقائياً
