class Kharcha {
  final int id;
  final int? departmentId;
  final int? employeeId;
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

  Kharcha({
    required this.id,
    this.departmentId,
    this.employeeId,
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

  factory Kharcha.fromJson(Map<String, dynamic> json) {
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
        return DateTime.tryParse(dateValue) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return Kharcha(
      id: json['id'] as int? ?? 0,
      departmentId: json['department_id'] as int?,
      employeeId: json['employee_id'] as int?,
      amount: parseAmount(json['amount']),
      date: parseDate(json['date']),
      periodId: json['period_id'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      kharchaType: json['kharcha_type'] as String? ?? 'department',
      departmentName: json['department_name'] as String?,
      employeeName: json['employee_name'] as String?,
      periodName: json['period_name'] as String? ?? '',
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}