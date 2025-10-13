import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'Employees/department_management_page.dart';
import 'Employees/employee_management_page.dart'; // For date formatting
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'Employees/payroll_processing_page.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Content for $title')),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryColor = Color(0xFF4A90E2); // A professional blue
  static const Color accentColor = Color(0xFF50E3C2); // A complementary accent
  static const Color backgroundColor = Color(0xFFF4F6F8);
  static const Color cardBackgroundColor = Colors.white;
  static const Color textColor = Color(0xFF333333);
  static const Color subtleTextColor = Color(0xFF757575);
  static const Color iconColor = primaryColor;

  double _totalPayrollLastMonth = 75320.50;
  String _nextPayDate = '';
  double _ytdExpenses = 450123.75;
  int _employeeCount = 0; // start with 0
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchEmployeeCount();
    _calculateNextPayDate();
  }

  Future<void> _refreshAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _fetchEmployeeCount(),
        _fetchPayrollData(),
        _fetchYTDExpenses(),
      ]);

      _calculateNextPayDate();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data refreshed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("⚠️ Error refreshing data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error refreshing data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEmployeeCount() async {
    try {
      final response = await http.get(
          Uri.parse("http://localhost:3000/api/employees/count")
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _employeeCount = data['count'];
        });
      } else {
        throw Exception("Failed to fetch employee count");
      }
    } catch (e) {
      print("⚠️ Error fetching employee count: $e");
      // Don't show error snackbar here to avoid multiple snackbars during refresh
    }
  }

  Future<void> _fetchPayrollData() async {
    // Simulate fetching updated payroll data
    // Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _totalPayrollLastMonth = 75320.50 + (DateTime.now().millisecond % 1000); // Simulate data change
    });
  }

  Future<void> _fetchYTDExpenses() async {
    // Simulate fetching updated YTD expenses
    // Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _ytdExpenses = 450123.75 + (DateTime.now().millisecond % 5000); // Simulate data change
    });
  }

  void _calculateNextPayDate() {
    // Calculate next pay date (e.g., next Friday)
    DateTime now = DateTime.now();
    int daysUntilNextFriday = DateTime.friday - now.weekday;
    if (daysUntilNextFriday <= 0) {
      daysUntilNextFriday += 7;
    }
    DateTime nextPayDate = now.add(Duration(days: daysUntilNextFriday));

    setState(() {
      _nextPayDate = DateFormat('MMMM dd, yyyy').format(nextPayDate);
    });
  }

  void _navigateToEmployees(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeManagementPage()));
  }

  void _navigateToDepartments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DepartmentManagementPage()),
    );
  }

  void _navigateToPayroll(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PayrollProcessingPage())
    );
  }

  void _navigateToReports(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderPage(title: "View Reports")));
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderPage(title: "Settings")));
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/login'); // Assuming you have a '/login' route
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logged out successfully"))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Salary System Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 2.0,
        iconTheme: const IconThemeData(color: Colors.white), // For drawer icon
        actions: [
          IconButton(
            icon: _isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: _isLoading ? null : _refreshAllData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              // TODO: Implement notifications view
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Implement user profile view
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildDashboardBody(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToPayroll(context),
        icon: const Icon(Icons.payments_outlined, color: Colors.white),
        label: const Text('RUN PAYROLL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: accentColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: const Text("Admin User", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            accountEmail: const Text("admin@example.com", style: TextStyle(color: Colors.white70)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                "A",
                style: TextStyle(fontSize: 40.0, color: primaryColor),
              ),
            ),
            decoration: BoxDecoration(
              color: primaryColor,
            ),
          ),
          _buildDrawerItem(Icons.dashboard_outlined, 'Dashboard', () => Navigator.pop(context)),
          _buildDrawerItem(Icons.people_alt_outlined, 'Manage Employees', () {
            Navigator.pop(context); _navigateToEmployees(context);
          }),
          _buildDrawerItem(Icons.apartment_outlined, 'Manage Departments', () {
            Navigator.pop(context);
            _navigateToDepartments(context);
          }),
          _buildDrawerItem(Icons.request_quote_outlined, 'Payroll Processing', () {
            Navigator.pop(context); _navigateToPayroll(context);
          }),
          _buildDrawerItem(Icons.bar_chart_outlined, 'Reports', () {
            Navigator.pop(context); _navigateToReports(context);
          }),
          const Divider(),
          _buildDrawerItem(Icons.settings_outlined, 'Settings', () {
            Navigator.pop(context); _navigateToSettings(context);
          }),
          _buildDrawerItem(Icons.exit_to_app_outlined, 'Logout', () {
            Navigator.pop(context); _logout(context);
          }),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: iconColor.withOpacity(0.8)),
      title: Text(title, style: const TextStyle(color: textColor, fontSize: 15)),
      onTap: onTap,
    );
  }

  Widget _buildDashboardBody(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(), // Required for RefreshIndicator
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Welcome, Admin!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Here is a summary of your salary system.',
              style: TextStyle(fontSize: 16, color: subtleTextColor),
            ),
            const SizedBox(height: 24),

            // --- Summary Metrics Grid ---
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                _buildSummaryCard(
                  context,
                  icon: Icons.groups_outlined,
                  title: 'Active Employees',
                  value: _employeeCount.toString(),
                  color: Colors.blue.shade400,
                  onTap: () => _navigateToEmployees(context),
                ),
                _buildSummaryCard(
                  context,
                  icon: Icons.payments_outlined,
                  title: 'Last Month Payroll',
                  value: '₹${NumberFormat("#,##0.00", "en_IN").format(_totalPayrollLastMonth)}',
                  color: Colors.green.shade400,
                ),
                _buildSummaryCard(
                  context,
                  icon: Icons.event_available_outlined,
                  title: 'Next Pay Date',
                  value: _nextPayDate,
                  color: Colors.orange.shade400,
                ),
                _buildSummaryCard(
                  context,
                  icon: Icons.trending_up_outlined,
                  title: 'YTD Salary Expenses',
                  value: '₹${NumberFormat("#,##0.00", "en_IN").format(_ytdExpenses)}',
                  color: Colors.purple.shade400,
                  onTap: () => _navigateToReports(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Quick Actions Section ---
            _buildSectionTitle('Quick Actions'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildActionChip(context, Icons.person_add_alt_1_outlined, 'Add Employee', () => _navigateToEmployees(context)),
                _buildActionChip(context, Icons.receipt_long_outlined, 'Generate Payslips', () => _navigateToPayroll(context)),
                _buildActionChip(context, Icons.summarize_outlined, 'View Tax Report', () => _navigateToReports(context)),
              ],
            ),
            const SizedBox(height: 24),

            // --- Placeholder for a Chart ---
            _buildSectionTitle('Salary Expense Trend (Monthly)'),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Chart Placeholder\n(e.g., using fl_chart or charts_flutter)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subtleTextColor, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 60), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {required IconData icon, required String title, required String value, Color? color, VoidCallback? onTap}) {
    return Card(
      elevation: 2.0,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: (color ?? primaryColor).withOpacity(0.15),
                radius: 20,
                child: Icon(icon, color: color ?? iconColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 14, color: subtleTextColor),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ActionChip(
          avatar: Icon(icon, color: primaryColor, size: 20),
          label: Text(label, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500, fontSize: 13)),
          onPressed: onPressed,
          backgroundColor: primaryColor.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: primaryColor.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }
}