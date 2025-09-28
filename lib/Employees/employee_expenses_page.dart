import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class EmployeeExpensesPage extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeExpensesPage({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<EmployeeExpensesPage> createState() => _EmployeeExpensesPageState();
}

class _EmployeeExpensesPageState extends State<EmployeeExpensesPage> {
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color accentColor = Color(0xFF50E3C2);
  static const Color textColor = Color(0xFF333333);
  static const Color subtleTextColor = Color(0xFF757575);
  static const Color warningColor = Color(0xFFFF9800);

  List<dynamic> expenses = [];
  List<dynamic> filteredExpenses = [];
  bool isLoading = true;
  final String _apiBaseUrl = "http://localhost:3000";

  // Date Range Picker Variables
  DateTime? startDate;
  DateTime? endDate;
  bool isFilteringByDate = false;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    try {
      final url = Uri.parse("$_apiBaseUrl/api/employees/${widget.employeeId}/expenses");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          expenses = jsonDecode(response.body);
          filteredExpenses = List.from(expenses);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load expenses: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching expenses: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _filterExpensesByDateRange() {
    if (startDate == null || endDate == null) {
      setState(() {
        filteredExpenses = List.from(expenses);
        isFilteringByDate = false;
      });
      return;
    }

    setState(() {
      filteredExpenses = expenses.where((expense) {
        try {
          final expenseDate = DateTime.parse(expense['expenseDate'] ?? '');
          return expenseDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
              expenseDate.isBefore(endDate!.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
      isFilteringByDate = true;
    });
  }

  void _clearDateFilter() {
    setState(() {
      startDate = null;
      endDate = null;
      filteredExpenses = List.from(expenses);
      isFilteringByDate = false;
    });
  }

  void _showDateRangePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Date Range"),
        content: SizedBox(
          width: 300,
          height: 400,
          child: SfDateRangePicker(
            selectionMode: DateRangePickerSelectionMode.range,
            initialSelectedRange: startDate != null && endDate != null
                ? PickerDateRange(startDate, endDate)
                : null,
            onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
              if (args.value is PickerDateRange) {
                final range = args.value as PickerDateRange;
                setState(() {
                  startDate = range.startDate;
                  endDate = range.endDate;
                });
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _filterExpensesByDateRange();
            },
            child: const Text("Apply", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  // PDF Generation Functions
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Expense Report - ${widget.employeeName}',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Date Range Info
              if (isFilteringByDate && startDate != null && endDate != null)
                pw.Text(
                  'Date Range: ${DateFormat('yyyy-MM-dd').format(startDate!)} to ${DateFormat('yyyy-MM-dd').format(endDate!)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),

              pw.SizedBox(height: 20),

              // Table Header
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex("#4A90E2"),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'Description',
                        style:  pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Date',
                        style:  pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Amount',
                        style:  pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Expense Items
              ...filteredExpenses.map((expense) {
                final amount = _formatAmountForPdf(expense['amount'] ?? '0');
                final date = _formatDateForPdf(expense['expenseDate'] ?? '');
                final description = expense['description'] ?? 'No description';

                return pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
                  ),
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(description),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(date),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(amount),
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.SizedBox(height: 20),

              // Summary
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Expenses: ${filteredExpenses.length}',
                      style:  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Total Amount: ${_calculateTotalAmount()}',
                      style:  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  String _formatDateForPdf(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatAmountForPdf(String amount) {
    try {
      final value = double.parse(amount);
      return "Rs ${value.toStringAsFixed(2)}";
    } catch (e) {
      return "Rs $amount";
    }
  }

  String _calculateTotalAmount() {
    double total = 0;
    for (var expense in filteredExpenses) {
      try {
        total += double.parse(expense['amount'] ?? '0');
      } catch (e) {
        // Skip invalid amounts
      }
    }
    return "Rs ${total.toStringAsFixed(2)}";
  }

  void _generateAndSharePdf() async {
    try {
      final Uint8List pdfData = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error generating PDF: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatAmount(String amount) {
    try {
      final value = double.parse(amount);
      return "Rs ${value.toStringAsFixed(2)}";
    } catch (e) {
      return "Rs $amount";
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: subtleTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isFilteringByDate ? 'No expenses in selected date range' : 'No expenses found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: subtleTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFilteringByDate
                ? 'Try selecting a different date range'
                : 'Expenses for ${widget.employeeName} will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: subtleTextColor.withOpacity(0.7),
            ),
          ),
          if (isFilteringByDate) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _clearDateFilter,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Date Filter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseCard(int index) {
    final exp = filteredExpenses[index];
    final amount = _formatAmount(exp['amount'] ?? '0');
    final date = _formatDate(exp['expenseDate'] ?? '');
    final description = exp['description'] ?? 'No description';

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.receipt,
            color: accentColor,
            size: 24,
          ),
        ),
        title: Text(
          description,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(
                color: subtleTextColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFE53935),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Expense',
                style: TextStyle(
                  color: warningColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.employeeName}\'s Expenses',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: _showDateRangePicker,
            tooltip: 'Filter by date range',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _generateAndSharePdf,
            tooltip: 'Generate PDF Report',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchExpenses,
            tooltip: 'Refresh expenses',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Loading expenses...',
              style: TextStyle(
                color: subtleTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Header with filters and summary
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Expenses: ${filteredExpenses.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Employee ID: ${widget.employeeId}',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isFilteringByDate && startDate != null && endDate != null)
                  Row(
                    children: [
                      Icon(Icons.date_range, size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('MMM dd, yyyy').format(startDate!)} - ${DateFormat('MMM dd, yyyy').format(endDate!)}',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _clearDateFilter,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.clear, size: 14),
                            SizedBox(width: 4),
                            Text('Clear'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Expenses List
          Expanded(
            child: filteredExpenses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              itemCount: filteredExpenses.length,
              itemBuilder: (context, index) => _buildExpenseCard(index),
            ),
          ),
        ],
      ),
    );
  }
}