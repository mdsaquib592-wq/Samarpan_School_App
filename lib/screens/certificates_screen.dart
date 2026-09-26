import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  final String _baseUrl = 'http://10.0.2.2:5000/api';

  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Map<String, dynamic>? _selectedStudent;

  String _activeCertificate = 'ID'; // 'ID', 'Bonafide', 'Leaving'
  Timer? _debounce;

  // 🚀 LIVE SEARCH FUNCTION (Debounced)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchStudents(query);
    });
  }

  Future<void> _searchStudents(String query) async {
    setState(() => _isSearching = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/search-students?query=$query'),
      );
      if (res.statusCode == 200) {
        setState(() => _searchResults = jsonDecode(res.body)['students'] ?? []);
      }
    } catch (e) {
      debugPrint("Search Error: $e");
    }
    setState(() => _isSearching = false);
  }

  void _selectStudent(Map<String, dynamic> student) {
    setState(() {
      _selectedStudent = student;
      _searchResults = [];
      _activeCertificate = 'ID'; // Default view
    });
  }

  // 📅 DATE FORMATTER
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      DateTime d = DateTime.parse(dateStr);
      return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
    } catch (e) {
      if (dateStr.length > 10) return dateStr.substring(0, 10);
      return dateStr;
    }
  }

  void _showPrintSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "🖨️ For real PDF printing, 'printing' & 'pdf' packages are required. Showing preview only.",
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎛️ TOP HEADER & SEARCH
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 36,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Documents",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Certificates & ID",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 🔍 LIVE SEARCH BOX
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                  ),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search Student by Name or ID...",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF059669),
                      ),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),

                // 🔍 SEARCH RESULTS DROPDOWN
                if (_searchResults.isNotEmpty && _selectedStudent == null)
                  Container(
                    margin: const EdgeInsets.only(
                      top: 10,
                    ), // 🚀 YAHAN ERROR FIX KIYA GAYA HAI
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A374C) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final s = _searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFF059669,
                            ).withValues(alpha: 0.2),
                            child: Text(
                              s['FullName'][0],
                              style: const TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            s['FullName'],
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "ID: ${s['StudentRegistrationId']} | Class: ${s['ClassName']}",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => _selectStudent(s),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 🚀 MAIN CONTENT AREA
          Expanded(
            child: _selectedStudent == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.badge_rounded,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "No Student Selected",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          "Search and select a student to generate documents.",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // 🎛️ ACTION BUTTONS PANEL
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blueAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedStudent!['FullName'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "ID: ${_selectedStudent!['StudentRegistrationId']} | Class: ${_selectedStudent!['ClassName']}",
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _selectedStudent = null),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 30),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDocBtn(
                                    "ID Card",
                                    Icons.badge_rounded,
                                    'ID',
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildDocBtn(
                                    "Bonafide",
                                    Icons.workspace_premium_rounded,
                                    'Bonafide',
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildDocBtn(
                                    "Leaving (TC)",
                                    Icons.library_books_rounded,
                                    'Leaving',
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 📄 PREVIEW AREA
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Center(
                            child: _activeCertificate == 'ID'
                                ? _buildIDCardPreview(isDark)
                                : _buildCertificatePreview(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),

      // 🖨️ PRINT FAB
      floatingActionButton: _selectedStudent != null
          ? FloatingActionButton.extended(
              onPressed: _showPrintSnack,
              backgroundColor: const Color(0xFF059669),
              elevation: 6,
              icon: const Icon(Icons.print_rounded, color: Colors.white),
              label: Text(
                "Print $_activeCertificate",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  // --- BUTTON WIDGET ---
  Widget _buildDocBtn(String title, IconData icon, String type, bool isDark) {
    final isActive = _activeCertificate == type;
    return InkWell(
      onTap: () => setState(() => _activeCertificate = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF059669)
              : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🎓 ID CARD PREVIEW (Native UI)
  // ==========================================
  Widget _buildIDCardPreview(bool isDark) {
    final s = _selectedStudent!;
    final photoBase64 = s['Photo']?.toString() ?? '';

    return Container(
      width: 250, // Standard ID Card width ratio
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white, // ID cards are usually printed on white PVC
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFF1E293B), width: 2),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.school, size: 15, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const Text(
                      "SAMARPAN VIDYALAYA",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "Tilaiya Dam, Sainik School",
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 7,
                      ),
                    ),
                    Text(
                      "Ph: +91 8789765575",
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 7,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                // Photo
                Container(
                  width: 80,
                  height: 95,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 2),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade200,
                  ),
                  child: photoBase64.isNotEmpty && photoBase64.length > 100
                      ? Image.memory(
                          base64Decode(
                            photoBase64.contains(',')
                                ? photoBase64.split(',').last
                                : photoBase64,
                          ),
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(
                  s['FullName'].toString().toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),

                // Details Grid
                _idRow("ID No.", s['StudentRegistrationId']),
                _idRow("Class", s['ClassName']),
                _idRow("Roll No.", s['RollNo']),
                _idRow("F. Name", s['FatherName']),
                _idRow("DOB", _formatDate(s['DOB'])),
                _idRow("Contact", s['ContactF'] ?? 'N/A'),
              ],
            ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(height: 20),
                Text(
                  "Principal's Signature",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.overline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _idRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 55,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Text(
            ":",
            style: TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📜 CERTIFICATE PREVIEW (A4 Layout)
  // ==========================================
  Widget _buildCertificatePreview(bool isDark) {
    final s = _selectedStudent!;
    final year = DateTime.now().year;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white, // Printed docs are white
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 40, color: Color(0xFF1E293B)),
              const SizedBox(width: 15),
              Column(
                children: [
                  const Text(
                    "SAMARPAN VIDYALAYA",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    "Barki Dhamrai Road, Upper More, Tilaiya Dam",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Phone: +91 8789765575",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Color(0xFF1E293B), thickness: 2),
          const SizedBox(height: 20),

          // Title
          Text(
            _activeCertificate == 'Bonafide'
                ? "BONAFIDE CERTIFICATE"
                : "SCHOOL LEAVING / TRANSFER CERTIFICATE",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Meta Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ref No: SV/${_activeCertificate == 'Bonafide' ? 'BON' : 'TC'}/$year/${s['RollNo']}",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                "Date: ${_formatDate(DateTime.now().toString())}",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Content Body
          if (_activeCertificate == 'Bonafide') ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "TO WHOM IT MAY CONCERN",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 2.0,
                ),
                children: [
                  const TextSpan(text: "This is to certify that Master/Miss "),
                  TextSpan(
                    text: s['FullName'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ", Son/Daughter of Mr. "),
                  TextSpan(
                    text: s['FatherName'] ?? "____________________",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: " and Mrs. "),
                  TextSpan(
                    text: s['MotherName'] ?? "____________________",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: " is/was a bonafide student of "),
                  const TextSpan(
                    text: "Samarpan Vidyalaya.\n\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const TextSpan(text: "He/She is/was studying in Class "),
                  TextSpan(
                    text: s['ClassName'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: " bearing Roll No. "),
                  TextSpan(
                    text: s['RollNo']?.toString() ?? "-",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: " and Registration ID "),
                  TextSpan(
                    text: s['StudentRegistrationId'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: " during the academic year ${year - 1}-$year.\n\n",
                  ),

                  const TextSpan(
                    text: "His/Her date of birth as per our school records is ",
                  ),
                  TextSpan(
                    text: _formatDate(s['DOB']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text:
                        ".\n\nTo the best of my knowledge, he/she bears a good moral character. We wish him/her success in all future endeavors.",
                  ),
                ],
              ),
            ),
          ] else ...[
            // Transfer Certificate Table
            Table(
              border: TableBorder.all(color: Colors.grey.shade400),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              children: [
                _tcRow("1. Name of Pupil", s['FullName'], isBold: true),
                _tcRow("2. Father's / Guardian's Name", s['FatherName']),
                _tcRow("3. Mother's Name", s['MotherName']),
                _tcRow("4. Nationality", "Indian"),
                _tcRow("5. Date of First Admission", _formatDate(s['DOA'])),
                _tcRow("6. Date of Birth", _formatDate(s['DOB']), isBold: true),
                _tcRow("7. Class Last Studied", "Class ${s['ClassName']}"),
                _tcRow("8. Registration ID", s['StudentRegistrationId']),
                _tcRow("9. General Conduct", "Good"),
                _tcRow("10. Reason for leaving", "Parents' Request"),
                _tcRow("11. Any other remarks", "Nil"),
              ],
            ),
          ],

          const SizedBox(height: 60),

          // Signatures
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sigBlock("Prepared By"),
              _sigBlock("Checked By"),
              _sigBlock("Principal's Signature & Seal"),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _tcRow(String label, dynamic value, {bool isBold = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value?.toString() ?? '-',
            style: TextStyle(
              color: Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sigBlock(String title) {
    return Column(
      children: [
        Container(width: 80, height: 1, color: Colors.black),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
