import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final String _baseUrl = 'http://10.0.2.2:5000/api';
  bool _isLoading = false;

  // Today's State
  List<dynamic> _attendanceData = [];
  String _searchQuery = '';

  // History State
  bool _viewHistoryMode = false;
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _historicalAttendance = [];

  @override
  void initState() {
    super.initState();
    _fetchTodayAttendance();
  }

  // ==========================================
  // API FUNCTIONS
  // ==========================================
  Future<void> _fetchTodayAttendance() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/attendance/today'));
      if (response.statusCode == 200) {
        setState(() {
          _attendanceData = jsonDecode(response.body) ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching today's attendance: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchHistoricalAttendance(String dateStr) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/attendance?date=$dateStr'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _historicalAttendance = jsonDecode(response.body) ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error fetching records."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAttendance(String teacherId, String status) async {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/attendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "teacher_id": teacherId,
          "status": status,
          "attendance_date": todayStr,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Attendance marked as $status"),
            backgroundColor: status == 'Present'
                ? Colors.green
                : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchTodayAttendance();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Server Error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF059669)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      final dateStr = picked.toIso8601String().split('T')[0];
      _fetchHistoricalAttendance(dateStr);
    }
  }

  Widget _attendanceBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎛️ TOP HEADER
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Staff Directory",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Attendance",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.event_available_rounded,
                  size: 36,
                  color: Color(0xFF059669),
                ),
              ],
            ),
          ),

          // 🔀 TOGGLE BUTTONS (Today vs History)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _viewHistoryMode = false);
                        _fetchTodayAttendance();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_viewHistoryMode
                              ? const Color(0xFF059669)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            "Today's Roster",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !_viewHistoryMode
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _viewHistoryMode = true);
                        _fetchHistoricalAttendance(
                          _selectedDate.toIso8601String().split('T')[0],
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _viewHistoryMode
                              ? const Color(0xFF059669)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            "View History",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _viewHistoryMode
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🚀 BODY CONTENT
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)),
                  )
                : _viewHistoryMode
                ? _buildHistoryView(isDark)
                : _buildTodayView(isDark),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 1: TODAY'S ROSTER
  // ==========================================
  Widget _buildTodayView(bool isDark) {
    List<dynamic> filteredAttendance = _attendanceData.where((t) {
      final search = _searchQuery.toLowerCase();
      final name = (t['name'] ?? '').toString().toLowerCase();
      final id = (t['id'] ?? '').toString().toLowerCase();
      return name.contains(search) || id.contains(search);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade300,
              ),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Search Roster...",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: Color(0xFF059669)),
              ),
            ),
          ),
        ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          child: Text(
            DateTime.now().toIso8601String().split('T')[0],
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Expanded(
          child: filteredAttendance.isEmpty
              ? const Center(child: Text("No records found for today."))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredAttendance.length,
                  itemBuilder: (context, i) {
                    final t = filteredAttendance[i];
                    final isMarked = t['attendance_status'] != null;
                    final status = t['attendance_status'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade200,
                        ),
                        boxShadow: !isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isDark
                                ? const Color(0xFF0F172A)
                                : Colors.grey.shade100,
                            child: Text(
                              (t['name'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['name'] ?? 'N/A',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  t['id'] ?? 'N/A',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isMarked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: status == 'Present'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: status == 'Present'
                                      ? Colors.green
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                _attendanceBtn(
                                  Icons.check_rounded,
                                  Colors.green,
                                  () => _markAttendance(
                                    t['id'].toString(),
                                    'Present',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _attendanceBtn(
                                  Icons.close_rounded,
                                  Colors.redAccent,
                                  () => _markAttendance(
                                    t['id'].toString(),
                                    'Absent',
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 2: HISTORY
  // ==========================================
  Widget _buildHistoryView(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: InkWell(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Selected Date: ${_selectedDate.toIso8601String().split('T')[0]}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Icon(Icons.calendar_month, color: Colors.blueAccent),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),

        Expanded(
          child: _historicalAttendance.isEmpty
              ? const Center(child: Text("No records found for selected date."))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _historicalAttendance.length,
                  itemBuilder: (context, i) {
                    final rec = _historicalAttendance[i];
                    final status = rec['status'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isDark
                                ? const Color(0xFF0F172A)
                                : Colors.grey.shade100,
                            child: Text(
                              (rec['teacher_name'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rec['teacher_name'] ?? 'N/A',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  rec['teacher_id'] ?? 'N/A',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'Present'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: status == 'Present'
                                    ? Colors.green
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
