// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
//
// import '../models/modelpayroll.dart';
// import '../models/kharchamodel.dart';
// import 'create_payroll_period_page.dart';
//
// class PayrollProcessingPage extends StatefulWidget {
//   const PayrollProcessingPage({super.key});
//
//   @override
//   State<PayrollProcessingPage> createState() => _PayrollProcessingPageState();
// }
//
// class _PayrollProcessingPageState extends State<PayrollProcessingPage> {
//   static const Color primaryColor = Color(0xFF4A90E2);
//   static const Color secondaryColor = Color(0xFF6C63FF);
//   static const Color backgroundColor = Color(0xFFF8F9FA);
//   static const Color cardColor = Color(0xFFFFFFFF);
//   static const Color textColor = Color(0xFF2D3748);
//
//   List<Department> _departments = [];
//   List<PayrollPeriod> _periods = [];
//   Department? _selectedDepartment;
//   PayrollPeriod? _selectedPeriod;
//   List<EmployeePayroll> _employees = [];
//   List<EmployeePayroll> _selectedEmployees = [];
//   List<Kharcha> _kharchas = [];
//   bool _isLoading = false;
//   bool _isGenerating = false;
//   bool _selectAllEmployees = true;
//   final Map<int, TextEditingController> _workingDaysControllers = {};
//   final Map<int, TextEditingController> _leaveDaysControllers = {};
//   static const String _apiBaseUrl = "http://localhost:3000/api";
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchDepartments();
//     _fetchPeriods();
//   }
//
//   Future<void> _fetchDepartments() async {
//     try {
//       final response = await http.get(Uri.parse("$_apiBaseUrl/departments"));
//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         setState(() {
//           _departments = data.map((dept) => Department.fromJson(dept)).toList();
//         });
//       }
//     } catch (e) {
//       _showError("Error fetching departments: $e");
//     }
//   }
//
//   Future<void> _fetchPeriods() async {
//     try {
//       final response = await http.get(Uri.parse("$_apiBaseUrl/payroll/periods"));
//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         setState(() {
//           _periods = data.map((period) => PayrollPeriod.fromJson(period)).toList();
//         });
//       } else {
//         _showError("Failed to fetch periods: ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Error fetching periods: $e");
//     }
//   }
//
//   Future<void> _loadDepartmentEmployees() async {
//     if (_selectedDepartment == null) return;
//
//     setState(() { _isLoading = true; });
//
//     try {
//       final response = await http.get(
//           Uri.parse("$_apiBaseUrl/payroll/department/${_selectedDepartment!.id}/employees")
//       );
//
//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         setState(() {
//           _employees = data.map((emp) => EmployeePayroll.fromJson(emp)).toList();
//           _selectedEmployees = List.from(_employees); // Select all by default
//           _workingDaysControllers.clear();
//           _leaveDaysControllers.clear();
//         });
//         _fetchKharchas(); // Load kharchas for the selected department/period
//       } else {
//         _showError("Failed to load employees: ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Error loading employees: $e");
//     } finally {
//       setState(() { _isLoading = false; });
//     }
//   }
//
//   Future<void> _fetchKharchas() async {
//     if (_selectedDepartment == null || _selectedPeriod == null) return;
//
//     try {
//       String url = "$_apiBaseUrl/kharcha";
//       final Map<String, String> params = {
//         'department_id': _selectedDepartment!.id.toString(),
//         'period_id': _selectedPeriod!.id.toString(),
//       };
//
//       url += "?${Uri(queryParameters: params).query}";
//
//       final response = await http.get(Uri.parse(url));
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List kharchaList = (data is Map && data.containsKey('kharchas'))
//             ? (data['kharchas'] ?? [])
//             : (data is List ? data : []);
//
//         final List<Kharcha> parsedKharchas = kharchaList.map((k) {
//           try {
//             return Kharcha.fromJson(k);
//           } catch (e) {
//             print("❌ Error parsing kharcha: $e");
//             return null;
//           }
//         }).whereType<Kharcha>().toList();
//
//         setState(() {
//           _kharchas = parsedKharchas;
//         });
//       }
//     } catch (e) {
//       print("Error loading kharchas: $e");
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.error_outline, color: Colors.white),
//             const SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   void _toggleEmployeeSelection(EmployeePayroll employee) {
//     setState(() {
//       if (_selectedEmployees.contains(employee)) {
//         _selectedEmployees.remove(employee);
//       } else {
//         _selectedEmployees.add(employee);
//       }
//       _selectAllEmployees = _selectedEmployees.length == _employees.length;
//     });
//   }
//
//   void _toggleSelectAllEmployees() {
//     setState(() {
//       if (_selectAllEmployees) {
//         _selectedEmployees.clear();
//         _selectAllEmployees = false;
//       } else {
//         _selectedEmployees = List.from(_employees);
//         _selectAllEmployees = true;
//       }
//     });
//   }
//
//   double _getEmployeeKharcha(int employeeId) {
//     return _kharchas
//         .where((kharcha) => kharcha.employeeId == employeeId && kharcha.kharchaType == 'individual')
//         .fold(0.0, (sum, kharcha) => sum + kharcha.amount);
//   }
//
//   double _getDepartmentKharcha() {
//     return _kharchas
//         .where((kharcha) => kharcha.kharchaType == 'department')
//         .fold(0.0, (sum, kharcha) => sum + kharcha.amount);
//   }
//
//   Future<void> _generatePayroll() async {
//     if (_selectedDepartment == null || _selectedPeriod == null) {
//       _showError("Please select department and period");
//       return;
//     }
//
//     if (_selectedEmployees.isEmpty) {
//       _showError("Please select at least one employee");
//       return;
//     }
//
//     setState(() { _isGenerating = true; });
//
//     try {
//       final departmentKharcha = _getDepartmentKharcha();
//       final departmentKharchaPerEmployee = departmentKharcha / _selectedEmployees.length;
//
//       final payrollEmployees = _selectedEmployees.map((emp) {
//         final calculatedBasicSalary = _calculateEmployeeSalary(emp);
//         final allowances = calculatedBasicSalary * 0.1;
//         final individualKharcha = _getEmployeeKharcha(emp.id);
//         final totalKharcha = individualKharcha + departmentKharchaPerEmployee;
//         final deductions = (calculatedBasicSalary * 0.05) + totalKharcha;
//         final netSalary = calculatedBasicSalary + allowances - deductions;
//
//         final dailyRate = emp.salary / 30;
//         final workingSalary = dailyRate * emp.workingDays;
//         final leaveSalary = dailyRate * emp.leaveDays;
//
//         // Prepare components
//         final components = [
//           {"type": "allowance", "name": "House Rent", "amount": allowances},
//           {"type": "deduction", "name": "Tax", "amount": calculatedBasicSalary * 0.05},
//         ];
//
//         // Add kharcha components
//         if (individualKharcha > 0) {
//           components.add({"type": "deduction", "name": "Individual Kharcha", "amount": individualKharcha});
//         }
//         if (departmentKharchaPerEmployee > 0) {
//           components.add({"type": "deduction", "name": "Department Kharcha Share", "amount": departmentKharchaPerEmployee});
//         }
//
//         // Add working salary breakdown if not full month
//         if (emp.workingDays > 0 && emp.workingDays < 30) {
//           components.addAll([
//             {"type": "allowance", "name": "Working Days Salary", "amount": workingSalary},
//             {"type": "allowance", "name": "Leave Days Salary", "amount": leaveSalary},
//           ]);
//         }
//
//         return {
//           "employee_id": emp.id,
//           "basic_salary": calculatedBasicSalary,
//           "allowances": allowances,
//           "deductions": deductions,
//           "net_salary": netSalary,
//           "working_days": emp.workingDays,
//           "leave_days": emp.leaveDays,
//           "daily_rate": dailyRate,
//           "working_salary": workingSalary,
//           "leave_salary": leaveSalary,
//           "components": components,
//           "kharcha_deductions": totalKharcha,
//         };
//       }).toList();
//
//       final response = await http.post(
//         Uri.parse("$_apiBaseUrl/payroll/department/${_selectedDepartment!.id}/generate"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "period_id": _selectedPeriod!.id,
//           "employees": payrollEmployees,
//         }),
//       );
//
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text("Payroll generated successfully"),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//         _viewGeneratedPayroll();
//       } else {
//         _showError("Failed to generate payroll: ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Error generating payroll: $e");
//     } finally {
//       setState(() { _isGenerating = false; });
//     }
//   }
//
//   void _viewGeneratedPayroll() {
//     if (_selectedDepartment == null || _selectedPeriod == null) return;
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => DepartmentPayrollPage(
//           departmentId: _selectedDepartment!.id,
//           periodId: _selectedPeriod!.id,
//           departmentName: _selectedDepartment!.name,
//           periodName: _selectedPeriod!.periodName,
//         ),
//       ),
//     );
//   }
//
//   String _calculateDays(PayrollPeriod period) {
//     if (period.periodType == 'full_month') {
//       return '30';
//     } else {
//       final start = DateTime.parse(period.startDate);
//       final end = DateTime.parse(period.endDate);
//       return (end.difference(start).inDays + 1).toString();
//     }
//   }
//
//   void _navigateToCreatePeriod(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const CreatePayrollPeriodPage()),
//     ).then((_) {
//       _fetchPeriods();
//     });
//   }
//
//   Widget _buildSelectionCard() {
//     return Card(
//       elevation: 2,
//       color: cardColor,
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.filter_alt, color: primaryColor, size: 20),
//                 const SizedBox(width: 8),
//                 Text(
//                   "SELECTION CRITERIA",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildDepartmentDropdown(),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: _buildPeriodDropdown(),
//                 ),
//                 const SizedBox(width: 8),
//                 _buildAddPeriodButton(),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDepartmentDropdown() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Department",
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: textColor.withOpacity(0.8),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade300),
//           ),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<Department>(
//               value: _selectedDepartment,
//               isExpanded: true,
//               icon: const Icon(Icons.keyboard_arrow_down, color: primaryColor),
//               items: _departments.map((dept) {
//                 return DropdownMenuItem(
//                   value: dept,
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     child: Text(
//                       dept.name,
//                       style: const TextStyle(fontSize: 14),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 );
//               }).toList(),
//               onChanged: (dept) {
//                 setState(() {
//                   _selectedDepartment = dept;
//                   _employees.clear();
//                   _selectedEmployees.clear();
//                   _kharchas.clear();
//                 });
//                 if (dept != null) _loadDepartmentEmployees();
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPeriodDropdown() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Payroll Period",
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: textColor.withOpacity(0.8),
//           ),
//         ),
//         const SizedBox(height: 8),
//         _periods.isEmpty
//             ? OutlinedButton.icon(
//           icon: const Icon(Icons.add, size: 18),
//           label: const Text("Create Period"),
//           onPressed: () => _navigateToCreatePeriod(context),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: primaryColor,
//             side: BorderSide(color: primaryColor),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//         )
//             : Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade300),
//           ),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<PayrollPeriod>(
//               value: _selectedPeriod,
//               isExpanded: true,
//               icon: const Icon(Icons.keyboard_arrow_down, color: primaryColor),
//               items: _periods.map((period) {
//                 final periodType = period.periodType == 'full_month' ? '📅 Full Month' : '📋 Custom Range';
//                 final days = _calculateDays(period);
//                 return DropdownMenuItem(
//                   value: period,
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           period.periodName,
//                           style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//                         ),
//                         Text(
//                           '$periodType • $days days',
//                           style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }).toList(),
//               onChanged: (period) {
//                 setState(() {
//                   _selectedPeriod = period;
//                   _kharchas.clear();
//                 });
//                 if (_selectedDepartment != null) _fetchKharchas();
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildAddPeriodButton() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             color: primaryColor,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: IconButton(
//             icon: const Icon(Icons.add, color: Colors.white, size: 20),
//             onPressed: () => _navigateToCreatePeriod(context),
//             tooltip: "Create New Period",
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildKharchaSummary() {
//     if (_kharchas.isEmpty || _selectedDepartment == null) return const SizedBox();
//
//     final departmentKharcha = _getDepartmentKharcha();
//     final totalIndividualKharcha = _kharchas
//         .where((kharcha) => kharcha.kharchaType == 'individual')
//         .fold(0.0, (sum, kharcha) => sum + kharcha.amount);
//
//     return Card(
//       elevation: 2,
//       color: Colors.orange[50],
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.money_off, color: Colors.orange, size: 20),
//                 const SizedBox(width: 8),
//                 const Text(
//                   "KHARCHA SUMMARY",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.orange,
//                   ),
//                 ),
//                 const Spacer(),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.orange.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     "Total: ₹${(departmentKharcha + totalIndividualKharcha).toStringAsFixed(2)}",
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.orange,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 _buildKharchaItem("Department", departmentKharcha),
//                 const SizedBox(width: 16),
//                 _buildKharchaItem("Individual", totalIndividualKharcha),
//                 const SizedBox(width: 16),
//                 _buildKharchaItem(
//                     "Per Employee",
//                     _selectedEmployees.isEmpty ? 0 : departmentKharcha / _selectedEmployees.length
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildKharchaItem(String label, double amount) {
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 12,
//               color: Colors.orange,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           Text(
//             "₹${amount.toStringAsFixed(2)}",
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: Colors.orange,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmployeesSection() {
//     if (_selectedDepartment == null) {
//       return const SizedBox();
//     }
//
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16.0),
//             child: Row(
//               children: [
//                 const Icon(Icons.people, color: primaryColor, size: 20),
//                 const SizedBox(width: 8),
//                 Text(
//                   "EMPLOYEES IN ${_selectedDepartment!.name.toUpperCase()}",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//                 const Spacer(),
//                 // Select All toggle
//                 Row(
//                   children: [
//                     Text(
//                       "Select All",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: textColor.withOpacity(0.7),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Switch(
//                       value: _selectAllEmployees,
//                       onChanged: (value) => _toggleSelectAllEmployees(),
//                       activeColor: primaryColor,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(width: 12),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: primaryColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Text(
//                     "${_selectedEmployees.length}/${_employees.length} selected",
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: primaryColor,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: _buildEmployeesList(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmployeesList() {
//     if (_isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(primaryColor)),
//             const SizedBox(height: 16),
//             Text(
//               "Loading Employees...",
//               style: TextStyle(
//                 fontSize: 16,
//                 color: textColor.withOpacity(0.6),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_employees.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
//             const SizedBox(height: 16),
//             Text(
//               "No Employees Found",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//                 color: textColor.withOpacity(0.6),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Select a department to view employees",
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey.shade500,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return ListView.builder(
//       itemCount: _employees.length,
//       itemBuilder: (context, index) {
//         final emp = _employees[index];
//         final isSelected = _selectedEmployees.contains(emp);
//         final individualKharcha = _getEmployeeKharcha(emp.id);
//         emp.calculatedSalary = _calculateEmployeeSalary(emp);
//
//         return Container(
//           margin: const EdgeInsets.only(bottom: 8),
//           child: Card(
//             elevation: 1,
//             color: isSelected ? primaryColor.withOpacity(0.05) : cardColor,
//             child: Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Column(
//                 children: [
//                   // Employee selection and basic info row
//                   Row(
//                     children: [
//                       // Selection checkbox
//                       Checkbox(
//                         value: isSelected,
//                         onChanged: (value) => _toggleEmployeeSelection(emp),
//                         activeColor: primaryColor,
//                       ),
//                       // Employee avatar
//                       Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: primaryColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Center(
//                           child: Text(
//                             emp.name[0].toUpperCase(),
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: primaryColor,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               emp.name,
//                               style: const TextStyle(fontWeight: FontWeight.w600),
//                             ),
//                             Text(
//                               emp.designation,
//                               style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//                             ),
//                             if (individualKharcha > 0)
//                               Text(
//                                 "Kharcha: ₹${individualKharcha.toStringAsFixed(2)}",
//                                 style: const TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.orange,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Text(
//                             "₹${emp.salary.toStringAsFixed(2)}",
//                             style: TextStyle(
//                               color: Colors.grey.shade700,
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           Text(
//                             "₹${emp.calculatedSalary.toStringAsFixed(2)}",
//                             style: TextStyle(
//                               color: secondaryColor,
//                               fontWeight: FontWeight.w600,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//
//                   // Days input section - only show for full_month period and selected employees
//                   if (isSelected && _selectedPeriod?.periodType == 'full_month') ...[
//                     const SizedBox(height: 12),
//                     const Divider(height: 1),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         // Working Days Input
//                         _buildDayInputSection(emp, true),
//                         const SizedBox(width: 16),
//                         // Leave Days Input
//                         _buildDayInputSection(emp, false),
//                         const SizedBox(width: 16),
//                         // Calculation Info
//                         _buildCalculationInfo(emp),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildDayInputSection(EmployeePayroll emp, bool isWorkingDays) {
//     final label = isWorkingDays ? "Working Days" : "Leave Days";
//     final currentValue = isWorkingDays ? emp.workingDays : emp.leaveDays;
//     final icon = isWorkingDays ? Icons.work : Icons.beach_access;
//     final color = isWorkingDays ? Colors.green : Colors.orange;
//
//     final controllerKey = emp.id;
//     TextEditingController controller;
//
//     if (isWorkingDays) {
//       if (!_workingDaysControllers.containsKey(controllerKey)) {
//         _workingDaysControllers[controllerKey] = TextEditingController(text: currentValue.toString());
//       }
//       controller = _workingDaysControllers[controllerKey]!;
//     } else {
//       if (!_leaveDaysControllers.containsKey(controllerKey)) {
//         _leaveDaysControllers[controllerKey] = TextEditingController(text: currentValue.toString());
//       }
//       controller = _leaveDaysControllers[controllerKey]!;
//     }
//
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 16, color: color),
//               const SizedBox(width: 4),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: textColor.withOpacity(0.8),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Container(
//             height: 36,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.grey.shade300),
//             ),
//             child: TextField(
//               controller: controller,
//               keyboardType: TextInputType.numberWithOptions(
//                   decimal: false,
//                   signed: !isWorkingDays
//               ),
//               textAlign: TextAlign.center,
//               decoration: InputDecoration(
//                 border: InputBorder.none,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 hintText: '0',
//                 hintStyle: TextStyle(color: Colors.grey.shade400),
//               ),
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: color,
//               ),
//               onChanged: (value) {
//                 if (value.isEmpty) {
//                   _updateEmployeeDays(emp, isWorkingDays, 0);
//                   return;
//                 }
//
//                 if (!isWorkingDays && value == '-') {
//                   return;
//                 }
//
//                 final RegExp validPattern = isWorkingDays
//                     ? RegExp(r'^\d+$')
//                     : RegExp(r'^-?\d+$');
//
//                 if (validPattern.hasMatch(value)) {
//                   final numericValue = int.parse(value);
//                   _updateEmployeeDays(emp, isWorkingDays, numericValue);
//                 } else {
//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     controller.text = currentValue.toString();
//                     controller.selection = TextSelection.fromPosition(
//                       TextPosition(offset: controller.text.length),
//                     );
//                   });
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCalculationInfo(EmployeePayroll emp) {
//     final totalMonthDays = 30;
//     final dailyRate = emp.salary / totalMonthDays;
//     final workingSalary = dailyRate * emp.workingDays;
//     final leaveSalary = dailyRate * emp.leaveDays;
//     final individualKharcha = _getEmployeeKharcha(emp.id);
//     final departmentKharchaShare = _selectedEmployees.isEmpty ? 0 : _getDepartmentKharcha() / _selectedEmployees.length;
//
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Calculation",
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: textColor.withOpacity(0.8),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             "Daily: ₹${dailyRate.toStringAsFixed(2)}",
//             style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
//           ),
//           Text(
//             "Work: ${emp.workingDays} days",
//             style: TextStyle(fontSize: 10, color: Colors.green.shade600),
//           ),
//           Text(
//             "Leave: ${emp.leaveDays} days",
//             style: TextStyle(fontSize: 10, color: Colors.orange.shade600),
//           ),
//           if (individualKharcha > 0)
//             Text(
//               "Kharcha: -₹${individualKharcha.toStringAsFixed(2)}",
//               style: TextStyle(fontSize: 10, color: Colors.red.shade600),
//             ),
//           const SizedBox(height: 2),
//           Container(
//             padding: const EdgeInsets.all(4),
//             decoration: BoxDecoration(
//               color: secondaryColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             child: Text(
//               "Net: ₹${emp.calculatedSalary.toStringAsFixed(2)}",
//               style: TextStyle(
//                 fontSize: 10,
//                 fontWeight: FontWeight.bold,
//                 color: secondaryColor,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _updateEmployeeDays(EmployeePayroll emp, bool isWorkingDays, int newValue) {
//     setState(() {
//       if (isWorkingDays) {
//         emp.workingDays = newValue < 0 ? 0 : newValue;
//       } else {
//         emp.leaveDays = newValue;
//       }
//       emp.calculatedSalary = _calculateEmployeeSalary(emp);
//     });
//   }
//
//   double _calculateEmployeeSalary(EmployeePayroll emp) {
//     if (_selectedPeriod == null) return emp.salary;
//
//     if (_selectedPeriod!.periodType == 'full_month') {
//       final totalMonthDays = 30;
//       final dailyRate = emp.salary / totalMonthDays;
//
//       final double actualWorkingDays = emp.workingDays.toDouble();
//       final double actualLeaveDays = emp.leaveDays.toDouble();
//
//       final workingSalary = dailyRate * actualWorkingDays;
//       final leaveSalary = dailyRate * actualLeaveDays;
//
//       final totalSalary = workingSalary + leaveSalary;
//
//       // Deduct kharcha
//       final individualKharcha = _getEmployeeKharcha(emp.id);
//       final departmentKharchaShare = _selectedEmployees.isEmpty ? 0 : _getDepartmentKharcha() / _selectedEmployees.length;
//       final totalKharcha = individualKharcha + departmentKharchaShare;
//
//       final netSalary = totalSalary - totalKharcha;
//
//       return netSalary < 0 ? 0.0 : netSalary;
//
//     } else {
//       final startDate = DateTime.parse(_selectedPeriod!.startDate);
//       final endDate = DateTime.parse(_selectedPeriod!.endDate);
//       final totalDaysInPeriod = endDate.difference(startDate).inDays + 1;
//
//       if (totalDaysInPeriod <= 0) return 0.0;
//
//       final dailyRate = emp.salary / 30;
//       return dailyRate * totalDaysInPeriod;
//     }
//   }
//
//   Widget _buildGenerateButton() {
//     if (_selectedEmployees.isEmpty || _selectedPeriod == null) {
//       return const SizedBox();
//     }
//
//     return Column(
//       children: [
//         if (_selectedPeriod?.periodType == 'full_month')
//           Padding(
//             padding: const EdgeInsets.only(bottom: 8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: _resetAllDays,
//                     icon: const Icon(Icons.refresh, size: 18),
//                     label: const Text("RESET ALL DAYS"),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.grey,
//                       side: BorderSide(color: Colors.grey.shade400),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         Container(
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           child: SizedBox(
//             width: double.infinity,
//             height: 56,
//             child: ElevatedButton.icon(
//               onPressed: _isGenerating ? null : _generatePayroll,
//               icon: _isGenerating
//                   ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
//               )
//                   : const Icon(Icons.play_arrow, size: 24),
//               label: _isGenerating
//                   ? const Text("GENERATING...")
//                   : Text("GENERATE PAYROLL (${_selectedEmployees.length} employees)"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: secondaryColor,
//                 foregroundColor: Colors.white,
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   void _resetAllDays() {
//     setState(() {
//       for (var emp in _selectedEmployees) {
//         emp.workingDays = 0;
//         emp.leaveDays = 0;
//         emp.calculatedSalary = _calculateEmployeeSalary(emp);
//
//         if (_workingDaysControllers.containsKey(emp.id)) {
//           _workingDaysControllers[emp.id]!.text = '0';
//         }
//         if (_leaveDaysControllers.containsKey(emp.id)) {
//           _leaveDaysControllers[emp.id]!.text = '0';
//         }
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         title: const Text('Payroll Processing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
//         backgroundColor: primaryColor,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSelectionCard(),
//             const SizedBox(height: 16),
//             _buildKharchaSummary(),
//             const SizedBox(height: 16),
//             _buildEmployeesSection(),
//             _buildGenerateButton(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _workingDaysControllers.forEach((key, controller) => controller.dispose());
//     _leaveDaysControllers.forEach((key, controller) => controller.dispose());
//     super.dispose();
//   }
// }
//
// // DepartmentPayrollPage remains the same as in your original code
// class DepartmentPayrollPage extends StatefulWidget {
//   final int departmentId;
//   final int periodId;
//   final String departmentName;
//   final String periodName;
//
//   const DepartmentPayrollPage({
//     super.key,
//     required this.departmentId,
//     required this.periodId,
//     required this.departmentName,
//     required this.periodName,
//   });
//
//   @override
//   State<DepartmentPayrollPage> createState() => _DepartmentPayrollPageState();
// }
//
// // ... (Keep the existing DepartmentPayrollPage implementation as is)