import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';


const Color _formPagePrimaryColor = Color(0xFF4A90E2);
const Color _formPageAccentColor = Color(0xFF50E3C2);
const Color _formPageTextColor = Color(0xFF333333);


class AddEditEmployeePage extends StatefulWidget {
  final String? employeeId;

  const AddEditEmployeePage({super.key, this.employeeId});

  @override
  State<AddEditEmployeePage> createState() => _AddEditEmployeePageState();
}

class _AddEditEmployeePageState extends State<AddEditEmployeePage> {
  final _formKey = GlobalKey<FormState>();
 static const String _apiBaseUrl = "http://localhost:3000/api";

  // --- Text Editing Controllers ---
  final _registerDateController = TextEditingController();
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _educationController = TextEditingController();
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();
  final _salaryController = TextEditingController();
  final _referenceController = TextEditingController();
  final _idCardNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  DateTime? _selectedRegisterDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.employeeId != null) {
      // This is Edit mode
      // TODO: Fetch existing employee data based on widget.employeeId and populate controllers
      _loadEmployeeData(widget.employeeId!);
    } else {
      // Add mode - set initial registration date to today
      _selectedRegisterDate = DateTime.now();
      _registerDateController.text = DateFormat('yyyy-MM-dd').format(_selectedRegisterDate!);
    }
  }

  Future<List<String>> _fetchDepartments(String query) async {
    final response = await http.get(Uri.parse("$_apiBaseUrl/departments"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((dept) => dept["name"].toString())
          .where((name) => name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      throw Exception("Failed to load departments");
    }
  }

  Future<void> _loadEmployeeData(String employeeId) async {
    try {
      final url = Uri.parse("$_apiBaseUrl/employees/$employeeId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _registerDateController.text = data['registerDate'] ?? '';
          _nameController.text = data['name'] ?? '';
          _fatherNameController.text = data['fatherName'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _educationController.text = data['education'] ?? '';
          _designationController.text = data['designation'] ?? '';
          _departmentController.text = data['department'] ?? '';
          _salaryController.text = data['salary']?.toString() ?? '';
          _referenceController.text = data['reference'] ?? '';
          _idCardNumberController.text = data['idCardNumber'] ?? '';
          _addressController.text = data['address'] ?? '';
          _phoneNumberController.text = data['phoneNumber'] ?? '';

          if (data['registerDate'] != null && data['registerDate'].toString().isNotEmpty) {
            try {
              _selectedRegisterDate = DateTime.parse(data['registerDate']);
            } catch (_) {
              _selectedRegisterDate = null;
            }
          }
        });
      } else {
        throw Exception("Failed to load employee");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading employee: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _registerDateController.dispose();
    _nameController.dispose();
    _fatherNameController.dispose();
    _ageController.dispose();
    _educationController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    _salaryController.dispose();
    _referenceController.dispose();
    _idCardNumberController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectRegisterDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedRegisterDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Allow future dates slightly if needed
    );
    if (picked != null && picked != _selectedRegisterDate) {
      setState(() {
        _selectedRegisterDate = picked;
        _registerDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final employeeData = {
        'registerDate': _registerDateController.text,
        'name': _nameController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),
        'age': _ageController.text.trim(),
        'education': _educationController.text.trim(),
        'designation': _designationController.text.trim(),
        'department': _departmentController.text.trim(),
        'salary': _salaryController.text.trim(),
        'reference': _referenceController.text.trim(),
        'idCardNumber': _idCardNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
      };

      try {
        late http.Response response;

        if (widget.employeeId == null) {
          // --- Add employee ---
          final url = Uri.parse("$_apiBaseUrl/employees");
          response = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(employeeData),
          );
        } else {
          // --- Update existing employee ---
          final url = Uri.parse("$_apiBaseUrl/employees/${widget.employeeId}");
          response = await http.put(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(employeeData),
          );
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.employeeId == null
                    ? 'Employee added successfully!'
                    : 'Employee updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        } else {
          throw Exception("Failed: ${response.statusCode} ${response.body}");
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.employeeId == null ? 'Add New Employee' : 'Edit Employee Details',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _formPagePrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // --- Personal Information Section ---
                _buildSectionTitle('Personal Information'),
                _buildDateField(
                  controller: _registerDateController,
                  label: 'Registration Date*',
                  onTap: () => _selectRegisterDate(context),
                ),
                _buildTextFormField(
                  controller: _nameController,
                  label: 'Full Name*',
                  icon: Icons.person_outline,
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter name' : null,
                ),
                _buildTextFormField(
                  controller: _fatherNameController,
                  label: "Father's Name",
                  icon: Icons.person_outline,
                ),
                _buildTextFormField(
                  controller: _ageController,
                  label: 'Age',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                _buildTextFormField(
                  controller: _idCardNumberController,
                  label: 'ID Card Number*',
                  icon: Icons.badge_outlined,
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter ID card number' : null,
                ),

                // --- Contact Information Section ---
                const SizedBox(height: 20),
                _buildSectionTitle('Contact Information'),
                _buildTextFormField(
                  controller: _phoneNumberController,
                  label: 'Phone Number*',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter phone number';
                    if (value.length < 10) return 'Enter a valid phone number'; // Basic check
                    return null;
                  },
                ),
                _buildTextFormField(
                  controller: _addressController,
                  label: 'Address',
                  icon: Icons.location_on_outlined,
                  maxLines: 3,
                ),

                // --- Professional Information Section ---
                const SizedBox(height: 20),
                _buildSectionTitle('Professional Information'),
                _buildTextFormField(
                  controller: _educationController,
                  label: 'Education',
                  icon: Icons.school_outlined,
                ),
                _buildTextFormField(
                  controller: _designationController,
                  label: 'Designation*',
                  icon: Icons.work_outline,
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter designation' : null,
                ),
                // _buildTextFormField(
                //   controller: _departmentController,
                //   label: 'Department*',
                //   icon: Icons.business_outlined,
                //   validator: (value) => (value == null || value.isEmpty) ? 'Please enter department' : null,
                // ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TypeAheadFormField<String>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _departmentController,
                      decoration: InputDecoration(
                        labelText: 'Department*',
                        prefixIcon: const Icon(Icons.business_outlined, color: _formPagePrimaryColor),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                      ),
                    ),
                    suggestionsCallback: (pattern) async {
                      return await _fetchDepartments(pattern);
                    },
                    itemBuilder: (context, String suggestion) {
                      return ListTile(title: Text(suggestion));
                    },
                    onSuggestionSelected: (String suggestion) {
                      _departmentController.text = suggestion;
                    },
                    validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please select department' : null,
                  ),
                ),

                _buildTextFormField(
                  controller: _salaryController,
                  label: 'Salary (Monthly)*',
                  icon: Icons.attach_money_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter salary';
                    if (double.tryParse(value) == null) return 'Enter a valid salary';
                    return null;
                  },
                ),
                _buildTextFormField(
                  controller: _referenceController,
                  label: 'Reference (Optional)',
                  icon: Icons.record_voice_over_outlined,
                ),

                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  icon: Icon(widget.employeeId == null ? Icons.person_add_alt_1_outlined : Icons.save_outlined, color: Colors.white),
                  label: Text(widget.employeeId == null ? 'ADD EMPLOYEE' : 'SAVE CHANGES', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: _saveEmployee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _formPageAccentColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _formPagePrimaryColor,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Select Date',
          prefixIcon: const Icon(Icons.calendar_today_outlined, color: _formPagePrimaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
        ),
        onTap: onTap,
        validator: validator ?? (value) => (value == null || value.isEmpty) ? 'Please select $label' : null,
        style: const TextStyle(color: _formPageTextColor),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: _formPagePrimaryColor.withOpacity(0.8)) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
        ),
        validator: validator,
        maxLines: maxLines,
        style: const TextStyle(color: _formPageTextColor),
      ),
    );
  }
}


