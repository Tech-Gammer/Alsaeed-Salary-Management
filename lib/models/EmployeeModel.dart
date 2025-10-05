class Employee {
  final String id;
  final String name;
  final String position;
  final String department;
  final String joinDate;
  final bool isActive;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.department,
    required this.joinDate,
    required this.isActive,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: _parseString(json['id']),
      name: _parseString(json['name']),
      position: _parseString(json['position'] ?? json['designation']), // Handle both position and designation
      department: _parseString(json['department']),
      joinDate: _parseString(json['joinDate'] ?? json['registerDate']), // Handle both joinDate and registerDate
      isActive: _parseBool(json['isActive']),
    );
  }

  // Helper method to parse any value to string
  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value.toString();
  }

  // Helper method to parse any value to boolean
  static bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'department': department,
      'joinDate': joinDate,
      'isActive': isActive,
    };
  }
}