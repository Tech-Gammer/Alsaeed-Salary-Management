class Kharcha {
  final int id;
  final int? departmentId;
  final String? employeeId; // Changed to String to match your API
  final double amount;
  final DateTime date;
  final int periodId;
  final String description;
  final String kharchaType;
  final String? departmentName;
  final String? employeeName;
  final String periodName;
  final DateTime createdAt;
  final DateTime updatedAt;
  bool includeInCurrentSalary;

  Kharcha({
    required this.id,
    this.departmentId,
    this.employeeId, // Now String
    required this.amount,
    required this.date,
    required this.periodId,
    required this.description,
    required this.kharchaType,
    this.departmentName,
    this.employeeName,
    required this.periodName,
    required this.createdAt,
    required this.updatedAt,
    this.includeInCurrentSalary = true,
  });

  // Helper getter for display name
  String get displayName {
    if (kharchaType == 'individual' && employeeName != null) {
      return employeeName!;
    } else if (kharchaType == 'department' && departmentName != null) {
      return departmentName!;
    }
    return 'Unknown';
  }

  // Helper getter for type display
  String get typeDisplay {
    return kharchaType == 'individual' ? '👤 Individual' : '🏢 Department';
  }

  // Helper getter for status display
  String get statusDisplay {
    return includeInCurrentSalary ? '💰 Current Month' : '⏳ Next Month';
  }

  factory Kharcha.fromJson(Map<String, dynamic> json) {
    // Parse integer fields safely
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    // Parse nullable integer fields safely
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        if (value.isEmpty) return null;
        return int.tryParse(value);
      }
      if (value is double) return value.toInt();
      return null;
    }

    // Parse string fields safely
    String parseString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    double parseAmount(dynamic amountValue) {
      if (amountValue == null) return 0.0;
      if (amountValue is double) return amountValue;
      if (amountValue is int) return amountValue.toDouble();
      if (amountValue is String) {
        final cleaned = amountValue.replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) {
        // Handle both date formats: "2025-10-23" and "2025-10-13 23:55:19"
        if (dateValue.contains(' ')) {
          return DateTime.tryParse(dateValue) ?? DateTime.now();
        } else {
          return DateTime.tryParse('$dateValue 00:00:00') ?? DateTime.now();
        }
      }
      return DateTime.now();
    }

    // Parse kharcha type with default
    String kharchaType = 'department';
    if (json['kharcha_type'] != null) {
      kharchaType = parseString(json['kharcha_type']);
    }

    // Parse employee_id as String since your API returns it as String
    String? employeeId;
    if (json['employee_id'] != null) {
      employeeId = parseString(json['employee_id']);
      if (employeeId!.isEmpty) employeeId = null;
    }

    return Kharcha(
      id: parseInt(json['id']),
      departmentId: parseNullableInt(json['department_id']),
      employeeId: employeeId, // Now using String
      amount: parseAmount(json['amount']),
      date: parseDate(json['date']),
      periodId: parseInt(json['period_id']),
      description: parseString(json['description']),
      kharchaType: kharchaType,
      departmentName: parseString(json['department_name']).isEmpty ? null : parseString(json['department_name']),
      employeeName: parseString(json['employee_name']).isEmpty ? null : parseString(json['employee_name']),
      periodName: parseString(json['period_name']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      includeInCurrentSalary: json['include_in_current_salary'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'department_id': departmentId,
      'employee_id': employeeId,
      'amount': amount,
      'date': date.toIso8601String(),
      'period_id': periodId,
      'description': description,
      'kharcha_type': kharchaType,
      'department_name': departmentName,
      'employee_name': employeeName,
      'period_name': periodName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'include_in_current_salary': includeInCurrentSalary,
    };
  }
}