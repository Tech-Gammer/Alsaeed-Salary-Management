import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/EmployeeModel.dart';
import '../models/kharchamodel.dart';
import '../models/modelpayroll.dart';
import 'create_payroll_period_page.dart';

class KharchaManagementPage extends StatefulWidget {
  const KharchaManagementPage({super.key});

  @override
  State<KharchaManagementPage> createState() => _KharchaManagementPageState();
}

class _KharchaManagementPageState extends State<KharchaManagementPage> {
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color secondaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF2D3748);

  List<Department> _departments = [];
  List<Employee> _employees = [];
  List<PayrollPeriod> _periods = [];
  List<Kharcha> _kharchas = [];
  Department? _selectedDepartment;
  Employee? _selectedEmployee;
  PayrollPeriod? _selectedPeriod;
  String _selectedKharchaType = 'department';
  String _selectedFilterType = 'department'; // New: Filter type
  bool _isLoading = false;
  bool _isSubmitting = false;
  OverlayEntry? _employeeOverlayEntry;
  OverlayEntry? _filterEmployeeOverlayEntry; // New: For filter employee search

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _employeeSearchController = TextEditingController();
  final TextEditingController _filterEmployeeSearchController = TextEditingController(); // New: For filter employee search
  DateTime _selectedDate = DateTime.now();

  // Employee search variables for form
  List<Employee> _filteredEmployees = [];
  bool _showEmployeeSuggestions = false;
  final FocusNode _employeeSearchFocusNode = FocusNode();
  final LayerLink _employeeSearchLayerLink = LayerLink();

  // Employee search variables for filter
  List<Employee> _filteredFilterEmployees = [];
  bool _showFilterEmployeeSuggestions = false;
  final FocusNode _filterEmployeeSearchFocusNode = FocusNode();
  final LayerLink _filterEmployeeSearchLayerLink = LayerLink();

  static const String _apiBaseUrl = "http://localhost:3000/api";

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchEmployees();
    _fetchPeriods();
    _fetchKharchas();

    _employeeSearchController.addListener(_filterEmployees);
    _employeeSearchFocusNode.addListener(_handleFocusChange);

    _filterEmployeeSearchController.addListener(_filterFilterEmployees);
    _filterEmployeeSearchFocusNode.addListener(_handleFilterFocusChange);
  }

  @override
  void dispose() {
    _employeeSearchController.removeListener(_filterEmployees);
    _employeeSearchFocusNode.removeListener(_handleFocusChange);
    _filterEmployeeSearchController.removeListener(_filterFilterEmployees);
    _filterEmployeeSearchFocusNode.removeListener(_handleFilterFocusChange);

    _amountController.dispose();
    _descriptionController.dispose();
    _employeeSearchController.dispose();
    _employeeSearchFocusNode.dispose();
    _filterEmployeeSearchController.dispose();
    _filterEmployeeSearchFocusNode.dispose();

    _hideEmployeeSuggestionsOverlay();
    _hideFilterEmployeeSuggestionsOverlay();
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

  void _handleFilterFocusChange() {
    if (_filterEmployeeSearchFocusNode.hasFocus) {
      _showFilterEmployeeSuggestionsOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _hideFilterEmployeeSuggestionsOverlay();
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

  void _filterFilterEmployees() {
    final query = _filterEmployeeSearchController.text.toLowerCase().trim();
    setState(() {
      _filteredFilterEmployees = _employees.where((employee) {
        return employee.name.toLowerCase().contains(query) ||
            employee.position.toLowerCase().contains(query);
      }).toList();
    });

    if (_filterEmployeeSearchFocusNode.hasFocus) {
      _showFilterEmployeeSuggestionsOverlay();
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

  void _selectFilterEmployee(Employee employee) {
    setState(() {
      _selectedEmployee = employee;
      _filterEmployeeSearchController.text = employee.name;
    });
    _hideFilterEmployeeSuggestionsOverlay();
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

  void _clearFilterEmployeeSelection() {
    setState(() {
      _selectedEmployee = null;
      _filterEmployeeSearchController.clear();
      _filteredFilterEmployees = _employees;
    });
    _filterEmployeeSearchFocusNode.requestFocus();
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
            child: SizedBox(
              height: _filteredEmployees.length * 60.0 > 240.0 ? 240.0 : null,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredEmployees.length,
                itemBuilder: (context, index) {
                  final employee = _filteredEmployees[index];
                  final isSelected = _selectedEmployee?.id == employee.id;
                  return ListTile(
                    title: Text(employee.name),
                    subtitle: Text(employee.position),
                    tileColor: isSelected ? secondaryColor.withOpacity(0.1) : null,
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

  void _showFilterEmployeeSuggestionsOverlay() {
    _hideFilterEmployeeSuggestionsOverlay();

    if (_filteredFilterEmployees.isEmpty) return;

    final overlay = Overlay.of(context);
    _filterEmployeeOverlayEntry = OverlayEntry(
      builder: (context) {
        return CompositedTransformFollower(
          link: _filterEmployeeSearchLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, 55.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: _filteredFilterEmployees.length * 60.0 > 240.0 ? 240.0 : null,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredFilterEmployees.length,
                itemBuilder: (context, index) {
                  final employee = _filteredFilterEmployees[index];
                  final isSelected = _selectedEmployee?.id == employee.id;
                  return ListTile(
                    title: Text(employee.name),
                    subtitle: Text(employee.position),
                    tileColor: isSelected ? secondaryColor.withOpacity(0.1) : null,
                    onTap: () => _selectFilterEmployee(employee),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_filterEmployeeOverlayEntry!);
    setState(() {
      _showFilterEmployeeSuggestions = true;
    });
  }

  void _hideFilterEmployeeSuggestionsOverlay() {
    if (_filterEmployeeOverlayEntry != null) {
      _filterEmployeeOverlayEntry!.remove();
      _filterEmployeeOverlayEntry = null;
      setState(() {
        _showFilterEmployeeSuggestions = false;
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
            _departments = data.map((dept) => Department.fromJson(dept)).toList();
          });
        }
      }
    } catch (e) {
      _showError("Error fetching departments: $e");
    }
  }

  Future<void> _fetchEmployees() async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/employees"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _employees = data.map((emp) => Employee.fromJson(emp)).toList();
            _filteredEmployees = _employees;
            _filteredFilterEmployees = _employees;
          });
        }
      } else {
        _showError("Failed to fetch employees: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching employees: $e");
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

  Future<void> _fetchKharchas() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    try {
      String url = "$_apiBaseUrl/kharcha";
      final Map<String, String> params = {};

      // Add filter parameters based on selected filter type
      if (_selectedFilterType == 'department' && _selectedDepartment != null) {
        params['department_id'] = _selectedDepartment!.id.toString();
      } else if (_selectedFilterType == 'individual' && _selectedEmployee != null) {
        params['employee_id'] = _selectedEmployee!.id.toString();
      }

      if (_selectedPeriod != null) {
        params['period_id'] = _selectedPeriod!.id.toString();
      }

      if (params.isNotEmpty) {
        url += "?${Uri(queryParameters: params).query}";
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List kharchaList = (data is Map && data.containsKey('kharchas')) ? (data['kharchas'] ?? []) : (data is List ? data : []);

        final List<Kharcha> parsedKharchas = kharchaList.map((k) {
          try {
            return Kharcha.fromJson(k);
          } catch (e) {
            print("❌ Error parsing kharcha: $e");
            return null;
          }
        }).whereType<Kharcha>().toList();

        if (mounted) {
          setState(() {
            _kharchas = parsedKharchas;
          });
        }
      } else {
        _showError("Failed to load kharchas: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error loading kharchas: $e");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
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
        _showSuccess("Kharcha added successfully");
        _resetForm();
        _fetchKharchas();
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

  Future<void> _deleteKharcha(int kharchaId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this kharcha record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(Uri.parse("$_apiBaseUrl/kharcha/$kharchaId"));

      if (response.statusCode == 200) {
        _showSuccess("Kharcha deleted successfully");
        _fetchKharchas();
      } else {
        _showError("Failed to delete kharcha");
      }
    } catch (e) {
      _showError("Error deleting kharcha: $e");
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

  void _resetFilters() {
    setState(() {
      _selectedDepartment = null;
      _selectedEmployee = null;
      _selectedFilterType = 'department';
      _filterEmployeeSearchController.clear();
      _filteredFilterEmployees = _employees;
    });
    _fetchKharchas();
  }

  void _showError(String message) {
    if (!mounted) return;
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
    if (!mounted) return;
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

  String _formatDisplayDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Kharcha Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
            _buildAddKharchaCard(),
            const SizedBox(height: 20),
            _buildKharchasList(),
          ],
        ),
      ),
    );
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
                const Icon(Icons.filter_list, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "FILTER KHARCHAS",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                _buildClearFiltersButton(),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFilterTypeDropdown(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedFilterType == 'department'
                        ? _buildDepartmentDropdown()
                        : _buildEmployeeFilterField(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPeriodDropdown(),
                ),
                const SizedBox(width: 16),
                _buildAddPeriodButton(),
                const SizedBox(width: 8),
                _buildRefreshButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Filter By",
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
            child: DropdownButton<String>(
              value: _selectedFilterType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'department',
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.business, size: 18, color: primaryColor),
                        SizedBox(width: 8),
                        Text("Department"),
                      ],
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'individual',
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18, color: secondaryColor),
                        SizedBox(width: 8),
                        Text("Individual"),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (type) {
                if (type == null) return;
                setState(() {
                  _selectedFilterType = type;
                  // Clear the other filter type when switching
                  if (type == 'department') {
                    _selectedEmployee = null;
                    _filterEmployeeSearchController.clear();
                  } else {
                    _selectedDepartment = null;
                  }
                });
                _fetchKharchas();
              },
            ),
          ),
        ),
      ],
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
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text("All Departments"),
              ),
              icon: const Icon(Icons.keyboard_arrow_down, color: primaryColor),
              items: [
                const DropdownMenuItem<Department>(
                  value: null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("All Departments"),
                  ),
                ),
                ..._departments.map((dept) {
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
                }),
              ],
              onChanged: (dept) {
                setState(() {
                  _selectedDepartment = dept;
                });
                _fetchKharchas();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeFilterField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Employee",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _filterEmployeeSearchLayerLink,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _showFilterEmployeeSuggestions ? primaryColor : Colors.grey.shade300),
            ),
            child: TextField(
              controller: _filterEmployeeSearchController,
              focusNode: _filterEmployeeSearchFocusNode,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                hintText: _selectedEmployee == null ? "Search employees..." : _selectedEmployee!.name,
                suffixIcon: _selectedEmployee != null
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: _clearFilterEmployeeSelection,
                )
                    : const Icon(Icons.search, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClearFiltersButton() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton.icon(
        onPressed: _resetFilters,
        icon: const Icon(Icons.clear_all, size: 16),
        label: const Text("Clear Filters"),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey.shade700,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
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
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text("Select Period"),
              ),
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
                _fetchKharchas();
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
        const SizedBox(height: 22),
        Container(
          height: 48,
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

  Widget _buildRefreshButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(height: 22),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: _fetchKharchas,
            tooltip: "Refresh Data",
          ),
        ),
      ],
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


  Widget _buildAddKharchaCard() {
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
                const Icon(Icons.add_circle, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "ADD NEW KHARCHA",
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildKharchaTypeDropdown(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedKharchaType == 'department'
                        ? _buildDepartmentFormDropdown()
                        : _buildEmployeeSearchField(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPeriodFormDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _buildAmountField(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildDescriptionField(),
                ),
                const SizedBox(width: 16),
                _buildSubmitButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKharchaTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Kharcha Type *",
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
            child: DropdownButton<String>(
              value: _selectedKharchaType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'department',
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.business, size: 18, color: primaryColor),
                        SizedBox(width: 8),
                        Text("Department"),
                      ],
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'individual',
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18, color: secondaryColor),
                        SizedBox(width: 8),
                        Text("Individual"),
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

  Widget _buildEmployeeSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Employee *",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.8)),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _employeeSearchLayerLink,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _showEmployeeSuggestions ? primaryColor : Colors.grey.shade300),
            ),
            child: TextField(
              controller: _employeeSearchController,
              focusNode: _employeeSearchFocusNode,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                hintText: _selectedEmployee == null ? "Search employees..." : _selectedEmployee!.name,
                suffixIcon: _selectedEmployee != null
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: _clearEmployeeSelection,
                )
                    : const Icon(Icons.search, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentFormDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Department *",
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
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text("Select Department"),
              ),
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
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodFormDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Period *",
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
            child: DropdownButton<PayrollPeriod>(
              value: _selectedPeriod,
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text("Select Period"),
              ),
              icon: const Icon(Icons.keyboard_arrow_down, color: primaryColor),
              items: _periods.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      period.periodName,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
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
          "Amount *",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.8)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              hintText: "0.00",
              prefixText: "₹ ",
            ),
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
          "Date *",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.8)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ListTile(
            title: Text(_formatDisplayDate(_selectedDate)),
            trailing: const Icon(Icons.calendar_today, size: 20),
            onTap: () => _selectDate(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
          "Description",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.8)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              hintText: "Enter description...",
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _addKharcha,
        icon: _isSubmitting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
            : const Icon(Icons.add, size: 18),
        label: Text(_isSubmitting ? "Adding..." : "Add Kharcha"),
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildKharchasList() {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (_kharchas.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "No Kharchas Found",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      );
    }

    final totalAmount = _kharchas.fold(0.0, (sum, kharcha) => sum + kharcha.amount);

    return Expanded(
      child: Column(
        children: [
          Card(
            color: primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Kharcha",
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          "₹${totalAmount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "${_kharchas.length} records",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _kharchas.length,
              itemBuilder: (context, index) {
                return _buildKharchaListItem(_kharchas[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKharchaListItem(Kharcha kharcha) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kharcha.kharchaType == 'individual' ? secondaryColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
          child: Icon(
            kharcha.kharchaType == 'individual' ? Icons.person : Icons.business,
            color: kharcha.kharchaType == 'individual' ? secondaryColor : primaryColor,
          ),
        ),
        title: Text(kharcha.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(kharcha.description.isEmpty ? "No description" : kharcha.description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("₹${kharcha.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: secondaryColor)),
            const SizedBox(height: 4),
            Text(_formatDisplayDate(kharcha.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        onLongPress: () => _deleteKharcha(kharcha.id),
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
}