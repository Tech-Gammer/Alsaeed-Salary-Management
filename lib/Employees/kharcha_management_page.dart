import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/EmployeeModel.dart';
import '../models/kharchamodel.dart';
import '../models/modelpayroll.dart';
import 'KharchaListPage.dart';

class KharchaManagementPage extends StatefulWidget {
  const KharchaManagementPage({super.key});

  @override
  State<KharchaManagementPage> createState() => _KharchaManagementPageState();
}

class _KharchaManagementPageState extends State<KharchaManagementPage> {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF10B981);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1E293B);

  List<Department> _departments = [];
  List<Employee> _employees = [];
  List<PayrollPeriod> _periods = [];
  Department? _selectedDepartment;
  Employee? _selectedEmployee;
  PayrollPeriod? _selectedPeriod;
  String _selectedKharchaType = 'department';

  bool _isLoading = false;
  bool _isSubmitting = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _employeeSearchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Employee search variables
  List<Employee> _filteredEmployees = [];
  bool _showEmployeeSuggestions = false;
  final FocusNode _employeeSearchFocusNode = FocusNode();
  final LayerLink _employeeSearchLayerLink = LayerLink();
  OverlayEntry? _employeeOverlayEntry;

  static const String _apiBaseUrl = "http://localhost:3000/api";

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchEmployees();
    _fetchPeriods();

    _employeeSearchController.addListener(_filterEmployees);
    _employeeSearchFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _employeeSearchController.removeListener(_filterEmployees);
    _employeeSearchFocusNode.removeListener(_handleFocusChange);
    _amountController.dispose();
    _descriptionController.dispose();
    _employeeSearchController.dispose();
    _employeeSearchFocusNode.dispose();
    _hideEmployeeSuggestionsOverlay();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_employeeSearchFocusNode.hasFocus) {
      _showEmployeeSuggestionsOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _hideEmployeeSuggestionsOverlay();
        }
      });
    }
  }

  void _filterEmployees() {
    final query = _employeeSearchController.text.toLowerCase().trim();
    setState(() {
      _filteredEmployees = _employees.where((employee) {
        return employee.name.toLowerCase().contains(query) ||
            employee.position.toLowerCase().contains(query);
      }).toList();
    });

    if (_employeeSearchFocusNode.hasFocus) {
      _showEmployeeSuggestionsOverlay();
    }
  }

  void _selectEmployee(Employee employee) {
    setState(() {
      _selectedEmployee = employee;
      _employeeSearchController.text = employee.name;
    });
    _hideEmployeeSuggestionsOverlay();
    FocusScope.of(context).unfocus();
  }

  void _clearEmployeeSelection() {
    setState(() {
      _selectedEmployee = null;
      _employeeSearchController.clear();
      _filteredEmployees = _employees;
    });
    _employeeSearchFocusNode.requestFocus();
  }

  void _showEmployeeSuggestionsOverlay() {
    _hideEmployeeSuggestionsOverlay();

    if (_filteredEmployees.isEmpty) return;

    final overlay = Overlay.of(context);
    _employeeOverlayEntry = OverlayEntry(
      builder: (context) {
        return CompositedTransformFollower(
          link: _employeeSearchLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, 55.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredEmployees.length,
                itemBuilder: (context, index) {
                  final employee = _filteredEmployees[index];
                  final isSelected = _selectedEmployee?.id == employee.id;
                  return ListTile(
                    title: Text(
                      employee.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      employee.position,
                      style: const TextStyle(fontSize: 12),
                    ),
                    tileColor: isSelected ? primaryColor.withOpacity(0.1) : null,
                    onTap: () => _selectEmployee(employee),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_employeeOverlayEntry!);
    setState(() {
      _showEmployeeSuggestions = true;
    });
  }

  void _hideEmployeeSuggestionsOverlay() {
    if (_employeeOverlayEntry != null) {
      _employeeOverlayEntry!.remove();
      _employeeOverlayEntry = null;
      setState(() {
        _showEmployeeSuggestions = false;
      });
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/departments"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _departments = data.map((dept) {
              return Department.fromJson(dept);
            }).toList();
          });
        }
      }
    } catch (e) {
      print("❌ Error fetching departments: $e");
    }
  }

  Future<void> _fetchEmployees() async {
    try {
      setState(() { _isLoading = true; });

      final response = await http.get(Uri.parse("$_apiBaseUrl/employees?active=1"));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _employees = data.map((emp) => Employee.fromJson(emp)).toList();
            _filteredEmployees = _employees;
          });
        }
      } else {
        _showError("Failed to fetch employees: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching employees: $e");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _fetchPeriods() async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/payroll/periods"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _periods = data.map((period) => PayrollPeriod.fromJson(period)).toList();
            if (_periods.isNotEmpty) {
              _selectedPeriod = _periods.firstWhere(
                    (period) => period.periodType == 'full_month' && _isCurrentMonth(period),
                orElse: () => _periods.first,
              );
            }
          });
        }
      }
    } catch (e) {
      _showError("Error fetching periods: $e");
    }
  }

  bool _isCurrentMonth(PayrollPeriod period) {
    final now = DateTime.now();
    final periodStart = DateTime.parse(period.startDate);
    return periodStart.year == now.year && periodStart.month == now.month;
  }

  Future<void> _addKharcha() async {
    if (_selectedKharchaType == 'department' && _selectedDepartment == null) {
      _showError("Please select a department");
      return;
    }

    if (_selectedKharchaType == 'individual' && _selectedEmployee == null) {
      _showError("Please select an employee");
      return;
    }

    if (_selectedPeriod == null) {
      _showError("Please select a period");
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError("Please enter a valid amount");
      return;
    }

    if (!mounted) return;
    setState(() { _isSubmitting = true; });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final kharchaData = {
        "kharcha_type": _selectedKharchaType,
        "department_id": _selectedKharchaType == 'department' ? _selectedDepartment!.id : null,
        "employee_id": _selectedKharchaType == 'individual' ? _selectedEmployee!.id : null,
        "amount": amount,
        "date": formattedDate,
        "period_id": _selectedPeriod!.id,
        "description": _descriptionController.text,
      };

      final response = await http.post(
        Uri.parse("$_apiBaseUrl/kharcha"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(kharchaData),
      );

      if (response.statusCode == 201) {
        _showSuccess("Kharcha added successfully!");
        _resetForm();
      } else {
        final errorData = jsonDecode(response.body);
        _showError("Failed to add kharcha: ${errorData['error']}");
      }
    } catch (e) {
      _showError("Error adding kharcha: $e");
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  void _resetForm() {
    _amountController.clear();
    _descriptionController.clear();
    _employeeSearchController.clear();
    _selectedDate = DateTime.now();
    _selectedEmployee = null;
    _selectedDepartment = null;
    setState(() {
      _filteredEmployees = _employees;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDisplayDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Add Kharcha',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KharchaListPage()),
              );
            },
            tooltip: 'View All Kharchas',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Add New Expense',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Record department or individual expenses',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Form Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Kharcha Type Selection
                    _buildKharchaTypeSection(),
                    const SizedBox(height: 20),

                    // Dynamic Fields based on Type
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _selectedKharchaType == 'department'
                          ? _buildDepartmentSection()
                          : _buildEmployeeSection(),
                    ),
                    const SizedBox(height: 20),

                    // Period Selection
                    _buildPeriodSection(),
                    const SizedBox(height: 20),

                    // Amount and Date
                    Row(
                      children: [
                        Expanded(child: _buildAmountField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDateField()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _buildDescriptionField(),
                    const SizedBox(height: 24),

                    // Submit Button
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKharchaTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense Type *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedKharchaType,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              items: const [
                DropdownMenuItem(
                  value: 'department',
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.business, color: Color(0xFF2563EB)),
                        SizedBox(width: 12),
                        Text('Department Expense'),
                      ],
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'individual',
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Color(0xFF10B981)),
                        SizedBox(width: 12),
                        Text('Individual Expense'),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (type) {
                if (type == null) return;
                setState(() {
                  _selectedKharchaType = type;
                  if (type == 'department') {
                    _clearEmployeeSelection();
                  } else {
                    _selectedDepartment = null;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Department *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
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
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Select Department'),
              ),
              items: _departments.map((dept) {
                return DropdownMenuItem(
                  value: dept,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(dept.name),
                  ),
                );
              }).toList(),
              onChanged: (dept) {
                setState(() {
                  _selectedDepartment = dept;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Employee *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        CompositedTransformTarget(
          link: _employeeSearchLayerLink,
          child: TextField(
            controller: _employeeSearchController,
            focusNode: _employeeSearchFocusNode,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: 'Search employees...',
              suffixIcon: _selectedEmployee != null
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: _clearEmployeeSelection,
              )
                  : const Icon(Icons.search, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payroll Period *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PayrollPeriod>(
              value: _selectedPeriod,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Select Period'),
              ),
              items: _periods.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(period.periodName),
                        Text(
                          '${DateFormat('dd MMM yyyy').format(DateTime.parse(period.startDate))} - ${DateFormat('dd MMM yyyy').format(DateTime.parse(period.endDate))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
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

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: '0.00',
            prefixText: '₹ ',
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Text(_formatDisplayDate(_selectedDate)),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor),
            ),
            contentPadding: const EdgeInsets.all(16),
            hintText: 'Enter expense description...',
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _addKharcha,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20),
            SizedBox(width: 8),
            Text(
              'Add Expense',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}