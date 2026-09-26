import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'dashboard_home.dart';
import 'admission_screen.dart';
import 'students_list_screen.dart';
import 'courses_screen.dart';
import 'student_attendance_screen.dart';
import 'notices_screen.dart';
import 'fee_management_screen.dart';
import 'teacher_records_screen.dart';
import 'teacher_attendance_screen.dart';
import 'salary_management_screen.dart';
import 'recent_payouts_screen.dart';
import 'exam_schedule_screen.dart';
import 'exam_mark_entry_screen.dart';
import 'exam_result_view_screen.dart';
import 'reports_screen.dart';
import 'certificates_screen.dart';
import 'backup_screen.dart'; // 💾 NAYA IMPORT: Backup Screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _adminName = "User";
  String _userRole = "Admin";
  String _activeTab = "Dashboard";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminName = prefs.getString('adminName') ?? "Admin User";
      _userRole = prefs.getString('userRole') ?? "Admin";
    });
  }

  void _showLogoutPopup() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Text("🚪", style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(
              "Ready to Leave?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to logout from your account?",
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            child: const Text(
              "Cancel",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted)
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              "Yes, Logout",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String tabName) {
    final isSelected = _activeTab == tabName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? const Color(0xFF059669)
              : (isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF059669)
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        selected: isSelected,
        selectedTileColor: isDark
            ? const Color(0xFF059669).withValues(alpha: 0.15)
            : const Color(0xFF059669).withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          setState(() => _activeTab = tabName);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildExpandableMenu(
    IconData icon,
    String title,
    List<String> childTabs,
    List<Widget> children,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpandedOrSelected = childTabs.contains(_activeTab);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpandedOrSelected,
          leading: Icon(
            icon,
            color: isExpandedOrSelected
                ? const Color(0xFF059669)
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isExpandedOrSelected
                  ? FontWeight.bold
                  : FontWeight.w500,
              color: isExpandedOrSelected
                  ? const Color(0xFF059669)
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Samarpan Vidyalaya",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            color: isDark ? Colors.amber : Colors.blueGrey,
            onPressed: () {
              final newTheme = isDark ? ThemeMode.light : ThemeMode.dark;
              SamarpanApp.of(context)?.changeTheme(newTheme);
            },
          ),
          const SizedBox(width: 5),
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF059669),
              radius: 16,
              child: Text(
                _adminName.isNotEmpty ? _adminName[0].toUpperCase() : "U",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    isDark ? 'assets/night.png' : 'assets/SAMARPAN-LOGO.png',
                    width: 65,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _adminName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF059669,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _userRole.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                children: [
                  _buildDrawerItem(
                    Icons.dashboard_rounded,
                    "Dashboard",
                    "Dashboard",
                  ),
                  _buildDrawerItem(
                    Icons.person_add_alt_1_rounded,
                    "Admission",
                    "Admission",
                  ),
                  _buildDrawerItem(
                    Icons.people_alt_rounded,
                    "Students",
                    "Students",
                  ),
                  _buildDrawerItem(
                    Icons.event_available_rounded,
                    "Student Attendance",
                    "Attendance",
                  ),

                  _buildExpandableMenu(
                    Icons.badge_rounded,
                    "Teacher Management",
                    [
                      "TeacherRecords",
                      "TeacherAttendance",
                      "SalaryManagement",
                      "RecentPayouts",
                    ],
                    [
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: _buildDrawerItem(
                          Icons.list_alt_rounded,
                          "Records",
                          "TeacherRecords",
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: _buildDrawerItem(
                          Icons.event_available_rounded,
                          "Attendance",
                          "TeacherAttendance",
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: _buildDrawerItem(
                          Icons.payments_rounded,
                          "Salary Management",
                          "SalaryManagement",
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: _buildDrawerItem(
                          Icons.history_rounded,
                          "Recent Payouts",
                          "RecentPayouts",
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 15),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 5),
                    child: Text(
                      "ACADEMICS & FINANCE",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  _buildDrawerItem(
                    Icons.auto_stories_rounded,
                    "Courses",
                    "Courses",
                  ),
                  _buildDrawerItem(
                    Icons.schedule_rounded,
                    "Exam Schedule",
                    "ExamSchedule",
                  ),

                  _buildExpandableMenu(
                    Icons.grade_rounded,
                    "Exam Results",
                    ["ExamMarkEntry", "ExamResultView"],
                    [
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: _buildDrawerItem(
                          Icons.edit_note_rounded,
                          "Exam Mark Entry",
                          "ExamMarkEntry",
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: _buildDrawerItem(
                          Icons.fact_check_rounded,
                          "Result",
                          "ExamResultView",
                        ),
                      ),
                    ],
                  ),

                  _buildDrawerItem(
                    Icons.account_balance_wallet_rounded,
                    "Fee Management",
                    "Fees",
                  ),
                  _buildDrawerItem(
                    Icons.workspace_premium_rounded,
                    "Certificates & ID",
                    "Certificates",
                  ),

                  _buildExpandableMenu(
                    Icons.insert_chart_rounded,
                    "Reports & Analytics",
                    [
                      "StudentsReport",
                      "FeesReport",
                      "AttendanceReport",
                      "ExamsReport",
                    ],
                    [
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: _buildDrawerItem(
                          Icons.group_rounded,
                          "Students Report",
                          "StudentsReport",
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: _buildDrawerItem(
                          Icons.payments_rounded,
                          "Fees Report",
                          "FeesReport",
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: _buildDrawerItem(
                          Icons.event_available_rounded,
                          "Attendance Report",
                          "AttendanceReport",
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: _buildDrawerItem(
                          Icons.military_tech_rounded,
                          "Exams Report",
                          "ExamsReport",
                        ),
                      ),
                    ],
                  ),

                  _buildDrawerItem(
                    Icons.campaign_rounded,
                    "Notice Board",
                    "Notices",
                  ),

                  const Divider(height: 30),
                  _buildDrawerItem(
                    Icons.security_rounded,
                    "Database Backup",
                    "Backup",
                  ), // 💾 BACKUP LINK ADDED
                  _buildDrawerItem(
                    Icons.help_outline_rounded,
                    "Help & Support",
                    "Help",
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                tileColor: Colors.redAccent.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: _showLogoutPopup,
              ),
            ),
          ],
        ),
      ),
      body: _activeTab == "Dashboard"
          ? DashboardHome(adminName: _adminName, userRole: _userRole)
          : _activeTab == "Admission"
          ? const AdmissionScreen()
          : _activeTab == "Students"
          ? const StudentsListScreen()
          : _activeTab == "TeacherRecords"
          ? const TeacherRecordsScreen()
          : _activeTab == "TeacherAttendance"
          ? const TeacherAttendanceScreen()
          : _activeTab == "SalaryManagement"
          ? const SalaryManagementScreen()
          : _activeTab == "RecentPayouts"
          ? const RecentPayoutsScreen()
          : _activeTab == "Courses"
          ? const CoursesScreen()
          : _activeTab == "ExamSchedule"
          ? const ExamScheduleScreen()
          : _activeTab == "ExamMarkEntry"
          ? const ExamMarkEntryScreen()
          : _activeTab == "ExamResultView"
          ? const ExamResultViewScreen()
          : _activeTab == "Attendance"
          ? const StudentAttendanceScreen()
          : _activeTab == "Fees"
          ? const FeeManagementScreen()
          : _activeTab == "Certificates"
          ? const CertificatesScreen()
          : _activeTab == "StudentsReport"
          ? const ReportsScreen(reportType: "Students")
          : _activeTab == "FeesReport"
          ? const ReportsScreen(reportType: "Fees")
          : _activeTab == "AttendanceReport"
          ? const ReportsScreen(reportType: "Attendance")
          : _activeTab == "ExamsReport"
          ? const ReportsScreen(reportType: "Exams")
          : _activeTab == "Notices"
          ? const NoticesScreen()
          : _activeTab == "Backup"
          ? const BackupScreen() // 🟢 BACKUP SCREEN LINKED
          : const Center(child: Text("Under Construction")),
    );
  }
}
