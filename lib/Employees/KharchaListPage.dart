import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/kharchamodel.dart';
import '../models/EmployeeModel.dart';
import '../models/modelpayroll.dart';

class KharchaListPage extends StatefulWidget {
  const KharchaListPage({super.key});

  @override
  State<KharchaListPage> createState() => _KharchaListPageState();
}

class _KharchaListPageState extends State<KharchaListPage> {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF10B981);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  List<Kharcha> _kharchas = [];
  List<Department> _departments = [];
  List<Employee> _employees = [];
  List<PayrollPeriod> _periods = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  // Filter variables
  Department? _selectedDepartment;
  Employee? _selectedEmployee;
  PayrollPeriod? _selectedPeriod;

  final TextEditingController _employeeSearchController = TextEditingController();

  // Employee search for filter
  List<Employee> _filteredEmployees = [];
  bool _showEmployeeSuggestions = false;
  final FocusNode _employeeSearchFocusNode = FocusNode();
  final LayerLink _employeeSearchLayerLink = LayerLink();
  OverlayEntry? _employeeOverlayEntry;

  static const String _apiBaseUrl = "http://localhost:3000/api";

  @override
  void initState() {
    super.initState();
    _fetchKharchas();
    _fetchDepartments();
    _fetchEmployees();
    _fetchPeriods();

    _employeeSearchController.addListener(_filterEmployees);
    _employeeSearchFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
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
    _applyFilters();
  }

  void _clearEmployeeSelection() {
    setState(() {
      _selectedEmployee = null;
      _employeeSearchController.clear();
      _filteredEmployees = _employees;
    });
    _applyFilters();
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

  Future<void> _fetchKharchas() async {
    try {
      setState(() { _isLoading = true; });

      final Map<String, String> queryParams = {};

      if (_selectedDepartment != null) {
        queryParams['department_id'] = _selectedDepartment!.id.toString();
      }

      if (_selectedEmployee != null) {
        queryParams['employee_id'] = _selectedEmployee!.id; // This is now String
      }

      if (_selectedPeriod != null) {
        queryParams['period_id'] = _selectedPeriod!.id.toString();
      }

      final uri = Uri.parse("$_apiBaseUrl/kharcha").replace(queryParameters: queryParams);
      print("🔍 Fetching kharchas from: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List kharchaList = data['kharchas'] ?? [];

        print("✅ Received ${kharchaList.length} kharchas");

        if (mounted) {
          setState(() {
            _kharchas = kharchaList.map((kharcha) {
              try {
                return Kharcha.fromJson(kharcha);
              } catch (e) {
                print("❌ Error parsing kharcha: $e");
                print("❌ Problematic kharcha data: $kharcha");
                // Let's see what type each field is
                kharcha.forEach((key, value) {
                  print("  $key: $value (${value.runtimeType})");
                });
                // Use the fromJson with safe parsing
                return Kharcha.fromJson(kharcha);
              }
            }).toList();
          });
        }

        // Debug output
        _debugKharchaData();
      } else {
        _showError("Failed to fetch kharchas: ${response.statusCode}");
        print("❌ Response body: ${response.body}");
      }
    } catch (e) {
      _showError("Error fetching kharchas: $e");
      print("❌ Detailed error: $e");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _debugKharchaData() {
    print("=== KHARCHA DATA DEBUG ===");
    print("Total kharchas in UI: ${_kharchas.length}");

    int departmentCount = 0;
    int individualCount = 0;

    for (var kharcha in _kharchas) {
      if (kharcha.kharchaType == 'department') {
        departmentCount++;
      } else if (kharcha.kharchaType == 'individual') {
        individualCount++;
      }

      print("ID: ${kharcha.id} | "
          "Type: ${kharcha.kharchaType} | "
          "Department: ${kharcha.departmentName} | "
          "Employee: ${kharcha.employeeName} | "
          "Amount: ₹${kharcha.amount} | "
          "Created: ${kharcha.createdAt} | "
          "Updated: ${kharcha.updatedAt}");
    }

    print("Department kharchas: $departmentCount");
    print("Individual kharchas: $individualCount");
    print("==========================");
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
      print("❌ Error fetching departments: $e");
    }
  }

  Future<void> _fetchEmployees() async {
    try {
      final response = await http.get(Uri.parse("$_apiBaseUrl/employees?active=1"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _employees = data.map((emp) => Employee.fromJson(emp)).toList();
            _filteredEmployees = _employees;
          });
        }
      }
    } catch (e) {
      print("❌ Error fetching employees: $e");
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
          });
        }
      }
    } catch (e) {
      print("❌ Error fetching periods: $e");
    }
  }

  void _applyFilters() {
    _fetchKharchas();
  }

  void _clearFilters() {
    setState(() {
      _selectedDepartment = null;
      _selectedEmployee = null;
      _selectedPeriod = null;
      _employeeSearchController.clear();
    });
    _fetchKharchas();
  }

  Future<void> _refreshData() async {
    setState(() { _isRefreshing = true; });
    await _fetchKharchas();
    setState(() { _isRefreshing = false; });
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

  double get _totalAmount {
    return _kharchas.fold(0.0, (sum, kharcha) => sum + kharcha.amount);
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
          'All Expenses',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Add New Expense',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Expenses',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_kharchas.length} records (${_kharchas.where((k) => k.kharchaType == 'department').length} department, ${_kharchas.where((k) => k.kharchaType == 'individual').length} individual)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: primaryColor),
                  ),
                ],
              ),
            ),
          ),

          // Filters
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list, size: 20, color: primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDepartmentFilter(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEmployeeFilter(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPeriodFilter(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Kharcha List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _kharchas.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _kharchas.length,
                itemBuilder: (context, index) {
                  return _buildKharchaListItem(_kharchas[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Department>(
              value: _selectedDepartment,
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('All Departments'),
              ),
              items: [
                const DropdownMenuItem<Department>(
                  value: null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('All Departments'),
                  ),
                ),
                ..._departments.map((dept) {
                  return DropdownMenuItem(
                    value: dept,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(dept.name),
                    ),
                  );
                }),
              ],
              onChanged: (dept) {
                setState(() {
                  _selectedDepartment = dept;
                  // Clear employee selection when department is selected
                  if (dept != null) {
                    _selectedEmployee = null;
                    _employeeSearchController.clear();
                  }
                });
                _applyFilters();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Employee',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _employeeSearchLayerLink,
          child: TextField(
            controller: _employeeSearchController,
            focusNode: _employeeSearchFocusNode,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Search employee...',
              suffixIcon: _selectedEmployee != null
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: _clearEmployeeSelection,
              )
                  : const Icon(Icons.search, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Period',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PayrollPeriod>(
              value: _selectedPeriod,
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('All Periods'),
              ),
              items: [
                const DropdownMenuItem<PayrollPeriod>(
                  value: null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('All Periods'),
                  ),
                ),
                ..._periods.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(period.periodName),
                    ),
                  );
                }),
              ],
              onChanged: (period) {
                setState(() {
                  _selectedPeriod = period;
                });
                _applyFilters();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKharchaListItem(Kharcha kharcha) {
    final isIndividual = kharcha.kharchaType == 'individual';
    final displayName = isIndividual
        ? (kharcha.employeeName ?? 'Unknown Employee')
        : (kharcha.departmentName ?? 'Unknown Department');

    final typeColor = isIndividual ? secondaryColor : primaryColor;
    final typeIcon = isIndividual ? Icons.person : Icons.business;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withOpacity(0.1),
          child: Icon(typeIcon, color: typeColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isIndividual ? 'Individual' : 'Department',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: typeColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kharcha.description.isNotEmpty) ...[
              Text(
                kharcha.description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Period: ${kharcha.periodName}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${kharcha.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDisplayDate(kharcha.date),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Expenses Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or add new expenses',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}