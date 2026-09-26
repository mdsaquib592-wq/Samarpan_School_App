import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class TeacherRecordsScreen extends StatefulWidget {
  const TeacherRecordsScreen({super.key});

  @override
  State<TeacherRecordsScreen> createState() => _TeacherRecordsScreenState();
}

class _TeacherRecordsScreenState extends State<TeacherRecordsScreen> {
  final String _baseUrl = 'http://10.0.2.2:5000/api';
  bool _isLoading = false;

  List<dynamic> _allTeachers = [];
  List<dynamic> _filteredTeachers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/teachers'));
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        setState(() {
          _allTeachers = (decodedData is List)
              ? decodedData
              : (decodedData['teachers'] ?? decodedData['data'] ?? []);
          _filterTeachers();
        });
      }
    } catch (e) {
      debugPrint("Error fetching teachers: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterTeachers() {
    setState(() {
      _filteredTeachers = _allTeachers.where((t) {
        final search = _searchQuery.toLowerCase();
        final name = (t['name'] ?? '').toString().toLowerCase();
        final id = (t['id'] ?? '').toString().toLowerCase();
        return name.contains(search) || id.contains(search);
      }).toList();
    });
  }

  Future<void> _saveTeacher({
    String? existingId,
    required String name,
    required String subject,
    required String phone,
    required String email,
    required String qualification,
    required String status,
  }) async {
    final isEdit = existingId != null;
    final id = isEdit ? existingId : 'T-${Random().nextInt(9000) + 1000}';
    final joinedDate = DateTime.now().toIso8601String().split('T')[0];

    final payload = {
      "id": id,
      "name": name,
      "subject": subject,
      "phone": phone,
      "email": email,
      "qualification": qualification,
      "joined": isEdit ? null : joinedDate,
      "status": status,
      "profile_image": "",
    };

    final url = isEdit ? '$_baseUrl/teachers/$id' : '$_baseUrl/teachers';

    try {
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
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showSnack(
          isEdit ? "✅ Teacher Updated!" : "✅ Teacher Added!",
          Colors.green,
        );
        _fetchTeachers();
      } else {
        _showSnack(data['error'] ?? "❌ Failed to save.", Colors.red);
      }
    } catch (e) {
      _showSnack("❌ Server Error", Colors.red);
    }
  }

  Future<void> _deleteTeacher(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/teachers/$id'));
      if (response.statusCode == 200) {
        _showSnack("🗑️ Teacher Deleted!", Colors.redAccent);
        _fetchTeachers();
      }
    } catch (e) {
      _showSnack("❌ Error deleting teacher.", Colors.redAccent);
    }
  }

  Future<void> _savePassword(String teacherId, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/teachers/set-credentials'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"teacher_id": teacherId, "password": password}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showSnack("🔑 Password Saved Successfully!", Colors.green);
      } else {
        _showSnack(data['error'] ?? "❌ Failed to save password.", Colors.red);
      }
    } catch (e) {
      _showSnack("❌ Server Error while saving password.", Colors.red);
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

  void _showTeacherFormSheet({Map<String, dynamic>? existingTeacher}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = existingTeacher != null;

    final id = isEdit ? existingTeacher['id'].toString() : null;
    final nameCtrl = TextEditingController(
      text: isEdit ? existingTeacher['name'] : '',
    );
    final subjectCtrl = TextEditingController(
      text: isEdit ? existingTeacher['subject'] : '',
    );
    final qualCtrl = TextEditingController(
      text: isEdit ? existingTeacher['qualification'] : '',
    );
    final phoneCtrl = TextEditingController(
      text: isEdit ? existingTeacher['phone'] : '',
    );
    final emailCtrl = TextEditingController(
      text: isEdit ? existingTeacher['email'] : '',
    );
    String status = isEdit ? (existingTeacher['status'] ?? 'Active') : 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
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
                        isEdit
                            ? "✏️ Edit Teacher Details"
                            : "✨ Add New Teacher",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildModernTextField(
                        controller: nameCtrl,
                        label: "Full Name",
                        icon: Icons.person,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernTextField(
                              controller: subjectCtrl,
                              label: "Subject",
                              icon: Icons.book,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildModernTextField(
                              controller: qualCtrl,
                              label: "Qualification",
                              icon: Icons.school,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernTextField(
                              controller: phoneCtrl,
                              label: "Phone",
                              icon: Icons.phone,
                              isDark: isDark,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildModernTextField(
                              controller: emailCtrl,
                              label: "Email",
                              icon: Icons.email,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: status,
                            isExpanded: true,
                            dropdownColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                            items: ['Active', 'Inactive']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null)
                                setModalState(() => status = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty)
                              return;
                            Navigator.pop(context);
                            _saveTeacher(
                              existingId: id,
                              name: nameCtrl.text,
                              subject: subjectCtrl.text,
                              phone: phoneCtrl.text,
                              email: emailCtrl.text,
                              qualification: qualCtrl.text,
                              status: status,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isEdit ? "UPDATE TEACHER" : "SAVE TEACHER",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPasswordDialog(Map<String, dynamic> teacher) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.key_rounded, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Set Password",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Login ID: ${teacher['id']}",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildModernTextField(
              controller: passCtrl,
              label: "New Password",
              icon: Icons.lock_outline,
              isDark: isDark,
              isPassword: true,
            ),
          ],
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
              if (passCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                _savePassword(teacher['id'], passCtrl.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Save",
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

  void _confirmDelete(String id, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text("Delete Teacher?"),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently remove $name from the records?",
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
              _deleteTeacher(id);
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool isNumber = false,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      obscureText: isPassword,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Yahan teeno stats calculate ho rahe hain
    int total = _allTeachers.length;
    int active = _allTeachers.where((t) => t['status'] == 'Active').length;
    int inactive = total - active; // Inactive count

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎛️ TOP HEADER (Without Tabs)
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
                      "Teachers",
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
                  Icons.support_agent_rounded,
                  size: 36,
                  color: Color(0xFF059669),
                ),
              ],
            ),
          ),

          // 🚀 BODY
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // 🟢 FIX: 3 Stat Cards Add Ho Gaye (Total, Active, Inactive)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    "Total",
                                    "$total",
                                    Icons.people_rounded,
                                    Colors.blueAccent,
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    "Active",
                                    "$active",
                                    Icons.check_circle_rounded,
                                    const Color(0xFF059669),
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    "Inactive",
                                    "$inactive",
                                    Icons.person_off_rounded,
                                    Colors.redAccent,
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: TextField(
                                onChanged: (val) {
                                  _searchQuery = val;
                                  _filterTeachers();
                                },
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Search by Name or ID...",
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                  ),
                                  border: InputBorder.none,
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _filteredTeachers.isEmpty
                            ? Center(
                                child: Text(
                                  "No Teachers Found",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: _filteredTeachers.length,
                                itemBuilder: (context, i) {
                                  final t = _filteredTeachers[i];
                                  final isActive = t['status'] == 'Active';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.transparent,
                                      ),
                                      boxShadow: !isDark
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 25,
                                              backgroundColor: const Color(
                                                0xFF059669,
                                              ).withOpacity(0.15),
                                              child: Text(
                                                (t['name'] ?? 'U')[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Color(0xFF059669),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
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
                                                    t['name'] ?? 'N/A',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "${t['subject']} • ID: ${t['id']}",
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isActive
                                                          ? Colors.green
                                                                .withOpacity(
                                                                  0.1,
                                                                )
                                                          : Colors.red
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      t['status'] ?? 'N/A',
                                                      style: TextStyle(
                                                        color: isActive
                                                            ? Colors.green
                                                            : Colors.redAccent,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.key_rounded,
                                                    color: Colors.amber,
                                                    size: 22,
                                                  ),
                                                  onPressed: () =>
                                                      _showPasswordDialog(t),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit_rounded,
                                                    color: Colors.blueAccent,
                                                    size: 22,
                                                  ),
                                                  onPressed: () =>
                                                      _showTeacherFormSheet(
                                                        existingTeacher: t,
                                                      ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    color: Colors.redAccent,
                                                    size: 22,
                                                  ),
                                                  onPressed: () =>
                                                      _confirmDelete(
                                                        t['id'].toString(),
                                                        t['name'],
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 30),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.phone_iphone_rounded,
                                              size: 14,
                                              color: Colors.blueGrey,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              t['phone'] ?? 'N/A',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.grey.shade300
                                                    : Colors.black87,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            const Icon(
                                              Icons.school_rounded,
                                              size: 14,
                                              color: Colors.blueGrey,
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                t['qualification'] ?? 'N/A',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.grey.shade300
                                                      : Colors.black87,
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
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
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTeacherFormSheet(),
        backgroundColor: const Color(0xFF059669),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        label: const Text(
          "Add Teacher",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // Helper for Stats Card (Slightly adjusted padding to fit 3 cards in a row nicely)
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent,
        ),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
