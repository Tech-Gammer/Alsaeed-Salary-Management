import 'dart:convert';
import 'package:alsaeed_salary/Employees/salary_historyPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'kharcha_management_page.dart';

// --- Color Definitions (Consistent Styling) ---
const Color deptPrimaryColor = Color(0xFF00796B); // Teal shade for departments
const Color deptAccentColor = Color(0xFF00ACC1); // Lighter teal
const Color deptTextColor = Color(0xFF333333);
const Color deptSubtleTextColor = Color(0xFF757575);

class Department {
  final dynamic id;
  final String name;
  final String? description;
  final double totalSalary; // ✅ New field

  Department({
    required this.id,
    required this.name,
    this.description,
    required this.totalSalary,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'] ?? 'Unnamed Department',
      description: json['description'],
      totalSalary: double.tryParse(json['total_salary'].toString()) ?? 0.0, // ✅ FIX
    );
  }

}


class DepartmentManagementPage extends StatefulWidget {
  const DepartmentManagementPage({super.key});

  @override
  State<DepartmentManagementPage> createState() => _DepartmentManagementPageState();
}

class _DepartmentManagementPageState extends State<DepartmentManagementPage> {
  static const String _apiBaseUrl = "http://localhost:3000/api";

  List<Department> _departments = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _departmentNameController = TextEditingController();
  final TextEditingController _departmentDescriptionController = TextEditingController();
  final TextEditingController _departmentSalaryController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }



  Future<void> _fetchDepartments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/departments')).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _departments = data.map((json) => Department.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load departments: ${response.statusCode}\n${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error fetching departments: $e\n\nEnsure your backend server is running and accessible at $_apiBaseUrl.';
        _isLoading = false;
      });
    }
  }

  Future<void> _addOrUpdateDepartment({Department? existingDepartment}) async {
    final name = _departmentNameController.text.trim();
    final description = _departmentDescriptionController.text.trim();
    final salary = double.tryParse(_departmentSalaryController.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department name cannot be empty.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    bool isDuplicate = _departments.any(
            (dept) => dept.name.toLowerCase() == name.toLowerCase() && (existingDepartment == null || dept.id != existingDepartment.id));

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Department "$name" already exists.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    final Map<String, dynamic> departmentData = {
      'name': name,
      'description': description.isNotEmpty ? description : null,
      if (_departmentSalaryController.text.trim().isNotEmpty)  // only send if user typed something
        'total_salary': salary,
    };



    bool isDialogLoading = true; // Assume loading starts
    // Show a loading indicator on the dialog button if possible or a general one
    // For simplicity, we'll update the main page's loading state after the call if dialog is closed.

    try {
      http.Response response;
      String successMessage;

      if (existingDepartment == null) {
        response = await http.post(
          Uri.parse('$_apiBaseUrl/departments'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(departmentData),
        ).timeout(const Duration(seconds: 10));
        successMessage = 'Department added successfully!';
      } else {
        response = await http.put(
          Uri.parse('$_apiBaseUrl/departments/${existingDepartment.id}'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(departmentData),
        ).timeout(const Duration(seconds: 10));
        successMessage = 'Department updated successfully!';
      }

      isDialogLoading = false; // Loading finished
      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
        _departmentNameController.clear();
        _departmentDescriptionController.clear();
        if (Navigator.canPop(context)) Navigator.pop(context); // Close dialog
        _fetchDepartments(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save department: ${response.statusCode}\n${response.body}'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      isDialogLoading = false; // Loading finished due to error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving department: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deleteDepartment(dynamic departmentId, String departmentName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Department?'),
          content: Text('Are you sure you want to delete the department "$departmentName"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red.shade700)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('$_apiBaseUrl/departments/$departmentId'),
        ).timeout(const Duration(seconds: 10));

        if (!mounted) return;

        if (response.statusCode == 200 || response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Department deleted successfully!'), backgroundColor: Colors.green),
          );
          _fetchDepartments(); // Refresh the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete department: ${response.statusCode}\n${response.body}'), backgroundColor: Colors.redAccent),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting department: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showDepartmentDialog({Department? department}) {
    if (department != null) {
      _departmentNameController.text = department.name;
      _departmentDescriptionController.text = department.description ?? '';
    } else {
      _departmentNameController.clear();
      _departmentDescriptionController.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final formKey = GlobalKey<FormState>();
        bool isDialogLoading = false; // Local loading state for the dialog button

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(department == null ? 'Add New Department' : 'Edit Department', style: const TextStyle(color: deptPrimaryColor)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      TextFormField(
                        controller: _departmentNameController,
                        decoration: const InputDecoration(
                          labelText: 'Department Name*',
                          hintText: 'e.g., Technology, Human Resources',
                          icon: Icon(Icons.business_outlined, color: deptPrimaryColor),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a department name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _departmentDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Briefly describe the department',
                          icon: Icon(Icons.description_outlined, color: deptPrimaryColor),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _departmentSalaryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Salary (Optional)',
                          hintText: 'e.g., 50000',
                          icon: Icon(Icons.attach_money, color: deptPrimaryColor),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null; // ✅ Allow empty
                        },
                      ),


                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel', style: TextStyle(color: deptSubtleTextColor)),
                  onPressed: isDialogLoading ? null : () { // Disable if dialog is loading
                    Navigator.of(context).pop();
                    _departmentNameController.clear();
                    _departmentDescriptionController.clear();
                  },
                ),
                ElevatedButton.icon(
                  icon: isDialogLoading
                      ? Container(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Icon(department == null ? Icons.add_circle_outline : Icons.save_outlined, color: Colors.white),
                  label: Text(department == null ? 'ADD' : 'SAVE', style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: deptAccentColor),
                  onPressed: isDialogLoading ? null : () async { // Disable if dialog is loading
                    if (formKey.currentState!.validate()) {
                      setDialogState(() {
                        isDialogLoading = true;
                      });
                      await _addOrUpdateDepartment(existingDepartment: department);
                      // If the dialog is still mounted after the await (e.g., error occurred and didn't pop),
                      // set loading back to false. Pop is handled in _addOrUpdateDepartment on success.
                      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                        setDialogState(() {
                          isDialogLoading = false;
                        });
                      }
                    }
                  },
                ),
              ],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Departments', style: TextStyle(color: Colors.white)),
        backgroundColor: deptPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2.0,
        // Add this in the AppBar of DepartmentManagementPage
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KharchaManagementPage()),
              );
            },
            tooltip: 'Manage Monthly Kharcha',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDepartments,
        color: deptPrimaryColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: deptPrimaryColor))
            : _errorMessage != null
            ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.redAccent.shade200, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to Load Departments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: deptTextColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: deptSubtleTextColor, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: const Text("Retry"),
                    onPressed: _fetchDepartments,
                    style: ElevatedButton.styleFrom(backgroundColor: deptPrimaryColor, foregroundColor: Colors.white),
                  )
                ],
              ),
            ))
            : _departments.isEmpty
            ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 70, color: deptSubtleTextColor.withOpacity(0.6)),
                const SizedBox(height: 20),
                const Text(
                  'No departments found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 19, color: deptSubtleTextColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the "+" button below to add your first department.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: deptSubtleTextColor.withOpacity(0.8)),
                ),
              ],
            ))
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0), // Padding for FAB
          itemCount: _departments.length,
          itemBuilder: (context, index) {
            final department = _departments[index];
            return Card(
              elevation: 2.0,
              margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                leading: CircleAvatar(
                  backgroundColor: deptAccentColor.withOpacity(0.15),
                  child: Icon(Icons.business_center_outlined, color: deptAccentColor, size: 26),
                ),
                title: Text(department.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: deptTextColor)),
                // subtitle: department.description != null && department.description!.isNotEmpty
                //     ? Padding(
                //   padding: const EdgeInsets.only(top: 4.0),
                //   child: Text(
                //     department.description!,
                //     style: const TextStyle(color: deptSubtleTextColor, fontSize: 13),
                //     maxLines: 2, // Allow more lines for description
                //     overflow: TextOverflow.ellipsis,
                //   ),
                // )
                //     : null,
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (department.description != null && department.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          department.description!,
                          style: const TextStyle(color: deptSubtleTextColor, fontSize: 13),
                        ),
                      ),
                    Text(
                      'Salary: ${department.totalSalary.toStringAsFixed(2)}',
                      style: const TextStyle(color: deptPrimaryColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: deptPrimaryColor.withOpacity(0.9), size: 22),
                      tooltip: 'Edit Department',
                      onPressed: () => _showDepartmentDialog(department: department),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700, size: 22),
                      tooltip: 'Delete Department',
                      onPressed: () => _deleteDepartment(department.id, department.name),
                    ),
                    IconButton(
                      icon: Icon(Icons.history, color: Colors.blueGrey.shade700, size: 22),
                      tooltip: 'View Salary History',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SalaryHistoryPage(
                              departmentId: department.id,
                              departmentName: department.name,
                            ),
                          ),
                        );
                      },
                    ),

                  ],
                ),
                onTap: () => _showDepartmentDialog(department: department), // Allow tap on tile to edit
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDepartmentDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ADD DEPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: deptAccentColor,
        elevation: 4.0,
        tooltip: 'Add New Department',
      ),
    );
  }
}

