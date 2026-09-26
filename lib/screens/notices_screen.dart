import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 🚀 Role ke liye zaroori
import 'dart:convert';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final String _baseUrl = 'http://10.0.2.2:5000/api/notices';
  List<dynamic> _allNotices = [];
  List<dynamic> _filteredNotices = [];
  bool _isLoading = true;
  String _userRole = "admin"; // Default

  String _selectedCategoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndFetch();
  }

  // 🚀 User Role nikalna aur phir Notices fetch karna
  Future<void> _loadUserRoleAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = (prefs.getString('userRole') ?? 'admin').toLowerCase();
    });
    _fetchNotices();
  }

  // 🚀 Dynamic Categories based on Role
  List<String> get _categories {
    if (_userRole == 'admin') {
      return [
        'All',
        'Announcement',
        'Holiday',
        'Parents Info',
        'Important Notice',
        'Admin Marquee notice',
        'Teacher Marquee notice',
      ];
    }
    return [
      'All',
      'Announcement',
      'Holiday',
      'Parents Info',
      'Important Notice',
    ];
  }

  List<String> get _formCategories {
    return [
      'Announcement',
      'Holiday',
      'Parents Info',
      'Important Notice',
      'Admin Marquee notice',
      'Teacher Marquee notice',
    ];
  }

  // 🚀 1. GET: Fetch Notices
  Future<void> _fetchNotices() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        setState(() {
          _allNotices = decodedData['data'] ?? [];
          _filterData();
          _isLoading = false;
        });
      } else {
        setState(() {
          _allNotices = [];
          _filteredNotices = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("API Error: $e");
      setState(() {
        _allNotices = [];
        _filteredNotices = [];
        _isLoading = false;
      });
    }
  }

  // 🚀 2. Filter Logic (Role Based)
  void _filterData() {
    setState(() {
      // Teacher ko Marquee notices nahi dikhenge
      List<dynamic> accessibleNotices = _userRole == 'admin'
          ? _allNotices
          : _allNotices
                .where(
                  (n) =>
                      n['category'] != 'Admin Marquee notice' &&
                      n['category'] != 'Teacher Marquee notice',
                )
                .toList();

      if (_selectedCategoryFilter == 'All') {
        _filteredNotices = accessibleNotices;
      } else {
        _filteredNotices = accessibleNotices
            .where((notice) => notice['category'] == _selectedCategoryFilter)
            .toList();
      }
    });
  }

  // 🚀 3. POST / PUT: Save Notice
  Future<void> _saveNotice({
    String? id,
    required String title,
    required String category,
    required String date,
    required String description,
  }) async {
    try {
      final isEdit = id != null;
      final url = isEdit ? '$_baseUrl/$id' : _baseUrl;
      final payload = {
        "title": title,
        "category": category,
        "date": date,
        "description": description,
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
                isEdit ? '✅ Notice Updated!' : '✅ Notice Published!',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _fetchNotices();
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error saving notice.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // 🚀 4. DELETE: Delete Notice
  Future<void> _deleteNoticeAPI(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/$id'));
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🗑️ Notice Deleted!"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _fetchNotices();
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error deleting notice.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // 📅 Date Picker Helper
  Future<String?> _selectDate(BuildContext context, String initialDate) async {
    DateTime parsedDate = initialDate.isNotEmpty
        ? (DateTime.tryParse(initialDate) ?? DateTime.now())
        : DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: parsedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF059669)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) return picked.toString().split(' ')[0];
    return null;
  }

  // 📝 Bottom Sheet Form
  void _showNoticeDialog({Map<String, dynamic>? existingNotice}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = existingNotice != null;

    final noticeId = isEdit ? existingNotice['id'].toString() : null;
    final titleCtrl = TextEditingController(
      text: isEdit ? existingNotice['title']?.toString() ?? '' : '',
    );
    final descCtrl = TextEditingController(
      text: isEdit ? existingNotice['description']?.toString() ?? '' : '',
    );
    String selectedCat = isEdit
        ? existingNotice['category']?.toString() ?? 'Announcement'
        : 'Announcement';

    String todayStr = DateTime.now().toString().split(' ')[0];
    String selectedDate = isEdit
        ? existingNotice['date']?.toString() ?? todayStr
        : todayStr;
    if (selectedDate.length > 10) selectedDate = selectedDate.substring(0, 10);

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
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
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
                      isEdit ? "✏️ Edit Notice" : "📢 Publish New Notice",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 25),

                    TextFormField(
                      controller: titleCtrl,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: "Notice Title",
                        labelStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(
                          Icons.title,
                          color: Color(0xFF059669),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
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
                                value: selectedCat,
                                isExpanded: true,
                                dropdownColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                items: _formCategories
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setModalState(() => selectedCat = val);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              String? pickedDate = await _selectDate(
                                context,
                                selectedDate,
                              );
                              if (pickedDate != null)
                                setModalState(() => selectedDate = pickedDate);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedDate,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    color: Color(0xFF059669),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: descCtrl,
                      maxLines: 4,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: "Notice Description",
                        labelStyle: TextStyle(color: Colors.grey.shade500),
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(
                          Icons.description_rounded,
                          color: Color(0xFF059669),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleCtrl.text.isEmpty || descCtrl.text.isEmpty)
                            return;
                          Navigator.pop(context);
                          _saveNotice(
                            id: noticeId,
                            title: titleCtrl.text,
                            category: selectedCat,
                            date: selectedDate,
                            description: descCtrl.text,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isEdit ? "UPDATE NOTICE" : "PUBLISH NOTICE",
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
      },
    );
  }

  void _confirmDelete(String id, String title) {
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
            Text("Delete Notice?"),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '$title'?",
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
              _deleteNoticeAPI(id);
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

  // 🚀 REACT WALE COLORS AUR ICONS
  Map<String, dynamic> _getCategoryDetails(String category) {
    switch (category) {
      case 'Holiday':
        return {
          'color': const Color(0xFF10B981),
          'icon': Icons.beach_access_rounded,
        }; // Green
      case 'Parents Info':
        return {
          'color': Colors.purpleAccent,
          'icon': Icons.family_restroom_rounded,
        };
      case 'Important Notice':
        return {'color': Colors.redAccent, 'icon': Icons.warning_rounded};
      case 'Admin Marquee notice':
        return {'color': Colors.teal, 'icon': Icons.smart_display_rounded};
      case 'Teacher Marquee notice':
        return {'color': Colors.cyan, 'icon': Icons.smart_display_rounded};
      case 'Announcement':
      default:
        return {'color': Colors.blueAccent, 'icon': Icons.campaign_rounded};
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = _userRole == 'admin'; // 🚀 Check if user is Admin

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎛️ TOP CONTROL: Header
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
                      "Announcements",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Notice Board",
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
                      value: _selectedCategoryFilter,
                      icon: const Icon(
                        Icons.filter_list_rounded,
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
                      items: _categories
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setState(() {
                            _selectedCategoryFilter = val;
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

          // 📢 NOTICES LIST
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)),
                  )
                : _filteredNotices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.campaign_rounded,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "No Notices Found",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isAdmin)
                          Text(
                            "Click + to publish a new announcement",
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
                    itemCount: _filteredNotices.length,
                    itemBuilder: (context, index) {
                      final notice = _filteredNotices[index];
                      final id = notice['id'].toString();
                      final title = notice['title']?.toString() ?? 'No Title';
                      final desc = notice['description']?.toString() ?? '';
                      final category =
                          notice['category']?.toString() ?? 'Announcement';

                      String dateStr =
                          notice['date']?.toString() ??
                          notice['created_at']?.toString() ??
                          '';
                      if (dateStr.length > 10)
                        dateStr = dateStr.substring(0, 10);

                      final catDetails = _getCategoryDetails(category);
                      final catColor = catDetails['color'] as Color;
                      final catIcon = catDetails['icon'] as IconData;

                      return Container(
                        margin: EdgeInsets.only(bottom: isDark ? 30 : 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.shade100,
                          ),

                          boxShadow: !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TOP BADGE ROW
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(catIcon, color: catColor, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        category.toUpperCase(),
                                        style: TextStyle(
                                          color: catColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.event_note_rounded,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // CONTENT AREA
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 15),

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
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Text(
                                      desc,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade600,
                                        fontSize: 14,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  // 🚀 SIRF ADMIN KO DIKHENGE EDIT/DELETE BUTTONS
                                  if (isAdmin) ...[
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _showNoticeDialog(
                                            existingNotice: notice,
                                          ),
                                          icon: const Icon(
                                            Icons.edit_rounded,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            "Edit",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.blueAccent,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _confirmDelete(id, title),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            "Delete",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
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

      // 🚀 SIRF ADMIN KO DIKHEGA FLOATING BUTTON
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showNoticeDialog(),
              backgroundColor: const Color(0xFF059669),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              icon: const Icon(
                Icons.campaign_rounded,
                color: Colors.white,
                size: 24,
              ),
              label: const Text(
                "Publish Notice",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            )
          : null, // Teacher ko FAB nahi dikhega
    );
  }
}
