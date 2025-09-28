import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DepartmentSalaryPage extends StatefulWidget {
  const DepartmentSalaryPage({super.key});

  @override
  State<DepartmentSalaryPage> createState() => _DepartmentSalaryPageState();
}

class _DepartmentSalaryPageState extends State<DepartmentSalaryPage> {
  static const String _apiBaseUrl = "http://localhost:3000/api";
  String? _selectedDeptId;
  List<dynamic> _departments = [];
  List<dynamic> _employees = [];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/departments"));
      if (response.statusCode == 200) {
        setState(() {
          _departments = jsonDecode(response.body);
        });
      } else {
        throw Exception("Failed to fetch departments");
      }
    } catch (e) {
      _showError("Error loading departments: $e");
    }
  }

  Future<void> _fetchEmployeesByDept(String deptId) async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/departments/$deptId/employees"));
      if (response.statusCode == 200) {
        setState(() {
          _employees = jsonDecode(response.body);
        });
      } else {
        throw Exception("Failed to fetch employees");
      }
    } catch (e) {
      _showError("Error loading employees: $e");
    }
  }

  Future<void> _addSalary(String employeeId, String amount, String date) async {
    try {
      final response = await http.post(
        Uri.parse("$_apiBaseUrl/employees/$employeeId/salaries"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": amount,
          "salaryDate": date,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Salary added successfully"), backgroundColor: Colors.green),
        );
      } else {
        throw Exception("Failed to add salary");
      }
    } catch (e) {
      _showError("Error adding salary: $e");
    }
  }

  void _showAddSalaryDialog(Map employee) {
    final _amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Add Salary for ${employee['name']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
              Row(
                children: [
                  Text("Date: ${selectedDate.toLocal()}".split(' ')[0]),
                  const Spacer(),
                  TextButton(
                    child: const Text("Pick Date"),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  )
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Save", style: TextStyle(color: Colors.green)),
              onPressed: () async {
                Navigator.pop(context);
                await _addSalary(employee['id'].toString(), _amountController.text, selectedDate.toIso8601String());
              },
            ),
          ],
        );
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Department Salaries")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Select Department"),
              value: _selectedDeptId,
              items: _departments.map<DropdownMenuItem<String>>((dept) {
                return DropdownMenuItem<String>(
                  value: dept['id'].toString(),
                  child: Text(dept['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDeptId = value);
                if (value != null) _fetchEmployeesByDept(value);
              },
            ),
          ),
          Expanded(
            child: _employees.isEmpty
                ? const Center(child: Text("No employees found"))
                : ListView.builder(
              itemCount: _employees.length,
              itemBuilder: (_, i) {
                final emp = _employees[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(emp['name']),
                    subtitle: Text(emp['designation'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.attach_money, color: Colors.green),
                      onPressed: () => _showAddSalaryDialog(emp),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
