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
  final int weekStartDay;

  EmployeesState({
    required this.employees,
    required this.attendance,
    this.weekStartDay = 6,
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
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    final employeesJson = prefs.getString('employees_list');
    List<EmployeeModel> loadedEmployees = [];
    if (employeesJson != null) {
      final List decoded = json.decode(employeesJson);
      loadedEmployees = decoded.map((e) => EmployeeModel.fromMap(e)).toList();
    }

    final attendanceJson = prefs.getString('attendance_list');
    List<AttendanceRecord> loadedAttendance = [];
    if (attendanceJson != null) {
      final List decoded = json.decode(attendanceJson);
      loadedAttendance = decoded.map((a) => AttendanceRecord.fromMap(a)).toList();
    }

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
    final dateOnly = DateTime(date.year, date.month, date.day);

    final updatedAttendance = List<AttendanceRecord>.from(state.attendance);
    updatedAttendance.removeWhere((a) {
      final aDate = DateTime(a.date.year, a.date.month, a.date.day);
      return a.employeeId == employeeId && aDate == dateOnly;
    });

    updatedAttendance.add(AttendanceRecord(
      employeeId: employeeId,
      date: dateOnly,
      isPresent: isPresent
    ));

    state = state.copyWith(attendance: updatedAttendance);
    _saveAttendance();
  }

  Future<void> setWeekStartDay(int day) async {
    state = state.copyWith(weekStartDay: day);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('week_start_day', day);
  }

  double calculateWeeklySalary(String employeeId) {
    DateTime startOfWeek = _getStartOfCurrentWeek();
    final employeeList = state.employees.where((e) => e.id == employeeId);
    if (employeeList.isEmpty) return 0.0;

    final employee = employeeList.first;

    final weekAttendance = state.attendance.where((a) {
      return a.employeeId == employeeId &&
             a.isPresent &&
             a.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
    }).length;

    return weekAttendance * employee.dailyRate;
  }

  DateTime _getStartOfCurrentWeek() {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday;
    int targetWeekday = state.weekStartDay;

    int daysToSubtract = (currentWeekday - targetWeekday) % 7;
    if (daysToSubtract < 0) daysToSubtract += 7;

    return DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
  }

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
