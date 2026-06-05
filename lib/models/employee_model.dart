class EmployeeModel {
  final String id;
  final String name;
  final double dailyRate;
  final bool isActive;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.dailyRate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dailyRate': dailyRate,
      'isActive': isActive,
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      dailyRate: (map['dailyRate'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }
}

class AttendanceRecord {
  final String employeeId;
  final DateTime date;
  final bool isPresent;

  AttendanceRecord({
    required this.employeeId,
    required this.date,
    this.isPresent = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'isPresent': isPresent,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      employeeId: map['employeeId'] ?? '',
      date: DateTime.parse(map['date']),
      isPresent: map['isPresent'] ?? true,
    );
  }
}
