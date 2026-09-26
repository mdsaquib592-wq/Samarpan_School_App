import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SalaryManagementScreen extends StatefulWidget {
  const SalaryManagementScreen({super.key});

  @override
  State<SalaryManagementScreen> createState() => _SalaryManagementScreenState();
}

class _SalaryManagementScreenState extends State<SalaryManagementScreen> {
  final String _baseUrl = 'http://10.0.2.2:5000/api';
  bool _isLoading = false;

  List<dynamic> _salaries = [];
  List<dynamic> _filteredSalaries = [];
  String _searchQuery = '';
  late String _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = _getCurrentMonthString();
    _fetchSalaries();
  }

  String _getCurrentMonthString() {
    final now = DateTime.now();
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return "${months[now.month - 1]} ${now.year}";
  }

  List<String> _getMonthOptions() {
    List<String> options = [];
    final now = DateTime.now();
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    for (int i = 0; i < 6; i++) {
      int m = now.month - 1 - i;
      int y = now.year;
      if (m < 0) {
        m += 12;
        y -= 1;
      }
      options.add("${months[m]} $y");
    }
    return options;
  }

  Future<void> _fetchSalaries() async {
    setState(() => _isLoading = true);
    try {
      final resSalaries = await http.get(
        Uri.parse('$_baseUrl/salaries?month=$_selectedMonth'),
      );
      if (resSalaries.statusCode == 200) {
        final decoded = jsonDecode(resSalaries.body);
        _salaries = (decoded is List) ? decoded : (decoded['salaries'] ?? []);
      }
      _filterSalaries();
    } catch (e) {
      debugPrint("Error fetching salary data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterSalaries() {
    setState(() {
      _filteredSalaries = _salaries.where((s) {
        final search = _searchQuery.toLowerCase();
        final name = (s['name'] ?? '').toString().toLowerCase();
        final id = (s['teacher_id'] ?? '').toString().toLowerCase();
        return name.contains(search) || id.contains(search);
      }).toList();
    });
  }

  Future<void> _handlePayment(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _showSnack(data['message'] ?? "Success", Colors.green);
        _fetchSalaries();
      } else {
        _showSnack(data['message'] ?? "Something went wrong!", Colors.red);
      }
    } catch (e) {
      _showSnack("Server Error. Check Backend.", Colors.red);
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

  void _showPaymentModal({
    required Map<String, dynamic> teacher,
    bool isUpdate = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountCtrl = TextEditingController(
      text: isUpdate ? teacher['amount_paid']?.toString() : '',
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
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUpdate ? "Update Salary" : "Process Salary",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Teacher: ${teacher['name']} (${teacher['teacher_id']})",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                Text(
                  "Month: $_selectedMonth",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 25),

                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: "Enter Amount (₹)",
                    labelStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: const Icon(
                      Icons.currency_rupee_rounded,
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
                      if (amountCtrl.text.isEmpty) return;
                      Navigator.pop(context);
                      final endpoint = isUpdate
                          ? '$_baseUrl/salaries/update'
                          : '$_baseUrl/salaries/pay';
                      _handlePayment(endpoint, {
                        "teacher_id": teacher['teacher_id'],
                        "amount_paid": amountCtrl.text,
                        "payment_month": _selectedMonth,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isUpdate ? "Update Payment" : "Confirm Payment",
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
        );
      },
    );
  }

  void _showSlipModal(Map<String, dynamic> teacher) {
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
                  "Salary Payslip",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const Divider(height: 30),

                _buildReceiptRow("Pay Month", _selectedMonth, isDark),
                _buildReceiptRow(
                  "Print Date",
                  DateTime.now().toIso8601String().split('T')[0],
                  isDark,
                ),
                _buildReceiptRow("Status", "PAID", isDark, isGreen: true),
                const SizedBox(height: 15),

                _buildReceiptRow("Teacher Name", teacher['name'], isDark),
                _buildReceiptRow("Teacher ID", teacher['teacher_id'], isDark),
                _buildReceiptRow(
                  "Subject",
                  teacher['subject'] ?? "N/A",
                  isDark,
                ),
                const Divider(height: 30),

                _buildReceiptRow(
                  "Basic Pay",
                  "₹ ${teacher['amount_paid']}",
                  isDark,
                ),
                _buildReceiptRow("Allowances", "-", isDark),
                const Divider(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "NET PAY",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      "₹ ${teacher['amount_paid']}",
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
                      "Admin Sign\n-----------",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      "Teacher Sign\n-----------",
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
                    label: const Text("Print Slip"),
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

  Widget _buildReceiptRow(
    String label,
    String value,
    bool isDark, {
    bool isGreen = false,
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
              color: isGreen
                  ? Colors.green
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int paidTeachers = _salaries
        .where((s) => s['payment_status']?.toLowerCase() == 'paid')
        .length;
    int pendingTeachers = _salaries.length - paidTeachers;
    double totalAmount = _salaries.fold(
      0,
      (sum, s) =>
          sum + (double.tryParse(s['amount_paid']?.toString() ?? '0') ?? 0),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎛️ TOP HEADER
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
                      "Staff Accounts",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Salary Management",
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
                  Icons.payments_rounded,
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
                            // 🟢 Stats Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    "Total Paid",
                                    "₹${totalAmount.toStringAsFixed(0)}",
                                    Icons.wallet_rounded,
                                    Colors.blueAccent,
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    "Paid Staff",
                                    "$paidTeachers",
                                    Icons.check_circle_rounded,
                                    const Color(0xFF059669),
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    "Pending",
                                    "$pendingTeachers",
                                    Icons.watch_later_rounded,
                                    Colors.redAccent,
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // 🔍 Search & Month Dropdown
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Container(
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
                                        _filterSalaries();
                                      },
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "Search Teacher...",
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
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 2,
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
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedMonth,
                                        isExpanded: true,
                                        dropdownColor: isDark
                                            ? const Color(0xFF1E293B)
                                            : Colors.white,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        items: _getMonthOptions()
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(e),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _selectedMonth = val,
                                            );
                                            _fetchSalaries();
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

                      // 📜 Salary List
                      Expanded(
                        child: _filteredSalaries.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    "No Records Found.",
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: _filteredSalaries.length,
                                itemBuilder: (context, i) {
                                  final s = _filteredSalaries[i];
                                  final isPaid =
                                      s['payment_status']?.toLowerCase() ==
                                      'paid';

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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: isDark
                                                  ? const Color(0xFF0F172A)
                                                  : Colors.grey.shade100,
                                              child: Text(
                                                (s['name'] ?? 'U')[0]
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontWeight: FontWeight.bold,
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
                                                    s['name'] ?? 'N/A',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                  Text(
                                                    "ID: ${s['teacher_id']}",
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isPaid
                                                    ? Colors.green.withOpacity(
                                                        0.1,
                                                      )
                                                    : Colors.red.withOpacity(
                                                        0.1,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                s['payment_status'] ??
                                                    'Pending',
                                                style: TextStyle(
                                                  color: isPaid
                                                      ? Colors.green
                                                      : Colors.redAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              isPaid
                                                  ? "Paid: ₹${s['amount_paid']}"
                                                  : "-",
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (!isPaid)
                                              ElevatedButton(
                                                onPressed: () =>
                                                    _showPaymentModal(
                                                      teacher: s,
                                                      isUpdate: false,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF059669,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 15,
                                                        vertical: 5,
                                                      ),
                                                ),
                                                child: const Text(
                                                  "Pay Now",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )
                                            else
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit_rounded,
                                                      color: Colors.blueAccent,
                                                      size: 20,
                                                    ),
                                                    onPressed: () =>
                                                        _showPaymentModal(
                                                          teacher: s,
                                                          isUpdate: true,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.print_rounded,
                                                      color: Color(0xFF059669),
                                                      size: 20,
                                                    ),
                                                    onPressed: () =>
                                                        _showSlipModal(s),
                                                  ),
                                                ],
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
    );
  }
}
