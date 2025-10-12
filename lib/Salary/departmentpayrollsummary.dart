import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/kharchamodel.dart';
import '../models/modelpayroll.dart';

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

  // Calculate grand totals
  double get _totalBasicSalary => _payrollData.fold<double>(0, (sum, item) => sum + (item['basic_salary'] ?? 0));
  double get _totalAllowances => _payrollData.fold<double>(0, (sum, item) => sum + (item['allowances'] ?? 0));
  double get _totalDeductions => _payrollData.fold<double>(0, (sum, item) => sum + (item['deductions'] ?? 0));
  double get _totalNetSalary => _payrollData.fold<double>(0, (sum, item) => sum + (item['net_salary'] ?? 0));

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
                _buildSummaryCard("Total Basic", _totalBasicSalary, Icons.attach_money, primaryColor),
                const SizedBox(width: 12),
                _buildSummaryCard("Total Allowances", _totalAllowances, Icons.add_circle, successColor),
                const SizedBox(width: 12),
                _buildSummaryCard("Total Deductions", _totalDeductions, Icons.remove_circle, errorColor),
                const SizedBox(width: 12),
                _buildSummaryCard("Total Net Pay", _totalNetSalary, Icons.account_balance_wallet, accentColor),
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

  // NEW: Grand Total Card at the bottom
  Widget _buildGrandTotalCard() {
    if (_payrollData.isEmpty) return const SizedBox();

    return Card(
      elevation: 2,
      color: accentColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.account_balance_wallet, color: surfaceColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "GRAND TOTAL",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: surfaceColor.withOpacity(0.9),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Total Net Salary for ${_payrollData.length} employees",
                    style: TextStyle(
                      fontSize: 14,
                      color: surfaceColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: surfaceColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "₹${_totalNetSalary.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: surfaceColor,
                ),
              ),
            ),
          ],
        ),
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
            const SizedBox(height: 16),
            _buildGrandTotalCard(), // NEW: Added grand total card at the bottom
          ],
        ),
      ),
    );
  }
}