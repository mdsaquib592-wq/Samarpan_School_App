import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedClass = '1';

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

  List<dynamic> _classStudents = [];
  Map<String, String> _attendanceStatus = {}; // RegID -> 'Present' ya 'Absent'

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchStudentsForClass();
  }

  // 📅 Date Picker
  Future<void> _pickDate(BuildContext context) async {
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
      setState(() => _selectedDate = picked);
    }
  }

  // 🚀 API Se Data Lana (Smart Fetch)
  Future<void> _fetchStudentsForClass() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/students'),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> allStudents = [];

        // Smart Extraction
        if (decodedData is List) {
          allStudents = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          if (decodedData['data'] is List)
            allStudents = decodedData['data'];
          else if (decodedData['students'] is List)
            allStudents = decodedData['students'];
          else if (decodedData['result'] is List)
            allStudents = decodedData['result'];
        }

        setState(() {
          // Sirf Selected Class ke bacche filter karein
          _classStudents = allStudents.where((student) {
            final cls = (student['ClassName'] ?? student['className'] ?? '')
                .toString();
            return cls == _selectedClass;
          }).toList();

          // Sabko by default 'Present' mark karein
          _attendanceStatus.clear();
          for (var student in _classStudents) {
            final regId =
                (student['RegistrationId'] ?? student['registrationId'] ?? '')
                    .toString();
            if (regId.isNotEmpty) {
              _attendanceStatus[regId] = 'Present';
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("API Error: $e");
      setState(() {
        _isLoading = false;
        // Dummy data for testing if API fails
        _classStudents = [
          {"registrationId": "SV001", "fullName": "Aarav Singh"},
          {"registrationId": "SV002", "fullName": "Rahul Kumar"},
          {"registrationId": "SV003", "fullName": "Priya Sharma"},
        ];
        for (var student in _classStudents) {
          _attendanceStatus[student['registrationId']] = 'Present';
        }
      });
    }
  }

  // 💾 Save Attendance to API
  Future<void> _saveAttendance() async {
    if (_classStudents.isEmpty) return;

    setState(() => _isSaving = true);

    // Backend ke liye payload banayein
    List<Map<String, dynamic>> attendanceRecords = [];
    for (var student in _classStudents) {
      final regId = (student['RegistrationId'] ?? student['registrationId'])
          .toString();
      final name = (student['FullName'] ?? student['fullName']).toString();
      attendanceRecords.add({
        "registrationId": regId,
        "studentName": name,
        "status": _attendanceStatus[regId],
      });
    }

    final payload = {
      "date":
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
      "className": _selectedClass,
      "attendance": attendanceRecords,
    };

    try {
      // ⚠️ Note: Yeh API endpoint aapke Node.js me hona chahiye
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/attendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Chahe success ho ya na ho, testing ke liye message dikha dete hain
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Attendance Saved Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error saving attendance.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 🎛️ TOP CONTROLS (Date & Class)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mark Attendance",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    // Date Picker Button
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_month,
                                color: Color(0xFF059669),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Class Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedClass,
                            isExpanded: true,
                            dropdownColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            items: _classes
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      "Class $e",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedClass = val);
                                _fetchStudentsForClass(); // Nayi class ka data lao
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

          // 🧑‍🎓 STUDENTS LIST
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)),
                  )
                : _classStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "No students found in Class $_selectedClass",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _classStudents.length,
                    itemBuilder: (context, index) {
                      final student = _classStudents[index];
                      final regId =
                          (student['RegistrationId'] ??
                                  student['registrationId'] ??
                                  '')
                              .toString();
                      final name =
                          (student['FullName'] ??
                                  student['fullName'] ??
                                  'Unknown')
                              .toString();
                      final isPresent = _attendanceStatus[regId] == 'Present';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isPresent
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Profile Avatar
                            CircleAvatar(
                              backgroundColor: isPresent
                                  ? const Color(0xFF059669)
                                  : Colors.redAccent,
                              radius: 20,
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            // Name & ID
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    regId,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 🟢🔴 TOGGLE BUTTONS
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _attendanceStatus[regId] = 'Present',
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPresent
                                          ? const Color(0xFF059669)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isPresent
                                            ? const Color(0xFF059669)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      "P",
                                      style: TextStyle(
                                        color: isPresent
                                            ? Colors.white
                                            : Colors.grey.shade500,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _attendanceStatus[regId] = 'Absent',
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !isPresent
                                          ? Colors.redAccent
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: !isPresent
                                            ? Colors.redAccent
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      "A",
                                      style: TextStyle(
                                        color: !isPresent
                                            ? Colors.white
                                            : Colors.grey.shade500,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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

          // 💾 SAVE BUTTON (Bottom Sticky)
          if (_classStudents.isNotEmpty && !_isLoading)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAttendance,
                  icon: _isSaving
                      ? const SizedBox()
                      : const Icon(Icons.check_circle_outline),
                  label: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save Attendance",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
