import 'dart:convert';
import 'package:alsaeed_salary/Employees/replacement_details_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/ReplacementRecordmodel.dart';
import 'AddEditEmployeePage.dart';
import 'EmployeeLoansPage.dart';
import 'deactivated_employees_page.dart';
import 'employee_expenses_page.dart';



class EmployeeManagementPage extends StatefulWidget {
  const EmployeeManagementPage({super.key});

  @override
  State<EmployeeManagementPage> createState() => _EmployeeManagementPageState();
}

class _EmployeeManagementPageState extends State<EmployeeManagementPage> {
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color accentColor = Color(0xFF50E3C2);
  static const Color listSeparatorColor = Color(0xFFE0E0E0);
  static const Color textColor = Color(0xFF333333);
  static const Color subtleTextColor = Color(0xFF757575);
  static const Color _formPagePrimaryColor = Color(0xFF4A90E2);

  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  final TextEditingController _searchController = TextEditingController();
  static const String _apiBaseUrl = "http://localhost:3000/api";

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deactivateEmployee(String id) async {
    try {
      final response = await http.put(Uri.parse("$_apiBaseUrl/employees/$id/deactivate"));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Employee deactivated"), backgroundColor: Colors.orange),
        );
        _fetchEmployees(); // refresh list
      } else {
        throw Exception("Failed to deactivate employee");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deactivating employee: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _fetchEmployees() async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/employees?active=1"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _employees = data.map((e) {
          return Employee(
            id: e['id'].toString(),
            name: e['name'] ?? '',
            position: e['designation'] ?? '',
            department: e['department'] ?? '',
            joinDate: e['registerDate'] ?? '',
          );
        }).toList();
        _filteredEmployees = List.from(_employees);
        setState(() {});
      } else {
        throw Exception('Failed to load employees');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching employees: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _filterEmployees() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = List.from(_employees);
      } else {
        _filteredEmployees = _employees.where((employee) {
          return employee.name.toLowerCase().contains(query) ||
              employee.position.toLowerCase().contains(query) ||
              employee.department.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _navigateToAddEmployee(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditEmployeePage()),
    ).then((_) => _fetchEmployees()); // Refresh after add/edit
  }

  Future<void> _addLoan(String employeeId, String desc, String amount, String date) async {
    try {
      final response = await http.post(
        Uri.parse("$_apiBaseUrl/employees/$employeeId/loans"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "description": desc,
          "amount": amount,
          "loanDate": date,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Loan added successfully"), backgroundColor: Colors.green),
        );
      } else {
        throw Exception("Failed to add loan");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding loan: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddLoanDialog(Employee employee) {
    final _descController = TextEditingController();
    final _amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Loan for ${employee.name}"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: "Amount"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
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
                await _addLoan(
                  employee.id,
                  _descController.text,
                  _amountController.text,
                  selectedDate.toIso8601String(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditEmployee(BuildContext context, String employeeId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditEmployeePage(employeeId: employeeId)),
    ).then((_) => _fetchEmployees()); // Refresh after edit
  }

  void _showAddExpenseDialog(Employee employee) {
    final _descController = TextEditingController();
    final _amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Expense for ${employee.name}"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: "Amount"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10), // Fixed: Added const
                Row(
                  children: [
                    Text("Date: ${selectedDate.toLocal()}".split(' ')[0]),
                    const Spacer(), // Fixed: Added const
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
                await _addExpense(
                  employee.id,
                  _descController.text,
                  _amountController.text,
                  selectedDate.toIso8601String(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addExpense(String employeeId, String desc, String amount, String date) async {
    try {
      final response = await http.post(
        Uri.parse("$_apiBaseUrl/employees/$employeeId/expenses"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "description": desc,
          "amount": amount,
          "expenseDate": date,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Expense added successfully"), backgroundColor: Colors.green),
        );
      } else {
        throw Exception("Failed to add expense");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding expense: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _viewEmployeeDetails(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(employee.name, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow('Employee ID:', employee.id),
                _buildDetailRow('Position:', employee.position),
                _buildDetailRow('Department:', employee.department),
                _buildDetailRow('Joined On:', employee.joinDate),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Edit', style: TextStyle(color: accentColor)),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToEditEmployee(context, employee.id);
              },
            ),
            Column(
              children: [
                TextButton(
                  child: const Text('Add Loan', style: TextStyle(color: Colors.purple)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAddLoanDialog(employee);
                  },
                ),
                TextButton(
                  child: const Text('View Loans', style: TextStyle(color: Colors.purple)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeeLoansPage(
                          employeeId: employee.id,
                          employeeName: employee.name,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            Column(
              children: [
                TextButton(
                  child: const Text('Add Expense', style: TextStyle(color: Colors.orange)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAddExpenseDialog(employee);
                  },
                ),
                TextButton(
                  child: const Text('View Expenses', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeeExpensesPage(
                          employeeId: employee.id,
                          employeeName: employee.name,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            TextButton(
              child: const Text('Deactivate', style: TextStyle(color: Colors.orange)),
              onPressed: () async {
                Navigator.of(context).pop(); // close detail dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Confirm Deactivation"),
                    content: Text("Are you sure you want to deactivate ${employee.name}?"),
                    actions: [
                      TextButton(
                        child: const Text("Cancel"),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      TextButton(
                        child: const Text("Deactivate", style: TextStyle(color: Colors.orange)),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _deactivateEmployee(employee.id);
                }
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Confirm Delete"),
                    content: Text("Are you sure you want to delete ${employee.name}?"),
                    actions: [
                      TextButton(
                        child: const Text("Cancel"),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      TextButton(
                        child: const Text("Delete", style: TextStyle(color: Colors.red)),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _deleteEmployee(employee.id);
                }
              },
            ),
            TextButton(
              child: const Text('Close', style: TextStyle(color: primaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            Column(
              children: [
                TextButton(
                  child: const Text('Replace', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showReplaceEmployeeDialog(employee);
                  },
                ),
                TextButton(
                  child: const Text('Replacement History', style: TextStyle(color: Colors.teal)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _viewReplacementHistory(context, employee);
                  },
                ),
              ],
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      },
    );
  }

  void _showReplacementDetails(ReplacementRecord replacement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReplacementDetailsPage(replacement: replacement),
      ),
    );
  }



  Future<void> _generateReplacementPdf(
      BuildContext context,
      Employee employee,
      List<ReplacementRecord> replacements,
      )
  async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) => [
          pw.Center(
            child: pw.Text(
              'Replacement Chain - ${employee.name}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),

          // Build table of replacements
          pw.Table.fromTextArray(
            headers: ['Date', 'Replaced', 'With', 'Reason'],
            data: replacements.map((r) {
              return [
                r.replacementDate,
                r.oldEmployeeName ?? '-',
                r.newEmployeeName ?? '-',
                r.reason.isNotEmpty ? r.reason : '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            border: null,
            cellHeight: 25,
          ),
        ],
      ),
    );

    // Show PDF preview or directly share/print
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }


  void _viewReplacementHistory(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Replacement Chain - ${employee.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<ReplacementRecord>>(
                future: _fetchReplacementChain(employee.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    );
                  }

                  final replacements = snapshot.data ?? [];

                  if (replacements.isEmpty) {
                    return const Center(
                      child: Text('No replacement history found.', style: TextStyle(color: subtleTextColor)),
                    );
                  }

                  return Expanded(
                    child: ListView.builder(
                      itemCount: replacements.length,
                      itemBuilder: (context, index) {
                        final replacement = replacements[index];
                        final isFirst = index == 0;
                        final isLast = index == replacements.length - 1;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!isFirst) Icon(Icons.arrow_downward, color: Colors.grey, size: 16),
                                Icon(Icons.swap_horiz, color: Colors.blue),
                                if (!isLast) Icon(Icons.arrow_downward, color: Colors.grey, size: 16),
                              ],
                            ),
                            title: Text(
                              replacement.replacementDate,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (replacement.oldEmployeeName != null)
                                  Text('Replaced: ${replacement.oldEmployeeName}'),
                                if (replacement.newEmployeeName != null)
                                  Text('With: ${replacement.newEmployeeName}'),
                                if (replacement.reason.isNotEmpty)
                                  Text('Reason: ${replacement.reason}'),
                                if (index < replacements.length - 1)
                                  Text('↓ Continued...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.visibility, color: primaryColor),
                              onPressed: () {
                                Navigator.pop(context);
                                _showReplacementDetails(replacement);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text("Export PDF"),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: () async {
                  final replacements = await _fetchReplacementChain(employee.id);
                  if (context.mounted) {
                    await _generateReplacementPdf(context, employee, replacements);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<ReplacementRecord>> _fetchReplacementChain(String employeeId) async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/employees/$employeeId/replacement-chain"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => ReplacementRecord.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load replacement chain');
      }
    } catch (e) {
      throw Exception('Error fetching replacement chain: $e');
    }
  }

  Future<List<String>> _fetchDepartments(String query) async {
    final response = await http.get(Uri.parse("$_apiBaseUrl/departments"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((dept) => dept["name"].toString())
          .where((name) => name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      throw Exception("Failed to load departments");
    }
  }

  void _showReplaceEmployeeDialog(Employee oldEmployee) async {
    final _nameController = TextEditingController();
    final _fatherNameController = TextEditingController();
    final _ageController = TextEditingController();
    final _educationController = TextEditingController();
    final _designationController = TextEditingController();
    final _departmentController = TextEditingController();
    final _salaryController = TextEditingController();
    final _referenceController = TextEditingController();
    final _idCardNumberController = TextEditingController();
    final _addressController = TextEditingController();
    final _phoneNumberController = TextEditingController();
    final _reasonController = TextEditingController();

    DateTime registerDate = DateTime.now();

    // FIXED: Get the previous replacement ID before showing the dialog
    String? previousReplacementId = await _getLatestReplacementId(oldEmployee.id);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Replace ${oldEmployee.name}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Personal Information
                        _buildReplaceTextField(_nameController, "New Employee Name*", Icons.person),
                        _buildReplaceTextField(_fatherNameController, "Father's Name", Icons.person_outline),
                        _buildReplaceTextField(_ageController, "Age", Icons.cake, TextInputType.number),
                        _buildReplaceTextField(_idCardNumberController, "ID Card Number*", Icons.badge),

                        // Contact Information
                        _buildReplaceTextField(_phoneNumberController, "Phone Number*", Icons.phone, TextInputType.phone),
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: "Address",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),

                        // Professional Information
                        _buildReplaceTextField(_educationController, "Education", Icons.school),
                        _buildReplaceTextField(_designationController, "Designation*", Icons.work),

                        // Department with TypeAhead
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TypeAheadField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _departmentController,
                              decoration: const InputDecoration(
                                labelText: 'Department*',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.business),
                              ),
                            ),
                            suggestionsCallback: (pattern) async {
                              return await _fetchDepartments(pattern);
                            },
                            itemBuilder: (context, String suggestion) {
                              return ListTile(title: Text(suggestion));
                            },
                            onSuggestionSelected: (String suggestion) {
                              _departmentController.text = suggestion;
                            },
                          ),
                        ),

                        _buildReplaceTextField(_salaryController, "Salary*", Icons.attach_money, TextInputType.number),
                        _buildReplaceTextField(_referenceController, "Reference", Icons.person_search),

                        // Reason for replacement
                        TextField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            labelText: "Reason for Replacement*",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        // Validate required fields
                        if (_nameController.text.isEmpty ||
                            _designationController.text.isEmpty ||
                            _departmentController.text.isEmpty ||
                            _salaryController.text.isEmpty ||
                            _idCardNumberController.text.isEmpty ||
                            _phoneNumberController.text.isEmpty ||
                            _reasonController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all required fields"), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        Navigator.pop(context);
                        await _replaceEmployee(
                          oldEmployee.id,
                          _nameController.text,
                          _fatherNameController.text,
                          _ageController.text,
                          _educationController.text,
                          _designationController.text,
                          _departmentController.text,
                          _salaryController.text,
                          _referenceController.text,
                          _idCardNumberController.text,
                          _addressController.text,
                          _phoneNumberController.text,
                          _reasonController.text,
                          registerDate.toIso8601String(),
                          previousReplacementId, // FIXED: Now properly defined
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Replace Employee", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _getLatestReplacementId(String employeeId) async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/employees/$employeeId/latest-replacement"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id']?.toString();
      }
    } catch (e) {
      debugPrint('Error getting latest replacement: $e');
    }
    return null;
  }

  Widget _buildReplaceTextField(TextEditingController controller, String label, IconData icon, [TextInputType keyboardType = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Future<void> _replaceEmployee(
      String oldId,
      String name,
      String fatherName,
      String age,
      String education,
      String designation,
      String department,
      String salary,
      String reference,
      String idCardNumber,
      String address,
      String phoneNumber,
      String reason,
      String date,
      String? previousReplacementId, // New parameter for chain tracking
      )
  async {
    try {
      final response = await http.post(
        Uri.parse("$_apiBaseUrl/employees/$oldId/replace"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "registerDate": date,
          "name": name,
          "fatherName": fatherName,
          "age": age,
          "education": education,
          "designation": designation,
          "department": department,
          "salary": salary,
          "reference": reference,
          "idCardNumber": idCardNumber,
          "address": address,
          "phoneNumber": phoneNumber,
          "reason": reason,
          "previousReplacementId": previousReplacementId, // Track the chain
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Employee replaced successfully"), backgroundColor: Colors.green),
        );
        _fetchEmployees();
      } else {
        throw Exception("Failed to replace employee: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error replacing employee: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteEmployee(String id) async {
    try {
      final response = await http.delete(Uri.parse("$_apiBaseUrl/employees/$id"));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Employee deleted successfully"), backgroundColor: Colors.green),
        );
        _fetchEmployees(); // Refresh list
      } else {
        throw Exception("Failed to delete employee");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting employee: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: TextStyle(fontWeight: FontWeight.w600, color: textColor.withOpacity(0.9))),
          Expanded(child: Text(value, style: TextStyle(color: subtleTextColor))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Employees', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.block, color: Colors.white),
            tooltip: "Deactivated Employees",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeactivatedEmployeesPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, position, department...',
                prefixIcon: Icon(Icons.search, color: primaryColor.withOpacity(0.7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: const BorderSide(color: primaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),
          Expanded(
            child: _filteredEmployees.isEmpty
                ? Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'No employees found.\nTap the "+" button to add one.'
                    : 'No employees match your search.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: subtleTextColor),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: _filteredEmployees.length,
              itemBuilder: (context, index) {
                final employee = _filteredEmployees[index];
                return Card(
                  elevation: 1.5,
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: accentColor.withOpacity(0.2),
                      child: Text(
                        employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(employee.name, style: const TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                    subtitle: Text('${employee.position} - ${employee.department}', style: const TextStyle(color: subtleTextColor, fontSize: 13)),
                    trailing: IconButton(
                      icon: Icon(Icons.more_vert, color: primaryColor.withOpacity(0.7)),
                      onPressed: () {
                        _viewEmployeeDetails(context, employee);
                      },
                    ),
                    onTap: () => _viewEmployeeDetails(context, employee),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 0),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEmployee(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ADD EMPLOYEE', style: TextStyle(color: Colors.white)),
        backgroundColor: accentColor,
      ),
    );
  }
}