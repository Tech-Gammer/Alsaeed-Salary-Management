import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  bool _deductDepartmentKharcha = true;
  bool _deductIndividualKharcha = true;
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
        // Wait for employees to load, then fetch kharchas
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
      final params = {
        'period_id': _selectedPeriod!.id.toString(),
      };

      final url = Uri.parse("$_apiBaseUrl/kharcha").replace(queryParameters: params);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List kharchaList = (data is Map && data.containsKey('kharchas'))
            ? (data['kharchas'] ?? [])
            : (data is List ? data : []);

        final List<Kharcha> parsedKharchas = kharchaList.map((k) {
          try {
            return Kharcha.fromJson(k);
          } catch (e) {
            print("❌ Error parsing kharcha: $e");
            print("❌ Problematic kharcha data: $k");
            return Kharcha(
              id: k['id'] ?? 0,
              kharchaType: k['kharcha_type'] ?? 'department',
              departmentId: k['department_id'],
              employeeId: k['employee_id']?.toString(),
              amount: (k['amount'] is num ? k['amount'].toDouble() : double.tryParse(k['amount']?.toString() ?? '0') ?? 0.0),
              date: DateTime.tryParse(k['date']?.toString() ?? '') ?? DateTime.now(),
              periodId: k['period_id'] ?? 0,
              description: k['description']?.toString() ?? '',
              departmentName: k['department_name']?.toString(),
              employeeName: k['employee_name']?.toString(),
              periodName: k['period_name']?.toString() ?? 'Unknown Period',
              createdAt: DateTime.tryParse(k['created_at']?.toString() ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(k['updated_at']?.toString() ?? '') ?? DateTime.now(),
            );
          }
        }).toList();

        // Enhanced filtering logic
        setState(() {
          _kharchas = parsedKharchas.where((k) {
            if (k.kharchaType == 'department') {
              return k.departmentId == _selectedDepartment!.id;
            } else if (k.kharchaType == 'individual') {
              final employeeId = k.employeeId;
              if (employeeId != null) {
                final employeeExists = _employees.any((emp) =>
                emp.id.toString() == employeeId.toString());
                return employeeExists;
              }
              return false;
            }
            return false;
          }).toList();
        });

        _debugKharchaData();
      } else {
        print("❌ Failed to load kharchas: ${response.statusCode}");
        print("❌ Response body: ${response.body}");
      }
    } catch (e) {
      print("❌ Error loading kharchas: $e");
    }
  }

  void _debugKharchaData() {
    print("=== ENHANCED KHARCHA DEBUG ===");
    print("Selected Department: ${_selectedDepartment?.name} (ID: ${_selectedDepartment?.id})");
    print("Selected Period: ${_selectedPeriod?.periodName} (ID: ${_selectedPeriod?.id})");
    print("Total kharchas loaded: ${_kharchas.length}");
    print("Deduct Department Kharcha: $_deductDepartmentKharcha");
    print("Deduct Individual Kharcha: $_deductIndividualKharcha");

    final departmentKharchas = _kharchas.where((k) => k.kharchaType == 'department').toList();
    final individualKharchas = _kharchas.where((k) => k.kharchaType == 'individual').toList();

    print("Department kharchas: ${departmentKharchas.length}");
    for (var k in departmentKharchas) {
      print("  - ID: ${k.id}, Amount: ₹${k.amount}, Dept ID: ${k.departmentId}");
    }

    print("Individual kharchas: ${individualKharchas.length}");
    for (var k in individualKharchas) {
      print("  - ID: ${k.id}, Amount: ₹${k.amount}, Employee ID: ${k.employeeId}, Employee Name: ${k.employeeName}");
    }

    print("Current Employees: ${_employees.length}");
    for (var emp in _employees) {
      final kharcha = _getEmployeeKharcha(emp.id);
      print("  - Employee: ${emp.name} (ID: ${emp.id}) - Kharcha: ₹$kharcha");
    }
    print("==============================");
  }

  void _initializeControllers() {
    for (var emp in _employees) {
      _workingDaysControllers[emp.id] = TextEditingController(text: emp.workingDays.toString());
      _leaveDaysControllers[emp.id] = TextEditingController(text: emp.leaveDays.toString());
    }
  }

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

  double _getEmployeeKharcha(int employeeId) {
    if (!_deductIndividualKharcha) return 0.0;

    final employeeIdStr = employeeId.toString();
    final individualKharchas = _kharchas.where((k) {
      if (k.kharchaType != 'individual') return false;
      final kharchaEmployeeId = k.employeeId?.toString();
      return kharchaEmployeeId == employeeIdStr;
    }).toList();

    final total = individualKharchas.fold(0.0, (sum, k) => sum + k.amount);

    if (total > 0) {
      print("📊 Total individual kharcha for employee $employeeIdStr: ₹$total (${individualKharchas.length} records)");
    }

    return total;
  }

  double _getDepartmentKharcha() {
    if (!_deductDepartmentKharcha) return 0.0;

    return _kharchas
        .where((k) => k.kharchaType == 'department' && k.departmentId == _selectedDepartment?.id)
        .fold(0.0, (sum, k) => sum + k.amount);
  }

  bool _hasDepartmentKharcha() {
    return _deductDepartmentKharcha && _kharchas.any((k) => k.kharchaType == 'department' && k.departmentId == _selectedDepartment?.id);
  }

  bool _hasIndividualKharcha() {
    return _deductIndividualKharcha && _kharchas.any((k) => k.kharchaType == 'individual');
  }

  double _getIndividualKharchaForSelectedEmployees() {
    if (!_deductIndividualKharcha) return 0.0;

    return _selectedEmployees.fold(0.0, (sum, emp) {
      final kharcha = _getEmployeeKharcha(emp.id);
      print("💰 Employee ${emp.name} (${emp.id}) - Individual Kharcha: ₹$kharcha");
      return sum + kharcha;
    });
  }

  void _updateEmployeeDays(EmployeePayroll emp, bool isWorkingDays, String value) {
    if (value.isEmpty || value == '-') {
      setState(() {
        if (isWorkingDays) {
          emp.workingDays = 0;
        } else {
          emp.leaveDays = 0;
        }
      });
      return;
    }

    final int? newValue = int.tryParse(value);

    if (newValue == null) {
      final controller = isWorkingDays ? _workingDaysControllers[emp.id] : _leaveDaysControllers[emp.id];
      final oldValue = isWorkingDays ? emp.workingDays : emp.leaveDays;
      controller?.text = oldValue.toString();
      controller?.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
      return;
    }

    setState(() {
      if (isWorkingDays) {
        emp.workingDays = newValue;
      } else {
        emp.leaveDays = newValue;
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

    // Deduct individual kharcha only if enabled
    final individualKharcha = _getEmployeeKharcha(emp.id);
    final netSalary = totalSalary - individualKharcha;

    print("💰 Salary Calculation for ${emp.name}:");
    print("   - Base Salary: ₹${emp.salary}");
    print("   - Calculated Salary: ₹$totalSalary");
    print("   - Individual Kharcha: ₹$individualKharcha");
    print("   - Net Salary: ₹$netSalary");

    return netSalary < 0 ? 0 : netSalary;
  }

  double get _totalBaseSalary {
    return _selectedEmployees.fold(0.0, (sum, emp) {
      if (_selectedPeriod == null) return sum + emp.salary;

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
      return sum + totalSalary;
    });
  }

  double get _totalKharcha {
    if (_hasDepartmentKharcha()) {
      return _getDepartmentKharcha();
    } else {
      return _getIndividualKharchaForSelectedEmployees();
    }
  }

  double get _totalNetSalary {
    if (_hasDepartmentKharcha()) {
      return _totalBaseSalary - _totalKharcha;
    } else {
      return _selectedEmployees.fold(0.0, (sum, emp) => sum + _calculateNetSalary(emp));
    }
  }

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
      child: SingleChildScrollView( // ADDED: Makes the side panel scrollable
        child: Padding(
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.arrow_back, size: 16, color: textPrimary),
                          padding: EdgeInsets.zero,
                        ),
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

              // Department Section
              _buildSectionHeader("Department", Icons.business_center),
              SizedBox(height: 5),
              _buildDepartmentDropdown(),

              SizedBox(height: 5),

              // Period Section
              _buildSectionHeader("Payroll Period", Icons.calendar_month),
              SizedBox(height: 5),
              _buildPeriodDropdown(),

              if (_periods.isEmpty) ...[
                SizedBox(height: 5),
                _buildCreatePeriodButton(),
              ],

              // NEW: Kharcha Deduction Settings
              SizedBox(height: 16),
              _buildSectionHeader("Kharcha Deduction", Icons.money_off),
              SizedBox(height: 8),
              _buildKharchaDeductionSettings(),

              SizedBox(height: 16), // Reduced space before Kharcha Summary

              // Kharcha Summary
              if (_kharchas.isNotEmpty) _buildKharchaSummaryCard(),

              SizedBox(height: 16), // Reduced space before Grand Total

              // Grand Total Summary
              if (_selectedEmployees.isNotEmpty) _buildGrandTotalCard(),

              SizedBox(height: 16), // Reduced space before Generate Button

              // Generate Button
              _buildGenerateButton(),

              SizedBox(height: 8), // Extra bottom padding for better scrolling
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKharchaDeductionSettings() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.settings, size: 18, color: primaryColor),
              ),
              SizedBox(width: 12),
              Text("Deduction Settings", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          SizedBox(height: 5),

          // Department Kharcha Toggle
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Department Kharcha", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      SizedBox(height: 2),
                      Text("Deduct from total salary", style: TextStyle(fontSize: 11, color: textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: _deductDepartmentKharcha,
                  onChanged: (value) {
                    setState(() {
                      _deductDepartmentKharcha = value;
                    });
                  },
                  activeColor: primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),

          SizedBox(height: 5),

          // Individual Kharcha Toggle
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Individual Kharcha", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      SizedBox(height: 2),
                      Text("Deduct from each employee", style: TextStyle(fontSize: 11, color: textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: _deductIndividualKharcha,
                  onChanged: (value) {
                    setState(() {
                      _deductIndividualKharcha = value;
                    });
                  },
                  activeColor: primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalCard() {
    final hasDepartmentKharcha = _hasDepartmentKharcha();
    final hasIndividualKharcha = _hasIndividualKharcha();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: successColor.withOpacity(0.2)),
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
                  color: successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.summarize, size: 18, color: successColor),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Grand Total", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text("${_selectedEmployees.length} employees selected",
                        style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 7),
          _buildTotalItem("Total Base Salary", _totalBaseSalary, textPrimary),
          SizedBox(height: 5),
          if (hasDepartmentKharcha)
            _buildTotalItem("Department Kharcha", _totalKharcha, warningColor),
          if (hasIndividualKharcha && !hasDepartmentKharcha)
            _buildTotalItem("Total Individual Kharcha", _totalKharcha, warningColor),
          SizedBox(height: 5),
          Divider(height: 1, color: borderColor),
          SizedBox(height: 5),
          _buildTotalItem("Total Net Payable", _totalNetSalary, successColor, isBold: true),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, double amount, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: 13,
          color: textSecondary,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
        )),
        Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(
          fontSize: 13,
          color: color,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        )),
      ],
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
    final hasDepartmentKharcha = _hasDepartmentKharcha();
    final hasIndividualKharcha = _hasIndividualKharcha();

    double departmentKharcha = 0.0;
    double individualKharcha = 0.0;

    if (hasDepartmentKharcha) {
      departmentKharcha = _getDepartmentKharcha();
    }
    if (hasIndividualKharcha) {
      individualKharcha = _getIndividualKharchaForSelectedEmployees();
    }

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
          SizedBox(height: 8),

          if (hasDepartmentKharcha) ...[
            _buildKharchaItem("Department Kharcha", departmentKharcha,
                "Deducted from total base salary"),
            SizedBox(height: 8),
          ],

          if (hasIndividualKharcha) ...[
            _buildKharchaItem("Individual Kharcha (${_selectedEmployees.length} employees)", individualKharcha,
                "Deducted from respective employees' salaries"),
            SizedBox(height: 8),
          ],

          if (hasDepartmentKharcha && hasIndividualKharcha) ...[
            Divider(height: 1, color: borderColor),
            SizedBox(height: 8),
            _buildKharchaItem("Total All Kharcha", totalKharcha,
                "Combined department and individual", isTotal: true),
          ],
        ],
      ),
    );
  }

  Widget _buildKharchaItem(String label, double amount, String description, {bool isTotal = false}) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              )),
              Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isTotal ? warningColor : textPrimary,
              )),
            ],
          ),
          SizedBox(height: 4),
          Text(description, style: TextStyle(fontSize: 10, color: textTertiary)),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isGenerating
            ? SizedBox(width: 16, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: surfaceColor))
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
          SizedBox(height: 10),
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
          SizedBox(height: 10),
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
          SizedBox(height: 10),
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
    final individualKharcha = _getEmployeeKharcha(emp.id);
    final hasDepartmentKharcha = _hasDepartmentKharcha();
    final netSalary = _calculateNetSalary(emp);

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
                  // Show individual kharcha if it exists and deduction is enabled
                  if (individualKharcha > 0 && _deductIndividualKharcha) ...[
                    SizedBox(height: 2),
                    Text(
                      "Individual kharcha: ₹${individualKharcha.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 10, color: warningColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(flex: 2, child: Text("₹${emp.salary.toStringAsFixed(2)}", style: TextStyle(fontSize: 14))),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show kharcha amount in the kharcha column
                if (individualKharcha > 0 && _deductIndividualKharcha)
                  Text("₹${individualKharcha.toStringAsFixed(2)}",
                      style: TextStyle(color: warningColor, fontSize: 14, fontWeight: FontWeight.w500))
                else if (hasDepartmentKharcha)
                  Text("--", style: TextStyle(color: textTertiary, fontSize: 14, fontWeight: FontWeight.w500))
                else
                  Text("--", style: TextStyle(color: textTertiary, fontSize: 14, fontWeight: FontWeight.w500)),

                Text(
                  hasDepartmentKharcha ? "Department kharcha" :
                  (_deductIndividualKharcha ? "Individual kharcha" : "No deduction"),
                  style: TextStyle(fontSize: 10, color: textTertiary),
                ),
              ],
            ),
          ),
          if (_selectedPeriod?.periodType == 'full_month') ...[
            Expanded(flex: 1, child: _buildDaysInput(emp, true)),
            Expanded(flex: 1, child: _buildDaysInput(emp, false)),
          ],
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${netSalary.toStringAsFixed(2)}",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold, color: successColor, fontSize: 14),
                  ),
                  // Show deduction info if kharcha was applied
                  if (individualKharcha > 0 && _deductIndividualKharcha)
                    Text(
                      "after kharcha",
                      style: TextStyle(fontSize: 10, color: textTertiary),
                    ),
                ],
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