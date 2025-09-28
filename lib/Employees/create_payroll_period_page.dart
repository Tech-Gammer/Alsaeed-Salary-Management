import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CreatePayrollPeriodPage extends StatefulWidget {
  const CreatePayrollPeriodPage({super.key});

  @override
  State<CreatePayrollPeriodPage> createState() => _CreatePayrollPeriodPageState();
}

class _CreatePayrollPeriodPageState extends State<CreatePayrollPeriodPage> {
  static const String _apiBaseUrl = "http://localhost:3000/api";

  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedPeriodType = 'full_month';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    if (_selectedPeriodType == 'full_month') {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
      _nameController.text = "Salary - ${DateFormat('MMMM yyyy').format(now)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Payroll Period'),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Period Type',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Full Month (30 days)'),
                            subtitle: const Text('Calculate salary for full month regardless of actual days'),
                            value: 'full_month',
                            groupValue: _selectedPeriodType,
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriodType = value!;
                                _initializeDates();
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Custom Range'),
                            subtitle: const Text('Select specific start and end dates'),
                            value: 'custom_range',
                            groupValue: _selectedPeriodType,
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriodType = value!;
                                // Keep current dates for custom range
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Period Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Period Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., Salary - January 2024',
              ),
            ),

            const SizedBox(height: 16),

            // Date Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Period Dates',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Start Date
                    Row(
                      children: [
                        const Text('Start Date:'),
                        const Spacer(),
                        Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _selectedPeriodType == 'custom_range'
                              ? () => _selectStartDate(context)
                              : null,
                          child: const Text('Select'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // End Date
                    Row(
                      children: [
                        const Text('End Date:'),
                        const Spacer(),
                        Text(DateFormat('yyyy-MM-dd').format(_endDate)),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _selectedPeriodType == 'custom_range'
                              ? () => _selectEndDate(context)
                              : null,
                          child: const Text('Select'),
                        ),
                      ],
                    ),

                    // Days Count
                    const SizedBox(height: 8),
                    Text(
                      'Total Days: ${_endDate.difference(_startDate).inDays + 1} days',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),

                    if (_selectedPeriodType == 'full_month') ...[
                      const SizedBox(height: 8),
                      const Text(
                        '💰 Salary will be calculated for 30 days regardless of actual month days',
                        style: TextStyle(fontSize: 12, color: Colors.green, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPeriod,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                )
                    : const Text(
                  'CREATE PAYROLL PERIOD',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(picked)) {
          _endDate = picked.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _createPeriod() async {
    if (_nameController.text.isEmpty) {
      _showError('Please enter a period name');
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      _showError('End date cannot be before start date');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final periodData = {
        "period_name": _nameController.text,
        "start_date": DateFormat('yyyy-MM-dd').format(_startDate),
        "end_date": DateFormat('yyyy-MM-dd').format(_endDate),
        "period_type": _selectedPeriodType,
      };

      final response = await http.post(
        Uri.parse("$_apiBaseUrl/payroll/periods"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(periodData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payroll period created successfully"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Go back to payroll page
      } else {
        _showError('Failed to create period: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error creating period: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}