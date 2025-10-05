import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/kharchamodel.dart';
import '../models/modelpayroll.dart';
import 'create_payroll_period_page.dart';

class PayrollProcessingPage extends StatefulWidget {
  const PayrollProcessingPage({super.key});

  @override
  State<PayrollProcessingPage> createState() => _PayrollProcessingPageState();
}

class _PayrollProcessingPageState extends State<PayrollProcessingPage> {
  // Enhanced Color Palette
  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color secondaryColor = Color(0xFF10B981);
  static const Color accentColor = Color(0xFFF59E0B);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  List<Department> _departments = [];
  List<PayrollPeriod> _periods = [];
  Department? _selectedDepartment;
  PayrollPeriod? _selectedPeriod;
  List<EmployeePayroll> _employees = [];
  List<EmployeePayroll> _selectedEmployees = [];
  List<Kharcha> _kharchas = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _selectAllEmployees = true;
  final Map<int, TextEditingController> _workingDaysControllers = {};
  final Map<int, TextEditingController> _leaveDaysControllers = {};
  static const String _apiBaseUrl = "http://localhost:3000/api";

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchPeriods();
  }

  @override
  void dispose() {
    _workingDaysControllers.forEach((_, controller) => controller.dispose());
    _leaveDaysControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // --- DATA FETCHING METHODS ---
  Future<void> _fetchDepartments() async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/departments"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() => _departments = data.map((dept) => Department.fromJson(dept)).toList());
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
        setState(() => _periods = data.map((period) => PayrollPeriod.fromJson(period)).toList());
      } else {
        _showError("Failed to fetch periods: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching periods: $e");
    }
  }

  Future<void> _loadDepartmentEmployees() async {
    if (_selectedDepartment == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/payroll/department/${_selectedDepartment!.id}/employees"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _employees = data.map((emp) => EmployeePayroll.fromJson(emp)).toList();
          _selectedEmployees = List.from(_employees);
          _workingDaysControllers.clear();
          _leaveDaysControllers.clear();
          _initializeControllers();
        });
        await _fetchKharchas();
      } else {
        _showError("Failed to load employees: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error loading employees: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchKharchas() async {
    if (_selectedDepartment == null || _selectedPeriod == null) return;
    try {
      final params = {'period_id': _selectedPeriod!.id.toString()};
      final url = Uri.parse("$_apiBaseUrl/kharcha").replace(queryParameters: params);
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List kharchaList = (data is Map && data.containsKey('kharchas')) ? (data['kharchas'] ?? []) : (data is List ? data : []);
        final List<Kharcha> parsedKharchas = kharchaList.map((k) => Kharcha.fromJson(k)).toList();
        setState(() => _kharchas = parsedKharchas);
      } else {
        print("❌ Failed to load kharchas: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error loading kharchas: $e");
    }
  }

  void _initializeControllers() {
    for (var emp in _employees) {
      _workingDaysControllers[emp.id] = TextEditingController(text: emp.workingDays.toString());
      _leaveDaysControllers[emp.id] = TextEditingController(text: emp.leaveDays.toString());
    }
  }

  // --- UI HELPER METHODS ---
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(Icons.error_outline, color: surfaceColor, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: errorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // --- PAYROLL LOGIC ---
  double _getEmployeeKharcha(int employeeId) => _kharchas.where((k) => k.employeeId == employeeId && k.kharchaType == 'individual').fold(0.0, (sum, k) => sum + k.amount);
  double _getDepartmentKharcha() => _kharchas.where((k) => k.kharchaType == 'department' && k.departmentId == _selectedDepartment?.id).fold(0.0, (sum, k) => sum + k.amount);
  bool _hasDepartmentKharcha() => _kharchas.any((k) => k.kharchaType == 'department' && k.departmentId == _selectedDepartment?.id);

  double _getTotalKharchaForEmployee(int employeeId) {
    final individualKharcha = _getEmployeeKharcha(employeeId);
    final departmentKharchaShare = _hasDepartmentKharcha() && _selectedEmployees.isNotEmpty ? _getDepartmentKharcha() / _selectedEmployees.length : 0.0;
    return individualKharcha + departmentKharchaShare;
  }

  void _updateEmployeeDays(EmployeePayroll emp, bool isWorkingDays, String value) {
    final int? newValue = int.tryParse(value);
    if (newValue == null && value.isNotEmpty) {
      final controller = isWorkingDays ? _workingDaysControllers[emp.id] : _leaveDaysControllers[emp.id];
      final oldValue = isWorkingDays ? emp.workingDays : emp.leaveDays;
      controller?.text = oldValue.toString();
      controller?.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
      return;
    }

    setState(() {
      if (isWorkingDays) {
        emp.workingDays = newValue ?? 0;
      } else {
        emp.leaveDays = newValue ?? 0;
      }
    });
  }

  double _calculateNetSalary(EmployeePayroll emp) {
    if (_selectedPeriod == null) return emp.salary;

    double totalSalary;
    final dailyRate = emp.salary / 30;

    if (_selectedPeriod!.periodType == 'full_month') {
      totalSalary = (emp.workingDays * dailyRate) + (emp.leaveDays * dailyRate);
    } else {
      final start = DateTime.parse(_selectedPeriod!.startDate);
      final end = DateTime.parse(_selectedPeriod!.endDate);
      final days = end.difference(start).inDays + 1;
      totalSalary = days * dailyRate;
    }

    final netSalary = totalSalary - _getTotalKharchaForEmployee(emp.id);
    return netSalary < 0 ? 0 : netSalary;
  }

  // --- ACTIONS ---
  void _toggleSelectAll() {
    setState(() {
      _selectAllEmployees = !_selectAllEmployees;
      if (_selectAllEmployees) {
        _selectedEmployees = List.from(_employees);
      } else {
        _selectedEmployees.clear();
      }
    });
  }

  void _toggleEmployeeSelection(EmployeePayroll employee) {
    setState(() {
      if (_selectedEmployees.contains(employee)) {
        _selectedEmployees.remove(employee);
      } else {
        _selectedEmployees.add(employee);
      }
      _selectAllEmployees = _selectedEmployees.length == _employees.length;
    });
  }

  void _navigateToCreatePeriod() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePayrollPeriodPage()))
        .then((_) => _fetchPeriods());
  }

  Future<void> _generatePayroll() async {
    if (_selectedDepartment == null || _selectedPeriod == null || _selectedEmployees.isEmpty) {
      _showError("Please select a department, period, and at least one employee.");
      return;
    }
    setState(() => _isGenerating = true);

    // Your existing payroll generation logic here
    await Future.delayed(const Duration(seconds: 1));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: surfaceColor, size: 20),
          SizedBox(width: 8),
          Text("Payroll for ${_selectedEmployees.length} employees generated successfully!"),
        ],
      ),
      backgroundColor: successColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));

    setState(() => _isGenerating = false);
  }

  // --- ENHANCED UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          _buildSidePanel(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Container(
      width: 360,
      color: surfaceColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.payments, color: surfaceColor, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Payroll Processing",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                        Text("Generate employee payroll",
                            style: TextStyle(fontSize: 14, color: textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Divider(color: borderColor),
            ],
          ),

          SizedBox(height: 24),

          // Department Section
          _buildSectionHeader("Department", Icons.business_center),
          SizedBox(height: 8),
          _buildDepartmentDropdown(),

          SizedBox(height: 20),

          // Period Section
          _buildSectionHeader("Payroll Period", Icons.calendar_month),
          SizedBox(height: 8),
          _buildPeriodDropdown(),

          if (_periods.isEmpty) ...[
            SizedBox(height: 12),
            _buildCreatePeriodButton(),
          ],

          Spacer(),

          // Kharcha Summary
          if (_kharchas.isNotEmpty) _buildKharchaSummaryCard(),

          SizedBox(height: 20),

          // Generate Button
          _buildGenerateButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 14)),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Department>(
          isExpanded: true,
          value: _selectedDepartment,
          items: _departments.map((dept) => DropdownMenuItem(
            value: dept,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(dept.name, style: TextStyle(fontSize: 14)),
            ),
          )).toList(),
          onChanged: (dept) {
            setState(() {
              _selectedDepartment = dept;
              _employees.clear();
              _selectedEmployees.clear();
              _kharchas.clear();
            });
            if (dept != null) _loadDepartmentEmployees();
          },
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text("Select Department", style: TextStyle(color: textTertiary)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PayrollPeriod>(
          isExpanded: true,
          value: _selectedPeriod,
          items: _periods.map((period) {
            final days = (period.periodType == 'full_month')
                ? '30 days'
                : '${DateTime.parse(period.endDate).difference(DateTime.parse(period.startDate)).inDays + 1} days';
            return DropdownMenuItem(
              value: period,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(period.periodName, style: TextStyle(fontSize: 14)),
                    SizedBox(height: 2),
                    Text(days, style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (period) {
            setState(() => _selectedPeriod = period);
            if (_selectedDepartment != null) _fetchKharchas();
          },
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text("Select Period", style: TextStyle(color: textTertiary)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildCreatePeriodButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.add, size: 16),
        label: Text("Create New Period"),
        onPressed: _navigateToCreatePeriod,
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildKharchaSummaryCard() {
    final departmentKharcha = _getDepartmentKharcha();
    final individualKharcha = _kharchas.fold(0.0, (sum, k) => k.kharchaType == 'individual' ? sum + k.amount : sum);
    final totalKharcha = departmentKharcha + individualKharcha;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.account_balance_wallet, size: 18, color: warningColor),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Kharcha Summary", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text("₹${totalKharcha.toStringAsFixed(2)} total",
                        style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKharchaItem("Department", departmentKharcha),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildKharchaItem("Individual", individualKharcha),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKharchaItem(String label, double amount) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
          SizedBox(height: 4),
          Text("₹${amount.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isGenerating
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: surfaceColor))
            : Icon(Icons.play_arrow, size: 20),
        label: Text(_isGenerating ? "GENERATING..." : "GENERATE PAYROLL"),
        onPressed: (_selectedEmployees.isEmpty || _isGenerating) ? null : _generatePayroll,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: surfaceColor,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentHeader(),
          SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _employees.isEmpty
                ? _buildEmptyState()
                : _buildEmployeeList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentHeader() {
    return Row(
      children: [
        Text("Employee List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
        Spacer(),
        if (_employees.isNotEmpty) ...[
          Text("${_selectedEmployees.length} of ${_employees.length} selected",
              style: TextStyle(fontSize: 14, color: textSecondary)),
          SizedBox(width: 16),
          _buildSelectAllToggle(),
        ],
      ],
    );
  }

  Widget _buildSelectAllToggle() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: _selectAllEmployees,
            onChanged: (val) => _toggleSelectAll(),
            visualDensity: VisualDensity.compact,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text("Select All", style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(primaryColor)),
          SizedBox(height: 16),
          Text("Loading employees...", style: TextStyle(fontSize: 16, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: textTertiary),
          SizedBox(height: 16),
          Text(
            _selectedDepartment == null ? "Select a Department" : "No Employees Found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            _selectedDepartment == null
                ? "Choose a department from the side panel to load employees"
                : "No employees found in the selected department",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    return Column(
      children: [
        // Table Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              SizedBox(width: 40), // Checkbox space
              Expanded(flex: 3, child: Text("EMPLOYEE", style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
              Expanded(flex: 2, child: Text("BASE SALARY", style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
              Expanded(flex: 2, child: Text("KHARCHA", style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
              if (_selectedPeriod?.periodType == 'full_month') ...[
                Expanded(flex: 1, child: Text("WORK DAYS", style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
                Expanded(flex: 1, child: Text("LEAVE DAYS", style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
              ],
              Expanded(flex: 2, child: Text("NET SALARY", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary, fontSize: 12))),
            ],
          ),
        ),
        SizedBox(height: 8),

        // Employee List
        Expanded(
          child: ListView.builder(
            itemCount: _employees.length,
            itemBuilder: (context, index) {
              final emp = _employees[index];
              final isSelected = _selectedEmployees.contains(emp);
              return _buildEmployeeItem(emp, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeItem(EmployeePayroll emp, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? primaryLight : surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? primaryColor : borderColor, width: isSelected ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Checkbox(
              value: isSelected,
              onChanged: (val) => _toggleEmployeeSelection(emp),
              visualDensity: VisualDensity.compact,
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emp.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  SizedBox(height: 2),
                  Text(emp.designation, style: TextStyle(color: textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
          Expanded(flex: 2, child: Text("₹${emp.salary.toStringAsFixed(2)}", style: TextStyle(fontSize: 14))),
          Expanded(flex: 2, child: Text("₹${_getTotalKharchaForEmployee(emp.id).toStringAsFixed(2)}",
              style: TextStyle(color: warningColor, fontSize: 14, fontWeight: FontWeight.w500))),
          if (_selectedPeriod?.periodType == 'full_month') ...[
            Expanded(flex: 1, child: _buildDaysInput(emp, true)),
            Expanded(flex: 1, child: _buildDaysInput(emp, false)),
          ],
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                "₹${_calculateNetSalary(emp).toStringAsFixed(2)}",
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.bold, color: successColor, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysInput(EmployeePayroll emp, bool isWorkingDays) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: 36,
        child: TextField(
          controller: isWorkingDays ? _workingDaysControllers[emp.id] : _leaveDaysControllers[emp.id],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: surfaceColor,
            hintText: isWorkingDays ? "Days" : "Leave",
            hintStyle: TextStyle(fontSize: 12, color: textTertiary),
          ),
          style: TextStyle(fontSize: 13),
          onChanged: (value) => _updateEmployeeDays(emp, isWorkingDays, value),
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
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF7C3AED);
  static const Color accentColor = Color(0xFF059669);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

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
      } else {
        _showError("Failed to fetch payroll data: ${response.statusCode}");
        setState(() { _isLoading = false; });
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
            Icon(Icons.error_outline, color: surfaceColor),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: surfaceColor),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _generatePayslip(int payrollId, String employeeName) async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/payroll/payslip/$payrollId"));
      if (response.statusCode == 200) {
        final payslipData = jsonDecode(response.body);
        await _generatePdfPayslip(payslipData, employeeName);
        _showSuccess("Payslip generated for $employeeName");
      } else {
        _showError("Failed to generate payslip: ${response.statusCode}");
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
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'AL SAEED SALARY SYSTEM',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'PAYSLIP',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Company and Employee Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Company Information',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Company: Al Saeed Salary System'),
                        pw.Text('Department: ${payslipData['department_name']}'),
                        pw.Text('Period: ${payslipData['period_name']}'),
                        pw.Text('Type: ${payslipData['period_type'] == 'full_month' ? 'Full Month (30 days)' : 'Custom Range'}'),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Employee Information',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Employee: $employeeName'),
                        pw.Text('ID: ${payslipData['id_card_number'] ?? 'N/A'}'),
                        pw.Text('Designation: ${payslipData['designation']}'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Salary Details
              pw.Text(
                'Salary Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 10),

              // Salary Breakdown Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blue50),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount (₹)',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Basic Salary'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${payslipData['basic_salary']}',
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Allowances'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${payslipData['allowances']}',
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Deductions'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${payslipData['deductions']}',
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Net Salary',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${payslipData['net_salary']}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'This is a computer-generated payslip and does not require signature.',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                        fontStyle: pw.FontStyle.italic,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _generateAllPayslips() async {
    setState(() { _isGeneratingAll = true; });

    try {
      for (final payroll in _payrollData) {
        await _generatePayslip(payroll['id'], payroll['employee_name']);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      _showSuccess("All payslips generated successfully");
    } catch (e) {
      _showError("Error generating payslips: $e");
    } finally {
      setState(() { _isGeneratingAll = false; });
    }
  }

  Widget _buildHeader() {
    return Card(
      elevation: 1,
      color: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.summarize, color: primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.departmentName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Period: ${widget.periodName}",
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Generated on: ${DateFormat('dd MMM yyyy').format(DateTime.now())}",
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    "${_payrollData.length} employees",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_payrollData.isEmpty) return const SizedBox();

    final totalBasic = _payrollData.fold<double>(0, (sum, item) => sum + (item['basic_salary'] ?? 0));
    final totalAllowances = _payrollData.fold<double>(0, (sum, item) => sum + (item['allowances'] ?? 0));
    final totalDeductions = _payrollData.fold<double>(0, (sum, item) => sum + (item['deductions'] ?? 0));
    final totalNet = _payrollData.fold<double>(0, (sum, item) => sum + (item['net_salary'] ?? 0));

    return Card(
      elevation: 1,
      color: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.analytics, color: accentColor, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  "PAYROLL SUMMARY",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryCard("Total Basic", totalBasic, Icons.attach_money, primaryColor),
                const SizedBox(width: 12),
                _buildSummaryCard("Total Allowances", totalAllowances, Icons.add_circle, successColor),
                const SizedBox(width: 12),
                _buildSummaryCard("Total Deductions", totalDeductions, Icons.remove_circle, errorColor),
                const SizedBox(width: 12),
                _buildSummaryCard("Total Net Pay", totalNet, Icons.account_balance_wallet, accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "₹${amount.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
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
                  color: textSecondary,
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
              Icon(Icons.receipt_long, size: 64, color: textSecondary.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                "No Payroll Data",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Payroll data will appear here after generation",
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text("Back to Payroll Processing"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: surfaceColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          // Actions Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.list_alt, color: primaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  "PAYROLL DETAILS",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isGeneratingAll ? null : _generateAllPayslips,
                  icon: _isGeneratingAll
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(surfaceColor),
                    ),
                  )
                      : const Icon(Icons.picture_as_pdf, size: 18),
                  label: Text(_isGeneratingAll ? "GENERATING..." : "GENERATE ALL PAYSLIPS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: surfaceColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Payroll List
          Expanded(
            child: ListView.builder(
              itemCount: _payrollData.length,
              itemBuilder: (context, index) {
                final payroll = _payrollData[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildPayrollItem(payroll),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollItem(Map<String, dynamic> payroll) {
    final basicSalary = payroll['basic_salary'] ?? 0;
    final allowances = payroll['allowances'] ?? 0;
    final deductions = payroll['deductions'] ?? 0;
    final netSalary = payroll['net_salary'] ?? 0;

    return Card(
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Employee Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  payroll['employee_name'][0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Employee Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payroll['employee_name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payroll['designation'],
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSalaryChip("Basic", basicSalary, primaryColor),
                      const SizedBox(width: 8),
                      _buildSalaryChip("Allowances", allowances, successColor),
                      const SizedBox(width: 8),
                      _buildSalaryChip("Deductions", deductions, errorColor),
                    ],
                  ),
                ],
              ),
            ),

            // Net Salary and Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "₹${netSalary.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _generatePayslip(payroll['id'], payroll['employee_name']),
                      icon: const Icon(Icons.receipt, size: 16),
                      label: const Text("Payslip"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryChip(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchPayrollData,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 16),
            _buildPayrollList(),
          ],
        ),
      ),
    );
  }
}

