import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeeManagementScreen extends StatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen> {
  final String _baseUrl = 'http://10.0.2.2:5000/api';
  String _activeTab = 'Collection';
  bool _isLoading = false;

  // --- STATE VARIABLES ---
  // 1. Collection
  String _searchQuery = '';
  Map<String, dynamic>? _selectedStudent;
  final _payAmountCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  String _discountReason = '';
  String _paymentMode = 'Cash';

  // 2. Status
  List<dynamic> _allFeeStatus = [];
  String _feeStatusSearch = '';

  // 3. Structure
  String _structClass = '8';
  final _tuitionCtrl = TextEditingController(text: '1500');
  final _computerCtrl = TextEditingController(text: '200');
  final _examCtrl = TextEditingController(text: '500');

  // 4. Defaulters
  List<dynamic> _defaultersList = [];

  // 5. Ledger / History
  String _ledgerSearch = '';
  List<dynamic> _feeHistoryData = [];
  Map<String, dynamic>? _ledgerStudentInfo;

  // 6. Reports
  List<dynamic> _chartPieData = [];
  List<dynamic> _chartBarData = [];

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
    _switchTab('Collection');
  }

  // ==========================================
  // FETCH DATA FUNCTIONS
  // ==========================================
  Future<void> _fetchAllFeeStatus() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/all-students-fee-status'),
      );
      if (res.statusCode == 200)
        setState(() => _allFeeStatus = jsonDecode(res.body)['students'] ?? []);
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchDefaulters() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/defaulters'));
      if (res.statusCode == 200)
        setState(
          () => _defaultersList = jsonDecode(res.body)['defaulters'] ?? [],
        );
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchStructure(String className) async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/fee-structure/$className'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['structure'];
        if (data != null) {
          _tuitionCtrl.text = data['tuition_fee'].toString();
          _computerCtrl.text = data['computer_fee'].toString();
          _examCtrl.text = data['exam_fee'].toString();
        } else {
          _tuitionCtrl.text = '1500';
          _computerCtrl.text = '200';
          _examCtrl.text = '500';
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/fee-reports'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _chartPieData = data['pieData'] ?? [];
          _chartBarData = data['barData'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _searchStudentForCollection() async {
    if (_searchQuery.isEmpty)
      return _showSnack('Enter Student ID or Name', Colors.red);
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/student-fee-info/$_searchQuery'),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          _selectedStudent = data['student'];
          _payAmountCtrl.text = _selectedStudent!['dues'].toString();
        });
      } else {
        _showSnack(data['message'] ?? 'Student not found', Colors.red);
        setState(() => _selectedStudent = null);
      }
    } catch (e) {
      _showSnack('Server Error', Colors.red);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchLedger() async {
    if (_ledgerSearch.isEmpty)
      return _showSnack('Enter Student ID', Colors.red);
    setState(() => _isLoading = true);
    try {
      final resLedger = await http.get(
        Uri.parse('$_baseUrl/fee-ledger/$_ledgerSearch'),
      );
      final resInfo = await http.get(
        Uri.parse('$_baseUrl/student-fee-info/$_ledgerSearch'),
      );
      if (resLedger.statusCode == 200)
        setState(
          () => _feeHistoryData = jsonDecode(resLedger.body)['history'] ?? [],
        );
      if (resInfo.statusCode == 200)
        setState(
          () => _ledgerStudentInfo = jsonDecode(resInfo.body)['student'],
        );
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isLoading = false);
  }

  // ==========================================
  // ACTION FUNCTIONS
  // ==========================================
  Future<void> _processPayment() async {
    if (_selectedStudent == null || _payAmountCtrl.text.isEmpty) return;

    final discount = _discountCtrl.text.isEmpty
        ? 0
        : int.parse(_discountCtrl.text);
    final paidAmt = int.parse(_payAmountCtrl.text) - discount;
    final generatedReceiptNo =
        "REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

    final payload = {
      "receiptNo": generatedReceiptNo,
      "studentRegId": _selectedStudent!['id'],
      "studentName": _selectedStudent!['name'],
      "className": _selectedStudent!['class'],
      "paidAmount": paidAmt,
      "discount": discount,
      "discountReason": _discountReason,
      "mode": _paymentMode,
    };

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/pay-fee'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (jsonDecode(res.body)['success'] == true) {
        // Show Receipt Modal
        final receiptData = {
          ...payload,
          "roll": _selectedStudent!['roll'],
          "totalAmount": _payAmountCtrl.text,
          "date":
              "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
        };

        setState(() {
          _selectedStudent = null;
          _searchQuery = '';
          _discountCtrl.text = '0';
          _discountReason = '';
        });
        _showReceiptDialog(receiptData);
      } else {
        _showSnack("Payment Failed", Colors.red);
      }
    } catch (e) {
      _showSnack("Server Error", Colors.red);
    }
  }

  Future<void> _saveStructure() async {
    final t = int.tryParse(_tuitionCtrl.text) ?? 0;
    final c = int.tryParse(_computerCtrl.text) ?? 0;
    final e = int.tryParse(_examCtrl.text) ?? 0;
    final total = t + c + e;

    final payload = {
      "className": _structClass,
      "class_name": _structClass,
      "tuitionFee": t,
      "tuition_fee": t,
      "computerFee": c,
      "computer_fee": c,
      "examFee": e,
      "exam_fee": e,
      "totalFee": total,
      "total_fee": total,
    };

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/fee-structure'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (jsonDecode(res.body)['success'] == true)
        _showSnack("Fee Structure Saved Successfully!", Colors.green);
    } catch (err) {
      _showSnack("Failed to save structure", Colors.red);
    }
  }

  void _sendWhatsAppReminder(String name, String phone, dynamic amount) {
    // Note: Since we are avoiding extra packages, we show a Snackbar simulation.
    // In real app with url_launcher, use: launchUrlString("https://wa.me/91$phone?text=...");
    _showSnack(
      "WhatsApp Reminder triggered for $name (₹$amount due). Install url_launcher to open WhatsApp directly.",
      Colors.blueAccent,
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _switchTab(String tab) {
    setState(() => _activeTab = tab);
    if (tab == 'Status') _fetchAllFeeStatus();
    if (tab == 'Defaulters') _fetchDefaulters();
    if (tab == 'Structure') _fetchStructure(_structClass);
    if (tab == 'Reports') _fetchReports();
  }

  // ==========================================
  // DIALOGS (RECEIPTS & LEDGER)
  // ==========================================
  void _showReceiptDialog(Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  "Fee Payment Receipt",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const Divider(height: 30),

                _buildReceiptRow("Receipt No", data['receiptNo'], isDark),
                _buildReceiptRow("Date", data['date'], isDark),
                _buildReceiptRow("Payment Mode", data['mode'], isDark),
                const SizedBox(height: 15),
                _buildReceiptRow("Student Name", data['studentName'], isDark),
                _buildReceiptRow(
                  "Class & Roll",
                  "${data['className']} (Roll: ${data['roll']})",
                  isDark,
                ),
                const Divider(height: 30),

                _buildReceiptRow(
                  "Fee Amount",
                  "₹ ${data['totalAmount']}",
                  isDark,
                ),
                if ((data['discount'] ?? 0) > 0)
                  _buildReceiptRow(
                    "Discount (${data['discountReason']})",
                    "- ₹ ${data['discount']}",
                    isDark,
                    isRed: true,
                  ),
                const Divider(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Paid",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      "₹ ${data['paidAmount']}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Cashier Sign\n-----------",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      "Parent Sign\n-----------",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showSnack("Print function invoked", Colors.blue),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text("Print Receipt"),
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

  void _showLedgerPrintDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
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
                    Text(
                      "Complete Fee Statement",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                    ),
                  ],
                ),
                const Divider(),
                _buildReceiptRow(
                  "Student Name",
                  _feeHistoryData[0]['student_name'],
                  isDark,
                ),
                _buildReceiptRow(
                  "Registration ID",
                  _feeHistoryData[0]['student_reg_id'],
                  isDark,
                ),
                _buildReceiptRow(
                  "Class",
                  _feeHistoryData[0]['class_name'],
                  isDark,
                ),
                const SizedBox(height: 15),

                // History List inside dialog
                ..._feeHistoryData.map((row) {
                  String date =
                      row['payment_date']?.toString().substring(0, 10) ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row['receipt_no'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              "$date | ${row['payment_mode']}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "+ ₹${row['paid_amount']}",
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                _buildReceiptRow(
                  "Total Course Fee",
                  "₹ ${_ledgerStudentInfo?['totalFee'] ?? 0}",
                  isDark,
                ),
                _buildReceiptRow(
                  "Total Paid",
                  "₹ ${_ledgerStudentInfo?['paid'] ?? 0}",
                  isDark,
                ),
                _buildReceiptRow(
                  "Total Due",
                  "₹ ${_ledgerStudentInfo?['dues'] ?? 0}",
                  isDark,
                  isRed: true,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showSnack("Print function invoked", Colors.blue),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text("Print Statement"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
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

  Widget _buildReceiptRow(
    String label,
    String value,
    bool isDark, {
    bool isRed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isRed
                  ? Colors.redAccent
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MAIN UI BUILDERS
  // ==========================================
  Widget _buildTabButton(String title, IconData icon, bool isDark) {
    final isActive = _activeTab == title;
    return GestureDetector(
      onTap: () => _switchTab(title),
      child: Container(
        margin: const EdgeInsets.only(right: 10, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF059669)
              : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade300),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.grey.shade300 : Colors.black87),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
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
          // 🎛️ TOP HEADER & TABS
          Container(
            padding: const EdgeInsets.only(top: 20, bottom: 5),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Accounts",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Fee Management",
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
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 36,
                        color: Color(0xFF059669),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildTabButton(
                        'Collection',
                        Icons.payments_rounded,
                        isDark,
                      ),
                      _buildTabButton(
                        'Status',
                        Icons.fact_check_rounded,
                        isDark,
                      ),
                      _buildTabButton(
                        'Structure',
                        Icons.settings_rounded,
                        isDark,
                      ),
                      _buildTabButton(
                        'Defaulters',
                        Icons.warning_rounded,
                        isDark,
                      ),
                      _buildTabButton('Ledger', Icons.history_rounded, isDark),
                      _buildTabButton(
                        'Reports',
                        Icons.pie_chart_rounded,
                        isDark,
                      ),
                    ],
                  ),
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
                : _buildActiveTabContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(bool isDark) {
    switch (_activeTab) {
      case 'Collection':
        return _buildCollectionTab(isDark);
      case 'Status':
        return _buildStatusTab(isDark);
      case 'Structure':
        return _buildStructureTab(isDark);
      case 'Defaulters':
        return _buildDefaultersTab(isDark);
      case 'Ledger':
        return _buildLedgerTab(isDark);
      case 'Reports':
        return _buildReportsTab(isDark);
      default:
        return const Center(child: Text("Tab Under Construction"));
    }
  }

  // ==========================================
  // TAB 1: COLLECTION
  // ==========================================
  Widget _buildCollectionTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => _searchQuery = val,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter Student ID or Name...",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _searchStudentForCollection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Search",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_selectedStudent != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
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
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedStudent!['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            "Class: ${_selectedStudent!['class']} | Roll: ${_selectedStudent!['roll']}",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Fee",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "₹${_selectedStudent!['totalFee']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Pending Dues",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "₹${_selectedStudent!['dues']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 30),

                  // Payment Form
                  _buildInputField(
                    "Paying Amount (₹)",
                    _payAmountCtrl,
                    Icons.currency_rupee_rounded,
                    isDark,
                  ),
                  const SizedBox(height: 15),
                  _buildInputField(
                    "Discount Amount (₹)",
                    _discountCtrl,
                    Icons.local_offer_rounded,
                    isDark,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          "Mode",
                          ['Cash', 'UPI', 'Cheque', 'DD'],
                          _paymentMode,
                          (v) => setState(() => _paymentMode = v!),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDropdown(
                          "Reason",
                          [
                            'None',
                            'Sibling Discount',
                            'Staff Child',
                            'Scholarship',
                          ],
                          _discountReason,
                          (v) => setState(() => _discountReason = v!),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _selectedStudent!['dues'] == 0
                          ? null
                          : _processPayment,
                      icon: Icon(
                        _selectedStudent!['dues'] == 0
                            ? Icons.check_circle
                            : Icons.receipt_long_rounded,
                      ),
                      label: Text(
                        _selectedStudent!['dues'] == 0
                            ? "No Pending Dues"
                            : "Collect & Generate Receipt",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: STATUS (All Students)
  // ==========================================
  Widget _buildStatusTab(bool isDark) {
    List<dynamic> filteredList = _allFeeStatus.where((s) {
      final search = _feeStatusSearch.toLowerCase();
      return (s['name']?.toString().toLowerCase().contains(search) ?? false) ||
          (s['id']?.toString().toLowerCase().contains(search) ?? false) ||
          (s['class']?.toString().toLowerCase().contains(search) ?? false);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
              ),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _feeStatusSearch = val),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Live Search Name, ID or Class...",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
              ),
            ),
          ),
        ),
        Expanded(
          child: filteredList.isEmpty
              ? const Center(child: Text("No students found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredList.length,
                  itemBuilder: (context, i) =>
                      _buildStudentCard(filteredList[i], isDark),
                ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: STRUCTURE
  // ==========================================
  Widget _buildStructureTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(25),
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
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Class",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            _buildDropdown("Class", _classes, _structClass, (v) {
              setState(() => _structClass = v!);
              _fetchStructure(v!);
            }, isDark),
            const Divider(height: 40),

            _buildInputField(
              "Tuition Fee (₹)",
              _tuitionCtrl,
              Icons.school_rounded,
              isDark,
            ),
            const SizedBox(height: 15),
            _buildInputField(
              "Computer Fee (₹)",
              _computerCtrl,
              Icons.computer_rounded,
              isDark,
            ),
            const SizedBox(height: 15),
            _buildInputField(
              "Exam Fee (₹)",
              _examCtrl,
              Icons.menu_book_rounded,
              isDark,
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _saveStructure,
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  "Save Master Structure",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 4: DEFAULTERS
  // ==========================================
  Widget _buildDefaultersTab(bool isDark) {
    if (_defaultersList.isEmpty)
      return const Center(
        child: Text(
          "No Pending Dues! 🎉",
          style: TextStyle(
            fontSize: 18,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _defaultersList.length,
      itemBuilder: (context, i) =>
          _buildStudentCard(_defaultersList[i], isDark, isDefaulter: true),
    );
  }

  // ==========================================
  // TAB 5: LEDGER (HISTORY)
  // ==========================================
  Widget _buildLedgerTab(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => _ledgerSearch = val,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter Student ID...",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      prefixIcon: const Icon(
                        Icons.history,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _fetchLedger,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Ledger",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_feeHistoryData.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  IconButton(
                    onPressed: _showLedgerPrintDialog,
                    icon: const Icon(
                      Icons.print_rounded,
                      color: Color(0xFF059669),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF059669,
                      ).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        Expanded(
          child: _feeHistoryData.isEmpty
              ? Center(
                  child: Text(
                    "Search to view history",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _feeHistoryData.length,
                  itemBuilder: (context, i) {
                    final row = _feeHistoryData[i];
                    String date =
                        row['payment_date']?.toString().substring(0, 10) ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade200,
                        ),
                        boxShadow: !isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.receipt_long_rounded,
                                    size: 16,
                                    color: Colors.blueAccent,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    row['receipt_no'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "$date • ${row['payment_mode']}",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "+ ₹${row['paid_amount']}",
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 5),
                              InkWell(
                                onTap: () {
                                  _showReceiptDialog({
                                    "receiptNo": row['receipt_no'],
                                    "studentName": row['student_name'],
                                    "className": row['class_name'],
                                    "roll": "-",
                                    "date": date,
                                    "mode": row['payment_mode'],
                                    "totalAmount":
                                        (Number(row['paid_amount']) +
                                                Number(
                                                  row['discount_amount'] ?? 0,
                                                ))
                                            .toString(),
                                    "discount": row['discount_amount'] ?? 0,
                                    "discountReason":
                                        row['discount_reason'] ?? '',
                                    "paidAmount": row['paid_amount'],
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "View Receipt",
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 11,
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
      ],
    );
  }

  // ==========================================
  // TAB 6: REPORTS (Native Flutter Implementation without Extra Packages)
  // ==========================================
  Widget _buildReportsTab(bool isDark) {
    if (_chartPieData.isEmpty)
      return const Center(child: Text("Loading Analytics..."));

    final collected =
        double.tryParse(_chartPieData[0]['value'].toString()) ?? 0;
    final pending = double.tryParse(_chartPieData[1]['value'].toString()) ?? 0;
    final total = collected + pending;
    final collectedPercent = total > 0 ? (collected / total) : 0.0;

    // Helper to get max value for manual bar chart scaling
    double maxBarVal = 0;
    for (var item in _chartBarData) {
      final val = double.tryParse(item['amount'].toString()) ?? 0;
      if (val > maxBarVal) maxBarVal = val;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // PIE CHART REPLACEMENT (SUMMARY RING)
          Container(
            padding: const EdgeInsets.all(25),
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
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Column(
              children: [
                Text(
                  "Overall Collection Summary",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 15,
                        color: Colors.redAccent.withValues(alpha: 0.2),
                      ),
                      CircularProgressIndicator(
                        value: collectedPercent,
                        strokeWidth: 15,
                        color: const Color(0xFF059669),
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Text(
                          "${(collectedPercent * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          "Collected",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        Text(
                          "₹$collected",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          "Pending",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        Text(
                          "₹$pending",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // NATIVE BAR CHART
          Container(
            padding: const EdgeInsets.all(25),
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
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Monthly Collections",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _chartBarData.map((data) {
                      final val =
                          double.tryParse(data['amount'].toString()) ?? 0;
                      final heightRatio = maxBarVal > 0 ? (val / maxBarVal) : 0;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "₹$val",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 30,
                            height: 150 * heightRatio.toDouble(),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            data['name'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE COMPONENTS ---
  Widget _buildStudentCard(
    Map<String, dynamic> student,
    bool isDark, {
    bool isDefaulter = false,
  }) {
    final dues = int.tryParse(student['dues'].toString()) ?? 0;
    final isPaid = dues <= 0;
    final statusColor = isPaid ? const Color(0xFF059669) : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
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
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: ${student['id']} | Class: ${student['class']}",
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPaid ? "PAID" : "DUE: ₹$dues",
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Course Fee",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${student['total_fee'] ?? student['totalFee']}",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Amount Paid",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${student['amount_paid'] ?? student['paid']}",
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isDefaulter || !isPaid) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: () => _sendWhatsAppReminder(
                  student['name'],
                  student['phone']?.toString() ?? '',
                  dues,
                ),
                icon: const Icon(Icons.message_rounded, size: 18),
                label: const Text(
                  "Send WhatsApp Reminder",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController ctrl,
    IconData icon,
    bool isDark,
  ) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: const Color(0xFF059669)),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    Function(String?) onChanged,
    bool isDark,
  ) {
    // Agar dropdown ki default value list mein na ho (like empty string logic), to list check karte hain
    final validValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Parse helper
  num Number(dynamic val) => num.tryParse(val.toString()) ?? 0;
}
