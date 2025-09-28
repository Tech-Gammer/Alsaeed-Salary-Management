import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../modelpayroll.dart';
import 'create_payroll_period_page.dart';

class PayrollProcessingPage extends StatefulWidget {
  const PayrollProcessingPage({super.key});

  @override
  State<PayrollProcessingPage> createState() => _PayrollProcessingPageState();
}

class _PayrollProcessingPageState extends State<PayrollProcessingPage> {
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color secondaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF2D3748);

  List<Department> _departments = [];
  List<PayrollPeriod> _periods = [];
  Department? _selectedDepartment;
  PayrollPeriod? _selectedPeriod;
  List<EmployeePayroll> _employees = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  static const String _apiBaseUrl = "http://localhost:3000/api";

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchPeriods();
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/departments"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _departments = data.map((dept) => Department.fromJson(dept)).toList();
        });
      }
    } catch (e) {
      _showError("Error fetching departments: $e");
    }
  }

  Future<void> _fetchPeriods() async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/payroll/periods"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _periods = data.map((period) => PayrollPeriod.fromJson(period)).toList();
        });
      } else {
        _showError("Failed to fetch periods: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching periods: $e");
    }
  }

  Future<void> _loadDepartmentEmployees() async {
    if (_selectedDepartment == null) return;

    setState(() { _isLoading = true; });

    try {
      final response = await http.get(
          Uri.parse("$_apiBaseUrl/payroll/department/${_selectedDepartment!.id}/employees")
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _employees = data.map((emp) => EmployeePayroll.fromJson(emp)).toList();
        });
      } else {
        _showError("Failed to load employees: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error loading employees: $e");
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _generatePayroll() async {
    if (_selectedDepartment == null || _selectedPeriod == null) {
      _showError("Please select department and period");
      return;
    }

    setState(() { _isGenerating = true; });

    try {
      final payrollEmployees = _employees.map((emp) {
        final calculatedBasicSalary = _calculateEmployeeSalary(emp);
        final allowances = calculatedBasicSalary * 0.1;
        final deductions = calculatedBasicSalary * 0.05;
        final netSalary = calculatedBasicSalary + allowances - deductions;

        final dailyRate = emp.salary / 30;
        final workingSalary = dailyRate * emp.workingDays;
        final leaveSalary = dailyRate * emp.leaveDays;

        // Prepare components
        final components = [
          {"type": "allowance", "name": "House Rent", "amount": allowances},
          {"type": "deduction", "name": "Tax", "amount": deductions},
        ];

        // Add working salary breakdown if not full month
        if (emp.workingDays > 0 && emp.workingDays < 30) {
          components.addAll([
            {"type": "allowance", "name": "Working Days Salary", "amount": workingSalary},
            {"type": "allowance", "name": "Leave Days Salary", "amount": leaveSalary},
          ]);
        }

        return {
          "employee_id": emp.id,
          "basic_salary": calculatedBasicSalary,
          "allowances": allowances,
          "deductions": deductions,
          "net_salary": netSalary,
          "working_days": emp.workingDays,
          "leave_days": emp.leaveDays,
          "daily_rate": dailyRate,
          "working_salary": workingSalary,
          "leave_salary": leaveSalary,
          "components": components,
        };
      }).toList();

      final response = await http.post(
        Uri.parse("$_apiBaseUrl/payroll/department/${_selectedDepartment!.id}/generate"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "period_id": _selectedPeriod!.id,
          "employees": payrollEmployees,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Payroll generated successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _viewGeneratedPayroll();
      } else {
        _showError("Failed to generate payroll: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error generating payroll: $e");
    } finally {
      setState(() { _isGenerating = false; });
    }
  }

  void _viewGeneratedPayroll() {
    if (_selectedDepartment == null || _selectedPeriod == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DepartmentPayrollPage(
          departmentId: _selectedDepartment!.id,
          periodId: _selectedPeriod!.id,
          departmentName: _selectedDepartment!.name,
          periodName: _selectedPeriod!.periodName,
        ),
      ),
    );
  }

  String _calculateDays(PayrollPeriod period) {
    if (period.periodType == 'full_month') {
      return '30';
    } else {
      final start = DateTime.parse(period.startDate);
      final end = DateTime.parse(period.endDate);
      return (end.difference(start).inDays + 1).toString();
    }
  }

  void _navigateToCreatePeriod(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePayrollPeriodPage()),
    ).then((_) {
      _fetchPeriods();
    });
  }

  Widget _buildSelectionCard() {
    return Card(
      elevation: 2,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_alt, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "SELECTION CRITERIA",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDepartmentDropdown(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPeriodDropdown(),
                ),
                const SizedBox(width: 8),
                _buildAddPeriodButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Department",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Department>(
              value: _selectedDepartment,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: primaryColor),
              items: _departments.map((dept) {
                return DropdownMenuItem(
                  value: dept,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      dept.name,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (dept) {
                setState(() {
                  _selectedDepartment = dept;
                  _employees.clear();
                });
                if (dept != null) _loadDepartmentEmployees();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Payroll Period",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        _periods.isEmpty
            ? OutlinedButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Create Period"),
          onPressed: () => _navigateToCreatePeriod(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: BorderSide(color: primaryColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        )
            : Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PayrollPeriod>(
              value: _selectedPeriod,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: primaryColor),
              items: _periods.map((period) {
                final periodType = period.periodType == 'full_month' ? '📅 Full Month' : '📋 Custom Range';
                final days = _calculateDays(period);
                return DropdownMenuItem(
                  value: period,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          period.periodName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '$periodType • $days days',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (period) {
                setState(() {
                  _selectedPeriod = period;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPeriodButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            onPressed: () => _navigateToCreatePeriod(context),
            tooltip: "Create New Period",
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeesSection() {
    if (_selectedDepartment == null) {
      return const SizedBox();
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                const Icon(Icons.people, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "EMPLOYEES IN ${_selectedDepartment!.name.toUpperCase()}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "${_employees.length} employees",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildEmployeesList(),
          ),
        ],
      ),
    );
  }


  Widget _buildEmployeesList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(primaryColor)),
            const SizedBox(height: 16),
            Text(
              "Loading Employees...",
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No Employees Found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Select a department to view employees",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final emp = _employees[index];
        // Calculate salary whenever the widget builds
        emp.calculatedSalary = _calculateEmployeeSalary(emp);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 1,
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Employee basic info row
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            emp.name[0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emp.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              emp.designation,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${emp.salary.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "₹${emp.calculatedSalary.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: secondaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Days input section - only show for full_month period
                  if (_selectedPeriod?.periodType == 'full_month') ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Working Days Input
                        _buildDayInputSection(emp, true),
                        const SizedBox(width: 16),
                        // Leave Days Input
                        _buildDayInputSection(emp, false),
                        const SizedBox(width: 16),
                        // Calculation Info
                        _buildCalculationInfo(emp),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayInputSection(EmployeePayroll emp, bool isWorkingDays) {
    final label = isWorkingDays ? "Working Days" : "Leave Days";
    final currentValue = isWorkingDays ? emp.workingDays : emp.leaveDays;
    final icon = isWorkingDays ? Icons.work : Icons.beach_access;
    final color = isWorkingDays ? Colors.green : Colors.orange;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove, size: 16, color: color),
                  onPressed: () {
                    _updateEmployeeDays(emp, isWorkingDays, -1);
                  },
                  padding: const EdgeInsets.all(4),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      currentValue.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, size: 16, color: color),
                  onPressed: () {
                    _updateEmployeeDays(emp, isWorkingDays, 1);
                  },
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationInfo(EmployeePayroll emp) {
    final totalMonthDays = 30;
    final dailyRate = emp.salary / totalMonthDays;
    final workingSalary = dailyRate * emp.workingDays;
    final leaveSalary = dailyRate * emp.leaveDays;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Calculation",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Daily: ₹${dailyRate.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          Text(
            "Work: ₹${workingSalary.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 10, color: Colors.green.shade600),
          ),
          Text(
            "Leave: ₹${leaveSalary.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 10, color: Colors.orange.shade600),
          ),
        ],
      ),
    );
  }

  void _updateEmployeeDays(EmployeePayroll emp, bool isWorkingDays, int change) {
    setState(() {
      if (isWorkingDays) {
        final newValue = emp.workingDays + change;
        emp.workingDays = newValue.clamp(0, 30); // Limit between 0-30 days
      } else {
        final newValue = emp.leaveDays + change;
        emp.leaveDays = newValue.clamp(0, 30); // Limit between 0-30 days
      }

      // Recalculate salary
      emp.calculatedSalary = _calculateEmployeeSalary(emp);
    });
  }

  double _calculateEmployeeSalary(EmployeePayroll emp) {
    if (_selectedPeriod == null) return emp.salary;

    if (_selectedPeriod!.periodType == 'full_month') {
      // For full month period with custom days calculation
      final totalMonthDays = 30; // Standard month days

      // Use provided working days or default to full month
      final workingDays = emp.workingDays > 0 ? emp.workingDays : totalMonthDays;
      final leaveDays = emp.leaveDays;

      // Daily rate based on monthly salary
      final dailyRate = emp.salary / totalMonthDays;

      // Calculate base salary for working days
      final workingSalary = dailyRate * workingDays;

      // Calculate leave salary (for paid leaves)
      final leaveSalary = dailyRate * leaveDays;

      // Total salary = working salary + leave salary
      final totalSalary = workingSalary + leaveSalary;

      return totalSalary;

    } else {
      // For custom range period - use the original logic
      final startDate = DateTime.parse(_selectedPeriod!.startDate);
      final endDate = DateTime.parse(_selectedPeriod!.endDate);
      final totalDays = endDate.difference(startDate).inDays + 1;
      final dailyRate = emp.salary / 30; // Standard daily rate

      return dailyRate * totalDays;
    }
  }

  Widget _buildGenerateButton() {
    if (_employees.isEmpty || _selectedPeriod == null) {
      return const SizedBox();
    }

    return Column(
      children: [
        if (_selectedPeriod?.periodType == 'full_month')
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetAllDays,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("RESET ALL DAYS"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePayroll,
              icon: _isGenerating
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
              )
                  : const Icon(Icons.play_arrow, size: 24),
              label: _isGenerating
                  ? const Text("GENERATING...")
                  : const Text("GENERATE PAYROLL"),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _resetAllDays() {
    setState(() {
      for (var emp in _employees) {
        emp.workingDays = 0; // Reset to 0, will default to 30 in calculation
        emp.leaveDays = 0;
        emp.calculatedSalary = _calculateEmployeeSalary(emp);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Payroll Processing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectionCard(),
            const SizedBox(height: 20),
            _buildEmployeesSection(),
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }
}

class DepartmentPayrollPage extends StatefulWidget {
  final int departmentId;
  final int periodId;
  final String departmentName;
  final String periodName;

  const DepartmentPayrollPage({
    super.key,
    required this.departmentId,
    required this.periodId,
    required this.departmentName,
    required this.periodName,
  });

  @override
  State<DepartmentPayrollPage> createState() => _DepartmentPayrollPageState();
}

class _DepartmentPayrollPageState extends State<DepartmentPayrollPage> {
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color secondaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF2D3748);

  List<dynamic> _payrollData = [];
  bool _isLoading = true;
  bool _isGeneratingAll = false;
  static const String _apiBaseUrl = "http://localhost:3000/api";

  @override
  void initState() {
    super.initState();
    _fetchPayrollData();
  }

  Future<void> _fetchPayrollData() async {
    try {
      final response = await http.get(
          Uri.parse("$_apiBaseUrl/payroll/department/${widget.departmentId}/period/${widget.periodId}")
      );

      if (response.statusCode == 200) {
        setState(() {
          _payrollData = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError("Error fetching payroll: $e");
      setState(() { _isLoading = false; });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _generatePayslip(int payrollId, String employeeName) async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/payroll/payslip/$payrollId"));
      if (response.statusCode == 200) {
        final payslipData = jsonDecode(response.body);
        await _generatePdfPayslip(payslipData, employeeName);
      }
    } catch (e) {
      _showError("Error generating payslip: $e");
    }
  }

  Future<void> _generatePdfPayslip(Map<String, dynamic> payslipData, String employeeName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'PAYSLIP',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Company: Al Saeed Salary System'),
                      pw.Text('Department: ${payslipData['department_name']}'),
                      pw.Text('Period: ${payslipData['period_name']}'),
                      pw.Text('Type: ${payslipData['period_type'] == 'full_month' ? 'Full Month (30 days)' : 'Custom Range'}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Employee: $employeeName'),
                      pw.Text('ID: ${payslipData['id_card_number']}'),
                      pw.Text('Designation: ${payslipData['designation']}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Salary Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Basic Salary:'),
                  pw.Text('₹${payslipData['basic_salary']}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Allowances:'),
                  pw.Text('₹${payslipData['allowances']}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Deductions:'),
                  pw.Text('₹${payslipData['deductions']}'),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Net Salary:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('₹${payslipData['net_salary']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _generateAllPayslips() async {
    setState(() { _isGeneratingAll = true; });

    try {
      for (final payroll in _payrollData) {
        await _generatePayslip(payroll['id'], payroll['employee_name']);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      _showSuccess("All payslips generated successfully");
    } finally {
      setState(() { _isGeneratingAll = false; });
    }
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
             Icon(Icons.summarize, color: primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.departmentName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "Period: ${widget.periodName}",
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "${_payrollData.length} employees",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollList() {
    if (_isLoading) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(primaryColor)),
              const SizedBox(height: 16),
              Text(
                "Loading Payroll Data...",
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_payrollData.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "No Payroll Data",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Payroll data will appear here after generation",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                const Icon(Icons.attach_money, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "PAYROLL SUMMARY",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isGeneratingAll ? null : _generateAllPayslips,
                  icon: _isGeneratingAll
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                      : const Icon(Icons.picture_as_pdf, size: 18),
                  label: Text(_isGeneratingAll ? "GENERATING..." : "GENERATE ALL"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _payrollData.length,
              itemBuilder: (context, index) {
                final payroll = _payrollData[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 1,
                    color: cardColor,
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            payroll['employee_name'][0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        payroll['employee_name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildSalaryItem("Basic", payroll['basic_salary']),
                              const SizedBox(width: 12),
                              _buildSalaryItem("Allowances", payroll['allowances'], isPositive: true),
                              const SizedBox(width: 12),
                              _buildSalaryItem("Deductions", payroll['deductions'], isPositive: false),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: secondaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "Net: ₹${payroll['net_salary']}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.receipt, color: primaryColor, size: 20),
                        ),
                        onPressed: () => _generatePayslip(payroll['id'], payroll['employee_name']),
                        tooltip: "Generate Payslip",
                      ),
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

  Widget _buildSalaryItem(String label, dynamic amount, {bool isPositive = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          "₹$amount",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Department Payroll', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildPayrollList(),
          ],
        ),
      ),
    );
  }
}