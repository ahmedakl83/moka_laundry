import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  EmployeesNotifier() : super(EmployeesState(employees: [], attendance: [])) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final weekStart = prefs.getInt('week_start_day') ?? 6;
    state = state.copyWith(weekStartDay: weekStart);

    // متابعة الموظفين
    _db.collection('employees').snapshots().listen((snapshot) {
      final employees = snapshot.docs.map((doc) => EmployeeModel.fromMap(doc.data())).toList();
      state = state.copyWith(employees: employees);
    });

    // متابعة الحضور
    _db.collection('attendance').snapshots().listen((snapshot) {
      final attendance = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['date'] is Timestamp) {
          data['date'] = (data['date'] as Timestamp).toDate().toIso8601String();
        }
        return AttendanceRecord.fromMap(data);
      }).toList();
      state = state.copyWith(attendance: attendance);
    });
  }

  Future<void> addEmployee(String name, double dailyRate) async {
    final docRef = _db.collection('employees').doc();
    final newEmployee = EmployeeModel(
      id: docRef.id,
      name: name,
      dailyRate: dailyRate,
    );
    await docRef.set(newEmployee.toMap());
  }

  Future<void> markAttendance(String employeeId, DateTime date, bool isPresent) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final docId = "${employeeId}_$dateStr";
    final docRef = _db.collection('attendance').doc(docId);

    if (isPresent) {
      await docRef.set({
        'employeeId': employeeId,
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'isPresent': true,
      });
    } else {
      await docRef.delete();
    }
  }

  Future<void> setWeekStartDay(int day) async {
    state = state.copyWith(weekStartDay: day);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('week_start_day', day);
  }

  Map<String, dynamic> getEmployeeHistory(String employeeId, DateTime start, DateTime end) {
    final records = state.attendance.where((a) =>
      a.employeeId == employeeId &&
      (a.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
       a.date.isBefore(end.add(const Duration(days: 1))))
    ).toList();

    int workingDays = records.where((r) => r.isPresent).length;

    final employeeList = state.employees.where((e) => e.id == employeeId);
    if (employeeList.isEmpty) return {'workingDays': 0, 'totalEarned': 0.0};

    final employee = employeeList.first;
    double totalEarned = workingDays * employee.dailyRate;

    return {
      'workingDays': workingDays,
      'totalEarned': totalEarned,
      'records': records,
    };
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
}
