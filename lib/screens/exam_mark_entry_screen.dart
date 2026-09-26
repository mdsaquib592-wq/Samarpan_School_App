import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExamMarkEntryScreen extends StatefulWidget {
  const ExamMarkEntryScreen({super.key});

  @override
  State<ExamMarkEntryScreen> createState() => _ExamMarkEntryScreenState();
}

class _ExamMarkEntryScreenState extends State<ExamMarkEntryScreen> {
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

  List<dynamic> _students = [];

  // 🟢 NAYA FIX: Data aur Controllers dono manage karne ke liye Maps
  Map<String, Map<String, String>> _marksData = {};
  Map<String, Map<String, TextEditingController>> _controllers = {};

  final TextEditingController _examNameCtrl = TextEditingController(
    text: "ANNUAL ASSESSMENT 2025-26",
  );

  @override
  void dispose() {
    // 🧹 Memory leak bachane ke liye saare controllers dispose karna zaroori hai
    for (var studentControllers in _controllers.values) {
      for (var ctrl in studentControllers.values) {
        ctrl.dispose();
      }
    }
    _examNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents(String className) async {
    if (className == 'All') {
      setState(() {
        _students = [];
        _marksData = {};
        _controllers = {};
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/students-by-class/$className'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          _students = data['students'] ?? [];

          // 🟢 NAYA FIX: Har student ke har subject ke liye ek Controller banana
          for (var student in _students) {
            String regId = student['StudentRegistrationId']?.toString() ?? '';
            if (regId.isNotEmpty && !_controllers.containsKey(regId)) {
              _marksData[regId] = {};
              _controllers[regId] = {};

              for (var sub in _subjects) {
                String subName = sub['name']!;
                _marksData[regId]![subName] = "";
                _controllers[regId]![subName] = TextEditingController();
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("API Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSingleResult(Map<String, dynamic> student) async {
    if (_selectedClassFilter == 'All') return;

    String regId = student['StudentRegistrationId'].toString();
    Map<String, String> studentMarks = _marksData[regId] ?? {};

    // Validate Marks
    bool hasMissingMarks = _subjects.any(
      (sub) =>
          studentMarks[sub['name']] == null ||
          studentMarks[sub['name']]!.isEmpty,
    );
    if (hasMissingMarks) {
      _showSnack(
        'Please enter marks for all subjects before saving.',
        Colors.orange,
      );
      return;
    }

    final payload = [
      {
        "studentRegId": regId,
        "className": _selectedClassFilter,
        "rollNo": student['RollNo'],
        "studentName": student['FullName'],
        "marks": studentMarks,
      },
    ];

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/save-results'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showSnack('Result saved for ${student['FullName']}!', Colors.green);
      } else {
        _showSnack(data['error'] ?? 'Error saving data', Colors.red);
      }
    } catch (e) {
      _showSnack('Server Error', Colors.red);
    }
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
                  "Mark Entry",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
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
                        child: TextField(
                          controller: _examNameCtrl,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Exam Name...",
                            prefixIcon: Icon(
                              Icons.title,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
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
                                  _fetchStudents(val);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
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
                : _selectedClassFilter == 'All' || _students.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          size: 70,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _selectedClassFilter == 'All'
                              ? "Select a Class"
                              : "No students found",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Choose a class from dropdown to enter marks.",
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
                      top: isDark ? 10 : 20,
                      bottom: 50,
                    ),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final regId = student['StudentRegistrationId'].toString();
                      final name = student['FullName'] ?? 'Unknown';
                      final roll = student['RollNo'] ?? '-';

                      return Container(
                        margin: EdgeInsets.only(bottom: isDark ? 15 : 20),
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
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : Colors.grey.shade100,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.blueAccent
                                        .withValues(alpha: 0.15),
                                    child: Text(
                                      name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          "Roll No: $roll | ID: $regId",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _saveSingleResult(student),
                                    icon: const Icon(
                                      Icons.save_rounded,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      "Save",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Inputs (Grid)
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _subjects.map((sub) {
                                  return SizedBox(
                                    width:
                                        (MediaQuery.of(context).size.width -
                                            60) /
                                        3, // 3 columns
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sub['name']!,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 35,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF0F172A)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          child: TextField(
                                            // 🟢 NAYA FIX: Controller assign kiya gaya hai
                                            controller:
                                                _controllers[regId]?[sub['name']],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                            ),
                                            onChanged: (val) {
                                              // Save values into map
                                              if (val.isNotEmpty &&
                                                  (double.tryParse(val) ==
                                                          null ||
                                                      double.parse(val) < 0 ||
                                                      double.parse(val) >
                                                          100)) {
                                                // Validations can go here if needed
                                              }
                                              setState(() {
                                                _marksData[regId]![sub['name']!] =
                                                    val;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
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
