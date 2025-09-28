import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DeactivatedEmployeesPage extends StatefulWidget {
  const DeactivatedEmployeesPage({super.key});

  @override
  State<DeactivatedEmployeesPage> createState() => _DeactivatedEmployeesPageState();
}

class _DeactivatedEmployeesPageState extends State<DeactivatedEmployeesPage> {
  static const String _apiBaseUrl = "http://localhost:3000/api";
  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    _fetchDeactivatedEmployees();
  }

  Future<void> _activateEmployee(String id) async {
    try {
      final response = await http.put(
        Uri.parse("$_apiBaseUrl/employees/$id/activate"),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Employee reactivated"), backgroundColor: Colors.green),
        );
        _fetchDeactivatedEmployees(); // refresh list
      } else {
        throw Exception("Failed to activate employee");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error activating employee: $e"), backgroundColor: Colors.red),
      );
    }
  }


  Future<void> _fetchDeactivatedEmployees() async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/employees?active=0"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _employees = data.map((e) => Employee(
            id: e['id'].toString(),
            name: e['name'] ?? '',
            position: e['designation'] ?? '',
            department: e['department'] ?? '',
            joinDate: e['registerDate'] ?? '',
          )).toList();
        });
      } else {
        throw Exception("Failed to load deactivated employees");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching deactivated employees: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deactivated Employees"),
        backgroundColor: Colors.red,
      ),
      body: _employees.isEmpty
          ? const Center(child: Text("No deactivated employees"))
          : ListView.builder(
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final emp = _employees[index];
          return ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: Text(emp.name),
            subtitle: Text("${emp.position} - ${emp.department}"),
            trailing: TextButton(
              child: const Text("Activate", style: TextStyle(color: Colors.green)),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Confirm Activation"),
                    content: Text("Do you want to reactivate ${emp.name}?"),
                    actions: [
                      TextButton(
                        child: const Text("Cancel"),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      TextButton(
                        child: const Text("Activate", style: TextStyle(color: Colors.green)),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  _activateEmployee(emp.id);
                }
              },
            ),
          );

        },
      ),
    );
  }
}

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
}
