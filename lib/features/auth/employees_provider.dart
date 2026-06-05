import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/employee_model.dart';

final employeesProvider = StateNotifierProvider<EmployeesNotifier, EmployeesState>((ref) {
  return EmployeesNotifier();
});

class EmployeesState {
  final List<EmployeeModel> employees;
  final List<AttendanceRecord> attendance;
  final int weekStartDay; // 1 = Monday, 6 = Saturday, 7 = Sunday

  EmployeesState({
    required this.employees,
    required this.attendance,
    this.weekStartDay = 6, // السبت كبداية افتراضية في مصر
  });

  EmployeesState copyWith({
    List<EmployeeModel>? employees,
    List<AttendanceRecord>? attendance,
    int? weekStartDay,
  }) {
    return EmployeesState(
      employees: employees ?? this.employees,
      attendance: attendance ?? this.attendance,
      weekStartDay: weekStartDay ?? this.weekStartDay,
    );
  }
}

class EmployeesNotifier extends StateNotifier<EmployeesState> {
  EmployeesNotifier() : super(EmployeesState(employees: [], attendance: [])) {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // تحميل الموظفين
    final employeesJson = prefs.getString('employees_list');
    List<EmployeeModel> loadedEmployees = [];
    if (employeesJson != null) {
      final List decoded = json.decode(employeesJson);
      loadedEmployees = decoded.map((e) => EmployeeModel.fromMap(e)).toList();
    }

    // تحميل الغياب
    final attendanceJson = prefs.getString('attendance_list');
    List<AttendanceRecord> loadedAttendance = [];
    if (attendanceJson != null) {
      final List decoded = json.decode(attendanceJson);
      loadedAttendance = decoded.map((a) => AttendanceRecord.fromMap(a)).toList();
    }

    // تحميل بداية الأسبوع
    final weekStart = prefs.getInt('week_start_day') ?? 6;

    state = state.copyWith(
      employees: loadedEmployees,
      attendance: loadedAttendance,
      weekStartDay: weekStart,
    );
  }

  Future<void> addEmployee(String name, double dailyRate) async {
    final newEmployee = EmployeeModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      dailyRate: dailyRate,
    );
    state = state.copyWith(employees: [...state.employees, newEmployee]);
    _saveEmployees();
  }

  Future<void> markAttendance(String employeeId, DateTime date, bool isPresent) async {
    // إزالة السجل القديم لنفس الموظف ونفس اليوم إن وجد
    final dateOnly = DateTime(date.year, date.month, date.day);
    final filtered = state.attendance.where((a) {
      final aDate = DateTime(a.date.year, a.date.month, a.date.day);
      return !(a.employeeId == employeeId && aDate == dateOnly);
    }).toList();

    if (isPresent) {
      filtered.add(AttendanceRecord(employeeId: employeeId, date: dateOnly, isPresent: true));
    }

    state = state.copyWith(attendance: filtered);
    _saveAttendance();
  }

  Future<void> setWeekStartDay(int day) async {
    state = state.copyWith(weekStartDay: day);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('week_start_day', day);
  }

  double calculateWeeklySalary(String employeeId) {
    final now = DateTime.now();
    // الحصول على تاريخ بداية الأسبوع الحالي بناءً على الإعداد
    DateTime startOfWeek = _getStartOfCurrentWeek();

    final employee = state.employees.firstWhere((e) => e.id == employeeId);

    final weekAttendance = state.attendance.where((a) {
      return a.employeeId == employeeId &&
             a.isPresent &&
             a.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
    }).length;

    return weekAttendance * employee.dailyRate;
  }

  DateTime _getStartOfCurrentWeek() {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday; // 1 = Mon, 7 = Sun
    int targetWeekday = state.weekStartDay;

    int daysToSubtract = (currentWeekday - targetWeekday) % 7;
    if (daysToSubtract < 0) daysToSubtract += 7;

    return DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
  }

  // حفظ البيانات
  Future<void> _saveEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(state.employees.map((e) => e.toMap()).toList());
    await prefs.setString('employees_list', encoded);
  }

  Future<void> _saveAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(state.attendance.map((a) => a.toMap()).toList());
    await prefs.setString('attendance_list', encoded);
  }
}
