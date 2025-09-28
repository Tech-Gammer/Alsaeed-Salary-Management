import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class EmployeeLoansPage extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeLoansPage({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<EmployeeLoansPage> createState() => _EmployeeLoansPageState();
}

class _EmployeeLoansPageState extends State<EmployeeLoansPage> {
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color accentColor = Color(0xFF50E3C2);
  static const Color textColor = Color(0xFF333333);
  static const Color subtleTextColor = Color(0xFF757575);
  static const Color successColor = Color(0xFF4CAF50);

  List<dynamic> loans = [];
  List<dynamic> filteredLoans = [];
  bool isLoading = true;
  final String _apiBaseUrl = "http://localhost:3000";

  // Date Range Picker
  DateTime? startDate;
  DateTime? endDate;
  bool isFilteringByDate = false;

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    try {
      final url = Uri.parse("$_apiBaseUrl/api/employees/${widget.employeeId}/loans");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          loans = jsonDecode(response.body);
          filteredLoans = List.from(loans);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load loans: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching loans: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _filterLoansByDateRange() {
    if (startDate == null || endDate == null) {
      setState(() {
        filteredLoans = List.from(loans);
        isFilteringByDate = false;
      });
      return;
    }

    setState(() {
      filteredLoans = loans.where((loan) {
        try {
          final loanDate = DateTime.parse(loan['loanDate'] ?? '');
          return loanDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
              loanDate.isBefore(endDate!.add(const Duration(days: 1)));
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
      filteredLoans = List.from(loans);
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
            onSelectionChanged: (args) {
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _filterLoansByDateRange();
            },
            child: const Text("Apply", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  // ---------- PDF ----------
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Loan Report - ${widget.employeeName}',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Generated: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 20),
            ...filteredLoans.map((loan) {
              final amount = _formatAmount(loan['amount'] ?? '0');
              final date = _formatDate(loan['loanDate'] ?? '');
              final desc = loan['description'] ?? 'Loan';

              return pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(desc),
                  pw.Text(date),
                  pw.Text(amount),
                ],
              );
            }),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  void _generateAndSharePdf() async {
    try {
      final pdfData = await _generatePdf();
      await Printing.layoutPdf(onLayout: (_) async => pdfData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating PDF: $e"), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(dateString));
    } catch (_) {
      return dateString;
    }
  }

  String _formatAmount(String amount) {
    try {
      final value = double.parse(amount);
      return "Rs ${value.toStringAsFixed(2)}";
    } catch (_) {
      return "Rs $amount";
    }
  }

  Widget _buildLoanCard(int index) {
    final loan = filteredLoans[index];
    final amount = _formatAmount(loan['amount'] ?? '0');
    final date = _formatDate(loan['loanDate'] ?? '');
    final description = loan['description'] ?? 'Loan';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.account_balance_wallet, color: accentColor, size: 24),
        ),
        title: Text(description,
            style: const TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 16)),
        subtitle: Text(date, style: TextStyle(color: subtleTextColor, fontSize: 13)),
        trailing: Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.bold, color: successColor, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("No loans found", style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.employeeName}'s Loans",style: const TextStyle(color: Colors.white, fontSize: 18),),
        backgroundColor: primaryColor,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today, color: Colors.white), onPressed: _showDateRangePicker),
          IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.white), onPressed: _generateAndSharePdf),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchLoans),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredLoans.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        itemCount: filteredLoans.length,
        itemBuilder: (_, i) => _buildLoanCard(i),
      ),
    );
  }
}
