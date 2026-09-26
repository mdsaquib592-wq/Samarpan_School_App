import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExamResultViewScreen extends StatefulWidget {
  // 🟢 YAHAN FIX KIYA HAI: Constructor ka naam class name se match hona chahiye
  const ExamResultViewScreen({super.key});

  @override
  State<ExamResultViewScreen> createState() => _ExamResultViewScreenState();
}

class _ExamResultViewScreenState extends State<ExamResultViewScreen> {
  final String _baseUrl = 'http://10.0.2.2:5000/api';
  bool _isLoading = false;

  String _selectedClassFilter = 'All';
  final List<String> _classes = [
    'All',
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

  final List<Map<String, String>> _subjects = [
    {"name": "MATHS", "f_mark": "100"},
    {"name": "SCIENCE", "f_mark": "100"},
    {"name": "ENGLISH", "f_mark": "100"},
    {"name": "SOCIAL SCIENCE", "f_mark": "100"},
    {"name": "HINDI", "f_mark": "100"},
    {"name": "COMPUTER", "f_mark": "100"},
    {"name": "GK", "f_mark": "100"},
    {"name": "DRAWING", "f_mark": "100"},
  ];

  List<dynamic> _savedResults = [];
  List<dynamic> _filteredResults = [];
  String _searchQuery = '';

  final TextEditingController _examNameCtrl = TextEditingController(
    text: "ANNUAL ASSESSMENT 2025-26",
  );

  Future<void> _fetchSavedResults(String className) async {
    if (className == 'All') {
      setState(() {
        _savedResults = [];
        _filteredResults = [];
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/get-results/$className'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _savedResults = data['results'] ?? [];
            _filterResults();
          });
        }
      }
    } catch (e) {
      debugPrint("API Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterResults() {
    setState(() {
      _filteredResults = _savedResults.where((res) {
        final search = _searchQuery.toLowerCase();
        final name = (res['student_name'] ?? '').toString().toLowerCase();
        final roll = (res['roll_no'] ?? '').toString().toLowerCase();
        final regId = (res['student_reg_id'] ?? '').toString().toLowerCase();

        return name.contains(search) ||
            roll.contains(search) ||
            regId.contains(search);
      }).toList();
    });
  }

  // ==========================================
  // CALCULATIONS (Grades & Status)
  // ==========================================
  Map<String, dynamic> _getGradeInfo(Map<String, dynamic> result) {
    double total = 0;
    bool isFail = false;

    for (var sub in _subjects) {
      String key = sub['name']!.toLowerCase().replaceAll(' ', '_');
      double marks = double.tryParse(result[key]?.toString() ?? '0') ?? 0;
      total += marks;
      if (marks < 33) isFail = true;
    }

    if (isFail)
      return {"grade": "F", "status": "FAIL", "color": Colors.redAccent};

    double percentage = (total / 800) * 100;
    if (percentage >= 90)
      return {"grade": "A+", "status": "PASSED", "color": Colors.green};
    if (percentage >= 80)
      return {"grade": "A", "status": "PASSED", "color": Colors.green};
    if (percentage >= 70)
      return {"grade": "B+", "status": "PASSED", "color": Colors.green};
    if (percentage >= 60)
      return {"grade": "B", "status": "PASSED", "color": Colors.blue};
    if (percentage >= 45)
      return {"grade": "C", "status": "PASSED", "color": Colors.orange};
    if (percentage >= 33)
      return {"grade": "D", "status": "PASSED", "color": Colors.orange};

    return {"grade": "F", "status": "FAIL", "color": Colors.redAccent};
  }

  Map<String, dynamic> _getSubjectGrade(dynamic marksVal) {
    double m = double.tryParse(marksVal?.toString() ?? '0') ?? 0;
    if (m >= 90)
      return {
        "grade": "A+",
        "color": Colors.green.withValues(alpha: 0.1),
        "text": Colors.green.shade800,
      };
    if (m >= 80)
      return {
        "grade": "A",
        "color": Colors.green.withValues(alpha: 0.1),
        "text": Colors.green.shade800,
      };
    if (m >= 70)
      return {
        "grade": "B+",
        "color": Colors.orange.withValues(alpha: 0.1),
        "text": Colors.orange.shade800,
      };
    if (m >= 60)
      return {
        "grade": "B",
        "color": Colors.orange.withValues(alpha: 0.1),
        "text": Colors.orange.shade800,
      };
    if (m >= 45)
      return {
        "grade": "C",
        "color": Colors.blue.withValues(alpha: 0.1),
        "text": Colors.blue.shade800,
      };
    if (m >= 33)
      return {
        "grade": "D",
        "color": Colors.blue.withValues(alpha: 0.1),
        "text": Colors.blue.shade800,
      };
    return {
      "grade": "F",
      "color": Colors.red.withValues(alpha: 0.1),
      "text": Colors.red.shade800,
    };
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // REPORT CARD MODAL
  // ==========================================
  void _showReportCardDialog(Map<String, dynamic> studentResult) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double total = 0;
    for (var sub in _subjects) {
      String key = sub['name']!.toLowerCase().replaceAll(' ', '_');
      total += double.tryParse(studentResult[key]?.toString() ?? '0') ?? 0;
    }
    double percentage = (total / 800) * 100;
    final gradeInfo = _getGradeInfo(studentResult);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      size: 30,
                      color: Color(0xFF059669),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                    ),
                  ],
                ),
                Text(
                  "SAMARPAN VIDYALAYA",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  _examNameCtrl.text,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const Divider(height: 30),

                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Name: ${studentResult['student_name']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              "Father: ${studentResult['FatherName'] ?? '- N/A -'}",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Class: ${studentResult['class_name']} | Roll: ${studentResult['roll_no']}",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${percentage.toStringAsFixed(1)}%",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Colors.blueAccent,
                              ),
                            ),
                            Text(
                              "Total: ${total.toStringAsFixed(0)}/800",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: gradeInfo['color'].withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                "${gradeInfo['grade']} (${gradeInfo['status']})",
                                style: TextStyle(
                                  color: gradeInfo['color'],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : Colors.grey.shade200,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "SUBJECT",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "MARKS",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "GRADE",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                ..._subjects.map((sub) {
                  String key = sub['name']!.toLowerCase().replaceAll(' ', '_');
                  String marks = studentResult[key]?.toString() ?? '0';
                  var subGrade = _getSubjectGrade(marks);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            sub['name']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "$marks/100",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: subGrade['color'],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                subGrade['grade'],
                                style: TextStyle(
                                  color: subGrade['text'],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Class Teacher Sign\n-----------------",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "Principal Sign\n-----------------",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSnack("Print function invoked", Colors.blueAccent);
                    },
                    icon: const Icon(Icons.print_rounded),
                    label: const Text("Print Report Card"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                        "Exam Results",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Saved Records",
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
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedClassFilter,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF059669),
                      ),
                      dropdownColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      items: _classes
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e == 'All' ? 'All Classes' : "Class $e",
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedClassFilter = val;
                            _fetchSavedResults(val);
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 🟢 NAYA: SEARCH BAR
          if (_selectedClassFilter != 'All' && _savedResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade300,
                  ),
                ),
                child: TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    _filterResults();
                  },
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: "Search by Name or ID...",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
              ),
            ),

          // 🚀 BODY CONTENT
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)),
                  )
                : _selectedClassFilter == 'All' || _savedResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fact_check_rounded,
                          size: 70,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _selectedClassFilter == 'All'
                              ? "Select a Class"
                              : "No results found",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Choose a class from dropdown to view results.",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: isDark ? 10 : 10,
                      bottom: 50,
                    ),
                    itemCount: _filteredResults.length,
                    itemBuilder: (context, index) {
                      final result = _filteredResults[index];
                      final name = result['student_name'] ?? 'Unknown';
                      final roll = result['roll_no'] ?? '-';

                      double total = 0;
                      for (var sub in _subjects) {
                        String key = sub['name']!.toLowerCase().replaceAll(
                          ' ',
                          '_',
                        );
                        total +=
                            double.tryParse(result[key]?.toString() ?? '0') ??
                            0;
                      }
                      double percentage = (total / 800) * 100;
                      final gradeInfo = _getGradeInfo(result);

                      return Container(
                        margin: EdgeInsets.only(bottom: isDark ? 15 : 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.transparent,
                          ),
                          boxShadow: !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
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
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: gradeInfo['color'].withValues(
                                alpha: 0.15,
                              ),
                              child: Text(
                                name[0].toUpperCase(),
                                style: TextStyle(
                                  color: gradeInfo['color'],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "Roll No: $roll | Total: ${total.toStringAsFixed(0)}/800",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Text(
                                        "${percentage.toStringAsFixed(1)}% ",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: gradeInfo['color'].withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          gradeInfo['grade'],
                                          style: TextStyle(
                                            color: gradeInfo['color'],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.print_rounded,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () => _showReportCardDialog(result),
                              tooltip: "Print Report Card",
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
