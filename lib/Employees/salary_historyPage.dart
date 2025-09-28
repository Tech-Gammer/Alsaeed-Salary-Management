import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


class SalaryHistory {
  final int id;
  final double oldSalary;
  final double newSalary;
  final String changedAt;

  SalaryHistory({
    required this.id,
    required this.oldSalary,
    required this.newSalary,
    required this.changedAt,
  });

  factory SalaryHistory.fromJson(Map<String, dynamic> json) {
    return SalaryHistory(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      oldSalary: double.tryParse(json['old_salary'].toString()) ?? 0.0, // ✅ FIX
      newSalary: double.tryParse(json['new_salary'].toString()) ?? 0.0, // ✅ FIX
      changedAt: json['changed_at']?.toString() ?? '',
    );
  }

}


const Color historyPrimaryColor = Color(0xFF3949AB);
const String _apiBaseUrl = "http://localhost:3000/api";

class SalaryHistoryPage extends StatefulWidget {
  final dynamic departmentId;
  final String departmentName;

  const SalaryHistoryPage({super.key, required this.departmentId, required this.departmentName});

  @override
  State<SalaryHistoryPage> createState() => _SalaryHistoryPageState();
}

class _SalaryHistoryPageState extends State<SalaryHistoryPage> {
  List<SalaryHistory> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSalaryHistory();
  }

  Future<void> _fetchSalaryHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('$_apiBaseUrl/departments/${widget.departmentId}/salary-history'))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _history = data.map((json) => SalaryHistory.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed: ${response.statusCode}\n${response.body}";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _generateSalaryHistoryPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) => [
          pw.Center(
            child: pw.Text(
              "${widget.departmentName} - Salary History",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Salary History Table
          _history.isEmpty
              ? pw.Center(
              child: pw.Text("No salary history found.",
                  style: pw.TextStyle(color: PdfColors.grey)))
              : pw.Table.fromTextArray(
            headers: ['Old Salary', 'New Salary', 'Changed At'],
            data: _history.map((entry) {
              return [
                entry.oldSalary.toStringAsFixed(2),
                entry.newSalary.toStringAsFixed(2),
                entry.changedAt,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration:
            const pw.BoxDecoration(color: PdfColors.indigo),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            border: null,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.departmentName} - Salary History",
            style: const TextStyle(color: Colors.white)),
        backgroundColor: historyPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSalaryHistory,
        color: historyPrimaryColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: historyPrimaryColor))
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
            : _history.isEmpty
            ? const Center(
            child: Text("No salary history found.",
                style: TextStyle(fontSize: 16, color: Colors.grey)))
            : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _history.length,
          itemBuilder: (context, index) {
            final entry = _history[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: historyPrimaryColor.withOpacity(0.15),
                  child: const Icon(Icons.history, color: historyPrimaryColor),
                ),
                title: Text(
                  "Changed from ${entry.oldSalary.toStringAsFixed(2)} → ${entry.newSalary.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text("At: ${entry.changedAt}"),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: historyPrimaryColor,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("Export PDF"),
        onPressed: _history.isEmpty ? null : _generateSalaryHistoryPdf,
      ),
    );
  }
}
