import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
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

  List<dynamic> _allCourses = [];
  List<dynamic> _filteredCourses = [];
  bool _isLoading = true;

  final String _baseUrl = 'http://10.0.2.2:5000/api/courses';

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  // 🚀 1. GET: API se Courses fetch karna
  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        setState(() {
          _allCourses = decodedData['courses'] ?? [];
          _filterData();
          _isLoading = false;
        });
      } else {
        setState(() {
          _allCourses = [];
          _filteredCourses = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _allCourses = [];
        _filteredCourses = [];
        _isLoading = false;
      });
    }
  }

  void _filterData() {
    setState(() {
      _filteredCourses = _allCourses
          .where((course) => course['class_name'].toString() == _selectedClass)
          .toList();
    });
  }

  // 🚀 2. POST / PUT: Course Save ya Update karna
  Future<void> _saveCourse({
    String? id,
    required String name,
    required String teacher,
    required String syllabus,
  }) async {
    try {
      final isEdit = id != null;
      final url = isEdit ? '$_baseUrl/$id' : _baseUrl;
      final payload = {
        "class_name": _selectedClass,
        "subject_name": name,
        "teacher_name": teacher,
        "study_material": syllabus,
        "progress": 0,
      };

      final response = isEdit
          ? await http.put(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
          : await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEdit ? '✅ Course Updated!' : '✅ New Course Added!',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _fetchCourses();
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error saving course.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // 🚀 3. DELETE: API se Course Delete karna
  Future<void> _deleteCourseAPI(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/$id'));
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Course Deleted!"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _fetchCourses();
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error deleting course.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // 📝 Bottom Sheet (Modern Add / Edit Form)
  void _showSubjectDialog({Map<String, dynamic>? existingCourse}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = existingCourse != null;

    final courseId = isEdit ? existingCourse['id'].toString() : null;
    final nameCtrl = TextEditingController(
      text: isEdit ? existingCourse['subject_name']?.toString() ?? '' : '',
    );
    final teacherCtrl = TextEditingController(
      text: isEdit ? existingCourse['teacher_name']?.toString() ?? '' : '',
    );
    final syllabusCtrl = TextEditingController(
      text: isEdit ? existingCourse['study_material']?.toString() ?? '' : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isEdit ? "✨ Edit Subject Details" : "✨ Add New Subject",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 25),

                _buildModernTextField(
                  controller: nameCtrl,
                  label: "Subject Name",
                  icon: Icons.science,
                  isDark: isDark,
                ),
                const SizedBox(height: 15),
                _buildModernTextField(
                  controller: teacherCtrl,
                  label: "Assigned Teacher",
                  icon: Icons.person_pin_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 15),
                _buildModernTextField(
                  controller: syllabusCtrl,
                  label: "Study Material / Syllabus",
                  icon: Icons.menu_book_rounded,
                  isDark: isDark,
                  maxLines: 3,
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isEmpty) return;
                      Navigator.pop(context);
                      _saveCourse(
                        id: courseId,
                        name: nameCtrl.text,
                        teacher: teacherCtrl.text,
                        syllabus: syllabusCtrl.text,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      shadowColor: const Color(
                        0xFF059669,
                      ).withValues(alpha: 0.5),
                    ),
                    child: Text(
                      isEdit ? "UPDATE COURSE" : "SAVE COURSE",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: const Color(0xFF059669)),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
        ),
      ),
    );
  }

  // 🗑️ Delete Confirmation Dialog
  void _confirmDelete(String id, String subjectName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text("Delete Subject?"),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently delete '$subjectName'?",
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCourseAPI(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Yes, Delete",
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎛️ TOP CONTROL: Modern Header & Class Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Academics",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Courses",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedClass,
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
                        fontSize: 16,
                      ),
                      items: _classes
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text("Class $e"),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setState(() {
                            _selectedClass = val;
                            _filterData();
                          });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 📚 SUBJECTS LIST
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)),
                  )
                : _filteredCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 70,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "No Courses Yet",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Click + to add subjects for Class $_selectedClass",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: isDark ? 10 : 20,
                    ),
                    itemCount: _filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = _filteredCourses[index];
                      final subId = course['id'].toString();
                      final subName =
                          course['subject_name']?.toString() ?? 'Unknown';
                      final teacherName =
                          course['teacher_name']?.toString() ?? 'Not Assigned';
                      final syllabus =
                          course['study_material']?.toString() ??
                          'No details available.';

                      // 📸 Yahan Teacher ki photo (base64) aayegi agar API me hui toh
                      final teacherImage =
                          course['profile_image']?.toString() ??
                          course['teacher_image']?.toString() ??
                          '';

                      return Container(
                        margin: EdgeInsets.only(bottom: isDark ? 20 : 30),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.transparent,
                          ),

                          boxShadow: !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 30,
                                    spreadRadius: 8,
                                    offset: const Offset(0, 15),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Premium Gradient Avatar (For Subject)
                                  Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF059669),
                                          Color(0xFF10B981),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF059669,
                                          ).withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        subName.isNotEmpty
                                            ? subName[0].toUpperCase()
                                            : 'B',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subName,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // 🧑‍🏫 MODERN TEACHER PROFILE PILL
                                        Container(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                            right: 12,
                                            top: 4,
                                            bottom: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF0F172A)
                                                : Colors.blueGrey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ), // Full round pill
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Image ya Initial check
                                              teacherImage.isNotEmpty &&
                                                      teacherImage.length > 50
                                                  ? CircleAvatar(
                                                      radius: 12,
                                                      backgroundImage:
                                                          MemoryImage(
                                                            base64Decode(
                                                              teacherImage
                                                                      .contains(
                                                                        ',',
                                                                      )
                                                                  ? teacherImage
                                                                        .split(
                                                                          ',',
                                                                        )
                                                                        .last
                                                                  : teacherImage,
                                                            ),
                                                          ),
                                                    )
                                                  : CircleAvatar(
                                                      radius: 12,
                                                      backgroundColor: isDark
                                                          ? Colors.grey.shade800
                                                          : Colors
                                                                .grey
                                                                .shade300,
                                                      child: Text(
                                                        teacherName.isNotEmpty
                                                            ? teacherName[0]
                                                                  .toUpperCase()
                                                            : 'T',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isDark
                                                              ? Colors.white
                                                              : Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                              const SizedBox(width: 8),
                                              Text(
                                                teacherName,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.grey.shade300
                                                      : Colors
                                                            .blueGrey
                                                            .shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Floating Action Icons
                                  Column(
                                    children: [
                                      InkWell(
                                        onTap: () => _showSubjectDialog(
                                          existingCourse: course,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.edit_rounded,
                                            color: Colors.blueAccent,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      InkWell(
                                        onTap: () =>
                                            _confirmDelete(subId, subName),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // 🚀 SYLLABUS BOX
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2A374C)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isDark
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 5),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.menu_book_rounded,
                                          size: 16,
                                          color: Color(0xFF059669),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Study Material / Syllabus",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      syllabus,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade600,
                                        fontSize: 14,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ➕ MODERN FLOATING ACTION BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectDialog(),
        backgroundColor: const Color(0xFF059669),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        label: const Text(
          "New Subject",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
