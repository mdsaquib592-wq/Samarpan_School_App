import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardHome extends StatefulWidget {
  final String adminName;
  final String userRole;

  const DashboardHome({
    super.key,
    required this.adminName,
    required this.userRole,
  });

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final String _baseUrl = 'http://10.0.2.2:5000/api';
  bool _isLoading = true;

  // ==========================================
  // 🟢 STATE VARIABLES (API DATA)
  // ==========================================
  double totalFees = 0;
  int activeTeachers = 0;
  int totalStudents = 0;
  int activeCourses = 0;

  List<Map<String, dynamic>> lowAttendanceStudents = [];
  List<Map<String, dynamic>> todaysAbsentees = [];
  List<Map<String, dynamic>> recentEnrollments = [];

  Map<String, String> latestNotice = {
    "title": "📢 Updates",
    "message": "Fetching latest notices...",
  };

  Map<String, double> teacherAttendanceSummary = {
    "Present": 0,
    "Absent": 0,
    "On Leave": 0,
  };

  List<double> weeklyRevenueData = [0, 0, 0, 0, 0, 0];

  String mySubjects = "Loading...";
  List<Map<String, dynamic>> teacherCourseDetails = [];

  String adminMarqueeText =
      "Welcome to Samarpan School Management System! Stay updated with the latest alerts.";
  String teacherMarqueeText =
      "Welcome to Samarpan School Management System! Ensure all attendances are marked before 10:00 AM.";

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // ==========================================
  // 🌐 API CALLS (Safe Parsing & Instant UI Update)
  // ==========================================
  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.userRole.toLowerCase() == 'admin') {
        await Future.wait([
          _fetchStats(),
          _fetchLowAttendance(),
          _fetchTodaysAbsentees(),
          _fetchRecentEnrollments(),
          _fetchLatestNotice(),
          _fetchTeacherAttendanceSummary(),
          _fetchWeeklyRevenue(),
        ]);
      } else {
        await Future.wait([
          _fetchTodaysAbsentees(),
          _fetchLatestNotice(),
          _fetchTeacherCourses(),
        ]);
      }
    } catch (e) {
      debugPrint("Dashboard Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 1. Fetch Quick Stats (4 Top Cards)
  Future<void> _fetchStats() async {
    try {
      // Get Fees Collected Today
      final resFee = await http.get(
        Uri.parse('$_baseUrl/total-fees-collected'),
      );
      if (resFee.statusCode == 200) {
        final data = jsonDecode(resFee.body);
        if (data['success'] == true) {
          setState(() {
            totalFees =
                double.tryParse(data['totalCollected']?.toString() ?? '0') ?? 0;
          });
        }
      }

      // Get Active Teachers Count
      final resTeach = await http.get(
        Uri.parse('$_baseUrl/active-teachers-count'),
      );
      if (resTeach.statusCode == 200) {
        final data = jsonDecode(resTeach.body);
        if (data['success'] == true) {
          setState(() {
            activeTeachers =
                int.tryParse(data['count']?.toString() ?? '0') ?? 0;
          });
        }
      }

      // Get Total Students
      final resStu = await http.get(Uri.parse('$_baseUrl/students'));
      if (resStu.statusCode == 200) {
        final data = jsonDecode(resStu.body);
        if (data['success'] == true && data['students'] != null) {
          setState(() {
            totalStudents = (data['students'] as List).length;
          });
        }
      }

      // Get Active Courses
      final resCour = await http.get(Uri.parse('$_baseUrl/courses'));
      if (resCour.statusCode == 200) {
        final data = jsonDecode(resCour.body);
        if (data['success'] == true && data['courses'] != null) {
          setState(() {
            activeCourses = (data['courses'] as List).length;
          });
        }
      }
    } catch (e) {
      debugPrint("Stats Error: $e");
    }
  }

  // 2. Fetch Low Attendance Students
  Future<void> _fetchLowAttendance() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/dashboard/low-attendance'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            lowAttendanceStudents = List<Map<String, dynamic>>.from(
              data['data'],
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Low Att Error: $e");
    }
  }

  // 3. Fetch Today's Absentees
  Future<void> _fetchTodaysAbsentees() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/dashboard/absent-students'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            todaysAbsentees = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint("Absentees Error: $e");
    }
  }

  // 4. Fetch Recent Enrollments
  Future<void> _fetchRecentEnrollments() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/dashboard/recent-enrollments'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            recentEnrollments = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint("Enrollment Error: $e");
    }
  }

  // 5. Fetch Latest Important Notice
  Future<void> _fetchLatestNotice() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/dashboard/latest-notice'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            latestNotice = {
              "title": data['data']['title']?.toString() ?? "📢 Notice",
              "message": data['data']['message']?.toString() ?? "",
            };
            adminMarqueeText =
                "Welcome to Samarpan School! Latest Update: ${latestNotice['title']}";
          });
        }
      }
    } catch (e) {
      debugPrint("Notice Error: $e");
    }
  }

  // 6. Fetch Teacher Attendance Summary for Pie Chart
  Future<void> _fetchTeacherAttendanceSummary() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/dashboard/teacher-attendance-summary'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['summary'] != null) {
          setState(() {
            teacherAttendanceSummary = {
              "Present":
                  double.tryParse(
                    data['summary']['Present']?.toString() ?? '0',
                  ) ??
                  0,
              "Absent":
                  double.tryParse(
                    data['summary']['Absent']?.toString() ?? '0',
                  ) ??
                  0,
              "On Leave":
                  double.tryParse(
                    data['summary']['On Leave']?.toString() ?? '0',
                  ) ??
                  0,
            };
          });
        }
      }
    } catch (e) {
      debugPrint("Teacher Att Summary Error: $e");
    }
  }

  // 7. Fetch Weekly Revenue Chart Data
  Future<void> _fetchWeeklyRevenue() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/fee-reports'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['barData'] != null) {
          List<dynamic> bar = data['barData'];
          List<double> vals = [];
          for (int i = 0; i < 6; i++) {
            if (i < bar.length) {
              vals.add(
                (double.tryParse(bar[i]['amount'].toString()) ?? 0) / 10000,
              );
            } else {
              vals.add(0);
            }
          }
          setState(() {
            weeklyRevenueData = vals;
          });
        }
      }
    } catch (e) {
      setState(() {
        weeklyRevenueData = [0, 0, 0, 0, 0, 0];
      });
    }
  }

  // 8. Fetch Teacher Specific Courses
  Future<void> _fetchTeacherCourses() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      mySubjects = "Subject Data Pending...";
      teacherCourseDetails = [
        {
          "id": "1",
          "chapter": "Check Courses Tab for updates",
          "status": "Ongoing",
        },
      ];
    });
  }

  // ==========================================
  // 📱 UI METHODS
  // ==========================================
  void handleSendWhatsApp(String studentName, String className, String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action: Send reminder to $studentName at $phone'),
        backgroundColor: const Color(0xFF25D366),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF0B1120);
    const Color cardColor = Color(0xFF161E2E);

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          // 🌌 Background Glow
          Positioned(
            top: -50,
            left: -50,
            child: _buildGlow(const Color(0x153EE7C9)),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _buildGlow(const Color(0x159C3CFB)),
          ),

          // 🪐 Main Content
          Positioned.fill(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3EE7C9)),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopHeader(),
                        const SizedBox(height: 25),
                        _buildMarqueeBar(cardColor),
                        const SizedBox(height: 25),

                        if (widget.userRole.toLowerCase() == 'teacher')
                          _buildTeacherView(cardColor)
                        else
                          _buildAdminView(cardColor),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 👨‍🏫 TEACHER VIEW
  // ==========================================
  Widget _buildTeacherView(Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.2,
          children: [
            _buildDarkStatCard(
              "My Subjects",
              mySubjects,
              Icons.menu_book,
              const Color(0xFF3B82F6),
              cardColor,
              isSmall: true,
            ),
            _buildDarkStatCard(
              "Class Absentees",
              "${todaysAbsentees.length}",
              Icons.person_off,
              const Color(0xFFEF4444),
              cardColor,
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildNoticeCard(cardColor),
        const SizedBox(height: 30),

        _buildTeacherCourseDetails(cardColor),
        const SizedBox(height: 20),

        _buildTodaysAbsenteesBox(cardColor),
        const SizedBox(height: 40),
      ],
    );
  }

  // ==========================================
  // 👨‍💼 ADMIN VIEW
  // ==========================================
  Widget _buildAdminView(Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // STATS GRID
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.2,
          children: [
            _buildDarkStatCard(
              "Total Students",
              "$totalStudents",
              Icons.people_outline,
              const Color(0xFF3B82F6),
              cardColor,
            ),
            _buildDarkStatCard(
              "Active Teachers",
              "$activeTeachers",
              Icons.person_pin_outlined,
              const Color(0xFF9C3CFB),
              cardColor,
            ),
            _buildDarkStatCard(
              "Active Courses",
              "$activeCourses",
              Icons.menu_book_outlined,
              const Color(0xFF3EE7C9),
              cardColor,
            ),
            _buildDarkStatCard(
              "Today's Collection",
              "₹${totalFees.toStringAsFixed(0)}",
              Icons.savings_outlined,
              const Color(0xFF10B981),
              cardColor,
              isSmall: true,
            ),
          ],
        ),
        const SizedBox(height: 15),

        // NOTICE CARD
        _buildNoticeCard(cardColor),
        const SizedBox(height: 30),

        // WEEKLY REVENUE BAR CHART
        const Text(
          "Monthly Revenue Overview (in 10Ks)",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 15),
        _buildWeeklyRevenueChart(cardColor),
        const SizedBox(height: 30),

        // ALERTS BOX
        _buildAdminAttendanceAlerts(cardColor),
        const SizedBox(height: 20),

        // PIE CHART
        _buildTeacherAttendancePieChart(cardColor),
        const SizedBox(height: 20),

        // ENROLLMENT TABLE
        _buildRecentEnrollmentsTable(cardColor),
        const SizedBox(height: 80),
      ],
    );
  }

  // ==========================================
  // 🧩 REUSABLE WIDGETS
  // ==========================================

  Widget _buildTopHeader() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFA1E3F9), Color(0xFFC094E0)],
            ),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back, ${widget.adminName.toUpperCase()}! 👋",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.userRole.toLowerCase() == 'teacher'
                    ? "Teacher Dashboard"
                    : "Admin Dashboard",
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarqueeBar(Color cardColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_outlined,
            color: Color(0xFFEAB308),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "⚠️ ${widget.userRole.toLowerCase() == 'teacher' ? teacherMarqueeText : adminMarqueeText}",
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEAB308),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color cardColor, {
    bool isSmall = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.15),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmall ? 15 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF451A03),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFFF59E0B), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  latestNotice['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            latestNotice['message'] ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyRevenueChart(Color cardColor) {
    BarChartRodData makeRod(double y) {
      return BarChartRodData(
        toY: y,
        gradient: const LinearGradient(
          colors: [Color(0xFF87E6D0), Color(0xFFC094E0)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        width: 14,
        borderRadius: BorderRadius.circular(4),
        backDrawRodData: BackgroundBarChartRodData(
          show: true,
          toY: 20,
          color: Colors.white.withOpacity(0.03),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 30, right: 15, left: 15, bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 20,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    (val.toInt() < 6) ? 'M${val.toInt() + 1}' : '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (val) =>
                FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (int i = 0; i < weeklyRevenueData.length; i++)
              BarChartGroupData(x: i, barRods: [makeRod(weeklyRevenueData[i])]),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherCourseDetails(Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📚 Course Details (Recent Chapters)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          ...teacherCourseDetails.map(
            (course) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      course['chapter'],
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  _buildCourseBadge(course['status']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysAbsenteesBox(Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "⚠️ Today's Absentees (Action Required)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          if (todaysAbsentees.isEmpty)
            const Text(
              "No students absent today.",
              style: TextStyle(color: Colors.white54),
            )
          else
            ...todaysAbsentees.map(
              (student) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          student['class']?.toString() ?? '',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    _whatsappButton(student),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminAttendanceAlerts(Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "⚠️ Student Attendance Alerts",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            "Low Attendance Warning (< 75%)",
            style: TextStyle(
              color: Colors.red.shade400,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Divider(color: Colors.white10, height: 20),
          if (lowAttendanceStudents.isEmpty)
            const Text(
              "No low attendance alerts.",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else
            ...lowAttendanceStudents.map(
              (student) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${student['name']} (${student['class']})",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${student['attendance_percent']}%",
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 25),

          Text(
            "Today's Absentees (Action Required)",
            style: TextStyle(
              color: Colors.blue.shade400,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Divider(color: Colors.white10, height: 20),
          if (todaysAbsentees.isEmpty)
            const Text(
              "No students absent today.",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else
            ...todaysAbsentees.map(
              (student) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${student['name']} (${student['class']})",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    _whatsappButton(student),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeacherAttendancePieChart(Color cardColor) {
    double total =
        teacherAttendanceSummary["Present"]! +
        teacherAttendanceSummary["Absent"]! +
        teacherAttendanceSummary["On Leave"]!;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "Teacher Attendance Summary\nNo data recorded today.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Teacher Attendance Summary",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: const Color(0xFF10B981),
                    value: teacherAttendanceSummary["Present"]!,
                    title: "P",
                    radius: 30,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFFEF4444),
                    value: teacherAttendanceSummary["Absent"]!,
                    title: "A",
                    radius: 30,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFFF59E0B),
                    value: teacherAttendanceSummary["On Leave"]!,
                    title: "L",
                    radius: 30,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEnrollmentsTable(Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Enrollments",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          if (recentEnrollments.isEmpty)
            const Text(
              "No recent enrollments.",
              style: TextStyle(color: Colors.white54),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                dataTextStyle: const TextStyle(color: Colors.white70),
                dividerThickness: 0.5,
                columns: const [
                  DataColumn(label: Text('Student')),
                  DataColumn(label: Text('Class')),
                  DataColumn(label: Text('Status')),
                ],
                rows: recentEnrollments.map((student) {
                  return DataRow(
                    cells: [
                      DataCell(Text(student['name'] ?? '')),
                      DataCell(Text(student['class']?.toString() ?? '')),
                      DataCell(
                        _buildPaymentBadge(student['status'] ?? 'Pending'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseBadge(String status) {
    Color bgColor, textColor;
    if (status == "Completed") {
      bgColor = const Color(0xFF10B981).withOpacity(0.15);
      textColor = const Color(0xFF10B981);
    } else if (status == "Ongoing") {
      bgColor = const Color(0xFF3B82F6).withOpacity(0.15);
      textColor = const Color(0xFF3B82F6);
    } else {
      bgColor = Colors.white.withOpacity(0.1);
      textColor = Colors.white70;
    }
    return _badgeContainer(status, bgColor, textColor);
  }

  Widget _buildPaymentBadge(String status) {
    bool isPaid = status.toLowerCase() == "paid";
    Color bgColor = isPaid
        ? const Color(0xFF10B981).withOpacity(0.15)
        : const Color(0xFFF59E0B).withOpacity(0.15);
    Color textColor = isPaid
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    return _badgeContainer(status, bgColor, textColor);
  }

  Widget _badgeContainer(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor, width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _whatsappButton(Map<String, dynamic> student) {
    return InkWell(
      onTap: () => handleSendWhatsApp(
        student['name'] ?? '',
        student['class']?.toString() ?? '',
        student['phone']?.toString() ?? '',
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366).withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF25D366).withOpacity(0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wechat, color: Color(0xFF25D366), size: 14),
            SizedBox(width: 4),
            Text(
              "WhatsApp",
              style: TextStyle(
                color: Color(0xFF25D366),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlow(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(blurRadius: 100, color: color)],
      ),
    );
  }
}
