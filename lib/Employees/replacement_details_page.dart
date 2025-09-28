import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../ReplacementRecord.dart';
import 'deactivated_employees_page.dart';

class ReplacementDetailsPage extends StatelessWidget {
  final ReplacementRecord replacement;
  final String apiBaseUrl = "http://localhost:3000/api";

  const ReplacementDetailsPage({super.key, required this.replacement});

  Future<Employee?> _fetchEmployeeById(String employeeId) async {
    try {
      final response = await http.get(Uri.parse("$apiBaseUrl/employees/$employeeId"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Employee(
          id: data['id'].toString(),
          name: data['name'] ?? '',
          position: data['designation'] ?? '',
          department: data['department'] ?? '',
          joinDate: data['registerDate'] ?? '',
        );
      }
    } catch (e) {
      debugPrint('Error loading employee: $e');
    }
    return null;
  }

  void _viewEmployeeDetails(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(employee.name, style: const TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow('Employee ID:', employee.id),
                _buildDetailRow('Position:', employee.position),
                _buildDetailRow('Department:', employee.department),
                _buildDetailRow('Joined On:', employee.joinDate),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildChainNavigation(BuildContext context) {
    return FutureBuilder<Map<String, ReplacementRecord?>>(
      future: _fetchAdjacentReplacements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(); // Or a loading indicator
        }

        final previous = snapshot.data?['previous'];
        final next = snapshot.data?['next'];

        return Row(
          children: [
            if (previous != null)
              Expanded(
                child: Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReplacementDetailsPage(replacement: previous),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Previous Replacement', style: TextStyle(fontSize: 12)),
                                Text(previous.replacementDate, style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (previous != null && next != null) SizedBox(width: 8),
            if (next != null)
              Expanded(
                child: Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReplacementDetailsPage(replacement: next),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Next Replacement', style: TextStyle(fontSize: 12)),
                                Text(next.replacementDate, style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<Map<String, ReplacementRecord?>> _fetchAdjacentReplacements() async {
    try {
      final response = await http.get(Uri.parse("$apiBaseUrl/replacements/${replacement.id}/adjacent"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'previous': data['previous'] != null ? ReplacementRecord.fromJson(data['previous']) : null,
          'next': data['next'] != null ? ReplacementRecord.fromJson(data['next']) : null,
        };
      }
    } catch (e) {
      debugPrint('Error fetching adjacent replacements: $e');
    }
    return {'previous': null, 'next': null};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Replacement Details', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4A90E2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 40, color: Colors.blue.shade700),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Replacement Record',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            replacement.replacementDate,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Replacement Information
            const Text(
              'Replacement Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (replacement.oldEmployeeName != null)
                      _buildInfoRow('Replaced Employee:', replacement.oldEmployeeName!),
                    if (replacement.newEmployeeName != null)
                      _buildInfoRow('New Employee:', replacement.newEmployeeName!),
                    _buildInfoRow('Replacement Date:', replacement.replacementDate),
                    _buildInfoRow('Reason:', replacement.reason),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Actions Section
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (replacement.oldEmployeeId != null)
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final employee = await _fetchEmployeeById(replacement.oldEmployeeId);
                          if (employee != null && context.mounted) {
                            _viewEmployeeDetails(context, employee);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(Icons.person_outline, color: Colors.orange.shade700),
                              const SizedBox(height: 8),
                              const Text(
                                'View Old Employee',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (replacement.oldEmployeeId != null && replacement.newEmployeeId != null)
                  const SizedBox(width: 16),
                if (replacement.newEmployeeId != null)
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final employee = await _fetchEmployeeById(replacement.newEmployeeId);
                          if (employee != null && context.mounted) {
                            _viewEmployeeDetails(context, employee);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(Icons.person, color: Colors.green.shade700),
                              const SizedBox(height: 8),
                              const Text(
                                'View New Employee',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // Additional Information
            const Text(
              'Record Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('Record ID:', replacement.id),
                    _buildInfoRow('Old Employee ID:', replacement.oldEmployeeId),
                    _buildInfoRow('New Employee ID:', replacement.newEmployeeId),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildChainNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: TextStyle(
                color: value.isNotEmpty ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
