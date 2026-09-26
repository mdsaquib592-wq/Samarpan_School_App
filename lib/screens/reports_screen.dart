import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportsScreen extends StatefulWidget {
  final String reportType; // Students, Fees, Attendance, or Exams

  const ReportsScreen({super.key, required this.reportType});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final String _baseUrl = 'http://10.0.2.2:5000/api';
  bool _isLoading = true;

  // ================= STATE VARIABLES (API DATA) =================
  List<Map<String, dynamic>> _studentReportData = [];
  List<Map<String, dynamic>> _feeReportData = [];
  List<Map<String, dynamic>> _attendanceReportData = [];
  List<Map<String, dynamic>> _examReportData = [];

  final List<String> _classes = [
    'Nursery',
    'LKG',
    'UKG',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSpecificReport();
  }

  // 🟢 NAYA: Sidebar se change hone par reload karne ke liye
  @override
  void didUpdateWidget(ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportType != widget.reportType) {
      _fetchSpecificReport();
    }
  }

  // 🚀 FETCH ONLY THE REQUIRED REPORT
  Future<void> _fetchSpecificReport() async {
    setState(() => _isLoading = true);
    try {
      if (widget.reportType == "Students") {
        await _fetchStudentsData();
      } else if (widget.reportType == "Fees") {
        await _fetchFeesData();
      } else if (widget.reportType == "Attendance") {
        await _fetchAttendanceData();
      } else if (widget.reportType == "Exams") {
        await _fetchExamsData();
      }
    } catch (e) {
      debugPrint("Error fetching reports: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 👥 1. FETCH TOTAL STUDENTS REPORT
  Future<void> _fetchStudentsData() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/students'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<dynamic> students = [];
        if (data is List)
          students = data;
        else if (data['students'] != null)
          students = data['students'];
        else if (data['data'] != null)
          students = data['data'];

        Map<String, Map<String, dynamic>> aggregated = {};

        for (var s in students) {
          String cls = (s['ClassName'] ?? s['className'] ?? 'Unknown')
              .toString();
          String gender = (s['Gender'] ?? s['gender'] ?? '')
              .toString()
              .toLowerCase();

          if (!aggregated.containsKey(cls)) {
            aggregated[cls] = {
              "class": cls,
              "section": "A",
              "boys": 0,
              "girls": 0,
              "total": 0,
            };
          }

          aggregated[cls]!['total'] += 1;
          if (gender == 'male' || gender == 'm') {
            aggregated[cls]!['boys'] += 1;
          } else if (gender == 'female' || gender == 'f') {
            aggregated[cls]!['girls'] += 1;
          }
        }

        List<Map<String, dynamic>> sortedList = [];
        for (String c in _classes) {
          if (aggregated.containsKey(c)) {
            sortedList.add(aggregated[c]!);
          }
        }
        _studentReportData = sortedList;
      }
    } catch (e) {
      debugPrint("Error fetching student reports: $e");
    }
  }

  // 💳 2. FETCH FEE COLLECTION REPORT
  Future<void> _fetchFeesData() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/all-students-fee-status'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          List<dynamic> feeStatusList = data['students'] ?? [];
          Map<String, Map<String, dynamic>> aggregated = {};

          for (var f in feeStatusList) {
            String cls = (f['class'] ?? 'Unknown').toString();
            double expected =
                double.tryParse(f['total_fee']?.toString() ?? '0') ?? 0;
            double collected =
                double.tryParse(f['amount_paid']?.toString() ?? '0') ?? 0;
            double pending = double.tryParse(f['dues']?.toString() ?? '0') ?? 0;

            if (!aggregated.containsKey(cls)) {
              aggregated[cls] = {
                "class": cls,
                "expected": 0.0,
                "collected": 0.0,
                "pending": 0.0,
              };
            }
            aggregated[cls]!['expected'] += expected;
            aggregated[cls]!['collected'] += collected;
            aggregated[cls]!['pending'] += pending;
          }

          List<Map<String, dynamic>> sortedList = [];
          for (String c in _classes) {
            if (aggregated.containsKey(c)) {
              sortedList.add(aggregated[c]!);
            }
          }
          _feeReportData = sortedList;
        }
      }
    } catch (e) {
      debugPrint("Error fetching fees report: $e");
    }
  }

  // 📅 3. FETCH MONTHLY ATTENDANCE REPORT
  Future<void> _fetchAttendanceData() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/dashboard/monthly-attendance'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          List<dynamic> monthlyList = data['data'] ?? [];
          _attendanceReportData = monthlyList.map((m) {
            double att =
                double.tryParse(m['attendance']?.toString() ?? '0') ?? 0;
            String status = att >= 90
                ? "Excellent"
                : (att >= 75 ? "Good" : "Average");
            return {
              "month": m['month']?.toString() ?? 'Unknown',
              "workingDays": 22,
              "avgAttendance": "${att.toStringAsFixed(1)}%",
              "status": status,
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching attendance report: $e");
    }
  }

  // 🏆 4. FETCH EXAM RESULTS REPORT
  Future<void> _fetchExamsData() async {
    try {
      List<Map<String, dynamic>> aggregated = [];
      for (String cls in _classes) {
        final res = await http.get(Uri.parse('$_baseUrl/get-results/$cls'));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['success'] == true &&
              data['results'] != null &&
              (data['results'] as List).isNotEmpty) {
            List<dynamic> results = data['results'];
            int appeared = results.length;
            int passed = 0;
            int failed = 0;

            for (var r in results) {
              bool isFail = false;
              List<String> subjects = [
                'maths',
                'science',
                'english',
                'social_science',
                'hindi',
                'computer',
                'gk',
                'drawing',
              ];
              for (var sub in subjects) {
                double marks = double.tryParse(r[sub]?.toString() ?? '0') ?? 0;
                if (marks < 33) {
                  isFail = true;
                  break;
                }
              }
              if (isFail)
                failed++;
              else
                passed++;
            }

            double passPercentage = appeared > 0
                ? (passed / appeared) * 100
                : 0;

            aggregated.add({
              "class": cls,
              "examName": "Annual Assessment",
              "appeared": appeared,
              "passed": passed,
              "failed": failed,
              "passPercentage": "${passPercentage.toStringAsFixed(1)}%",
            });
          }
        }
      }
      _examReportData = aggregated;
    } catch (e) {
      debugPrint("Error fetching exams report: $e");
    }
  }

  void _handlePrintReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🖨️ Generating Live PDF Report..."),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
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
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "School Analytics",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${widget.reportType} Report", // 🟢 NAYA: Dynamic Title
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _handlePrintReport,
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text("Print / PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 🚀 BODY CONTENT
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: !isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: widget.reportType == "Students"
                              ? _buildStudentsTable(isDark)
                              : widget.reportType == "Fees"
                              ? _buildFeesTable(isDark)
                              : widget.reportType == "Attendance"
                              ? _buildAttendanceTable(isDark)
                              : _buildExamsTable(isDark),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ================= INDIVIDUAL TABLES =================
  Widget _buildStudentsTable(bool isDark) {
    if (_studentReportData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "No Student Data Found.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    int tBoys = _studentReportData.fold(
      0,
      (acc, c) => acc + (c['boys'] as int),
    );
    int tGirls = _studentReportData.fold(
      0,
      (acc, c) => acc + (c['girls'] as int),
    );
    int tTotal = _studentReportData.fold(
      0,
      (acc, c) => acc + (c['total'] as int),
    );

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      ),
      columns: [
        _buildCol("Class", isDark),
        _buildCol("Sections", isDark),
        _buildCol("Boys", isDark),
        _buildCol("Girls", isDark),
        _buildCol("Total Students", isDark, isGreen: true),
      ],
      rows: [
        ..._studentReportData.map(
          (data) => DataRow(
            cells: [
              DataCell(
                Text(
                  data['class'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  data['section'],
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  data['boys'].toString(),
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  data['girls'].toString(),
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  data['total'].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Total Row
        DataRow(
          color: WidgetStateProperty.all(
            isDark ? const Color(0xFF0F172A) : Colors.grey.shade200,
          ),
          cells: [
            DataCell(
              Text(
                "GRAND TOTAL:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            DataCell(
              Text(
                "",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            DataCell(
              Text(
                tBoys.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            DataCell(
              Text(
                tGirls.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            DataCell(
              Text(
                tTotal.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeesTable(bool isDark) {
    if (_feeReportData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "No Fee Data Found.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    double tExpected = _feeReportData.fold(
      0.0,
      (acc, c) => acc + (c['expected'] as double),
    );
    double tCollected = _feeReportData.fold(
      0.0,
      (acc, c) => acc + (c['collected'] as double),
    );
    double tPending = _feeReportData.fold(
      0.0,
      (acc, c) => acc + (c['pending'] as double),
    );

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      ),
      columns: [
        _buildCol("Class", isDark),
        _buildCol("Expected Amount (₹)", isDark),
        _buildCol("Collected Amount (₹)", isDark, isGreen: true),
        _buildCol("Pending Amount (₹)", isDark, isRed: true),
      ],
      rows: [
        ..._feeReportData.map(
          (data) => DataRow(
            cells: [
              DataCell(
                Text(
                  data['class'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  data['expected'].toStringAsFixed(0),
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  data['collected'].toStringAsFixed(0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
              DataCell(
                Text(
                  data['pending'].toStringAsFixed(0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Total Row
        DataRow(
          color: WidgetStateProperty.all(
            isDark ? const Color(0xFF0F172A) : Colors.grey.shade200,
          ),
          cells: [
            DataCell(
              Text(
                "TOTAL:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            DataCell(
              Text(
                "₹ ${tExpected.toStringAsFixed(0)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            DataCell(
              Text(
                "₹ ${tCollected.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
            ),
            DataCell(
              Text(
                "₹ ${tPending.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceTable(bool isDark) {
    if (_attendanceReportData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "No Attendance Data Found.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      ),
      columns: [
        _buildCol("Month", isDark),
        _buildCol("Working Days", isDark),
        _buildCol("Average Attendance", isDark, isBlue: true),
        _buildCol("Status", isDark),
      ],
      rows: _attendanceReportData.map((data) {
        bool isExcellent = data['status'] == "Excellent";
        return DataRow(
          cells: [
            DataCell(
              Text(
                data['month'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            DataCell(
              Text(
                "${data['workingDays']} Days",
                style: TextStyle(
                  color: isDark ? Colors.grey.shade300 : Colors.black87,
                ),
              ),
            ),
            DataCell(
              Text(
                data['avgAttendance'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isExcellent
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['status'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isExcellent ? Colors.green : Colors.blueAccent,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildExamsTable(bool isDark) {
    if (_examReportData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "No Exam Data Found.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      ),
      columns: [
        _buildCol("Class", isDark),
        _buildCol("Exam Name", isDark),
        _buildCol("Appeared", isDark),
        _buildCol("Passed", isDark, isGreen: true),
        _buildCol("Failed", isDark, isRed: true),
        _buildCol("Pass %", isDark),
      ],
      rows: _examReportData
          .map(
            (data) => DataRow(
              cells: [
                DataCell(
                  Text(
                    data['class'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    data['examName'],
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.black87,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    data['appeared'].toString(),
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.black87,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    data['passed'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    data['failed'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data['passPercentage'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  // Column Header Builder Helper
  DataColumn _buildCol(
    String text,
    bool isDark, {
    bool isGreen = false,
    bool isRed = false,
    bool isBlue = false,
  }) {
    Color tColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    if (isGreen) tColor = const Color(0xFF059669);
    if (isRed) tColor = Colors.redAccent;
    if (isBlue) tColor = Colors.blueAccent;

    return DataColumn(
      label: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: tColor,
          fontSize: 12,
        ),
      ),
    );
  }
}
