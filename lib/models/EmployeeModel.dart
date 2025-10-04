class Employee {
  final String id;
  final String name;
  final String position;
  final String department;
  final String joinDate;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.department,
    required this.joinDate,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      position: json['position'] as String? ?? '',
      department: json['department'] as String? ?? '',
      joinDate: json['joinDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'department': department,
      'joinDate': joinDate,
    };
  }
}