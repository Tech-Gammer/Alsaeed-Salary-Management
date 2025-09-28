class Department {
  final int id;
  final String name;
  final String? description;
  final double totalSalary;

  Department({required this.id, required this.name, this.description, required this.totalSalary});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: int.parse(json['id'].toString()),
      name: json['name'].toString(),
      description: json['description']?.toString(),
      totalSalary: _parseDouble(json['total_salary']),
    );
  }
}

class PayrollPeriod {
  final int id;
  final String periodName;
  final String startDate;
  final String endDate;
  final String status;
  final String periodType; // 'full_month' or 'custom_range'

  PayrollPeriod({
    required this.id,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.periodType,
  });

  factory PayrollPeriod.fromJson(Map<String, dynamic> json) {
    return PayrollPeriod(
      id: int.parse(json['id'].toString()),
      periodName: json['period_name'].toString(),
      startDate: json['start_date'].toString(),
      endDate: json['end_date'].toString(),
      status: json['status'].toString(),
      periodType: json['period_type']?.toString() ?? 'full_month',
    );
  }
}

class EmployeePayroll {
  final int id;
  final String name;
  final String designation;
  final double salary;
  final String departmentName;
  int workingDays; // Add this
  int leaveDays;   // Add this
  double calculatedSalary; // Add this to store calculated amount

  EmployeePayroll({
    required this.id,
    required this.name,
    required this.designation,
    required this.salary,
    required this.departmentName,
    this.workingDays = 0,
    this.leaveDays = 0,
    this.calculatedSalary = 0.0,
  });

  factory EmployeePayroll.fromJson(Map<String, dynamic> json) {
    return EmployeePayroll(
      id: int.parse(json['id'].toString()),
      name: json['name'].toString(),
      designation: json['designation'].toString(),
      salary: _parseDouble(json['salary']),
      departmentName: json['department_name'].toString(),
      workingDays: json['working_days'] ?? 0,
      leaveDays: json['leave_days'] ?? 0,
      calculatedSalary: _parseDouble(json['calculated_salary']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'designation': designation,
      'salary': salary,
      'department_name': departmentName,
      'working_days': workingDays,
      'leave_days': leaveDays,
      'calculated_salary': calculatedSalary,
    };
  }
}
// Helper function to safely parse double values
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value.replaceAll(',', ''));
    } catch (e) {
      return 0.0;
    }
  }
  return 0.0;
}