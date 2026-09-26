import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  List<dynamic> _allStudents = [];
  List<dynamic> _filteredStudents = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedClass = 'All';
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

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  // 🚀 API Se Data Lana
  Future<void> _fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/students'),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        setState(() {
          if (decodedData is List) {
            _allStudents = decodedData;
          } else if (decodedData is Map<String, dynamic>) {
            if (decodedData['data'] != null && decodedData['data'] is List) {
              _allStudents = decodedData['data'];
            } else if (decodedData['students'] != null &&
                decodedData['students'] is List) {
              _allStudents = decodedData['students'];
            } else if (decodedData['result'] != null &&
                decodedData['result'] is List) {
              _allStudents = decodedData['result'];
            } else {
              _allStudents = decodedData.values.firstWhere(
                (v) => v is List,
                orElse: () => [],
              );
            }
          }

          _filteredStudents = _allStudents;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("🔥 API Error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🔍 Search Aur Filter Logic (UPDATED for Capital Keys)
  void _filterData() {
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        // Backend keys ke hisaab se check karein
        final name = (student['FullName'] ?? student['fullName'] ?? '')
            .toString()
            .toLowerCase();
        final className = (student['ClassName'] ?? student['className'] ?? '')
            .toString();

        final nameMatch = name.contains(_searchQuery.toLowerCase());
        final classMatch =
            _selectedClass == 'All' || className == _selectedClass;
        return nameMatch && classMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Students Directory",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🎛️ FILTERS ROW
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          onChanged: (value) {
                            _searchQuery = value;
                            _filterData();
                          },
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search by Name...",
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade500,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedClass,
                              isExpanded: true,
                              dropdownColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 14,
                              ),
                              items: _classes
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e == 'All' ? 'All Classes' : 'Class $e',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  _selectedClass = val;
                                  _filterData();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 📊 DATA TABLE (UPDATED FOR CAPITAL KEYS)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _filteredStudents.isEmpty
                          ? Center(
                              child: Text(
                                "No students found.",
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF8FAFC),
                                  ),
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        'Reg ID',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Student Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Class',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Roll No',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Contact',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: _filteredStudents.map((student) {
                                    // 🚀 Yahan backend wali Asli (Capital) keys daali hain
                                    final regId =
                                        student['RegistrationId'] ??
                                        student['registrationId'] ??
                                        student['StudentRegistrationId'] ??
                                        'N/A';
                                    final name =
                                        student['FullName'] ??
                                        student['fullName'] ??
                                        'N/A';
                                    final cls =
                                        student['ClassName'] ??
                                        student['className'] ??
                                        'N/A';
                                    final roll =
                                        student['RollNo'] ??
                                        student['rollNo'] ??
                                        '-';
                                    final contact =
                                        student['ContactF'] ??
                                        student['contactF'] ??
                                        student['ContactH'] ??
                                        'N/A';

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            regId.toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF059669),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(name.toString())),
                                        DataCell(Text(cls.toString())),
                                        DataCell(Text(roll.toString())),
                                        DataCell(Text(contact.toString())),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
