import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';

class AdmissionScreen extends StatefulWidget {
  const AdmissionScreen({super.key});

  @override
  State<AdmissionScreen> createState() => _AdmissionScreenState();
}

class _AdmissionScreenState extends State<AdmissionScreen> {
  final _formKey = GlobalKey<FormState>();

  // 🆔 ID Generator (React wala)
  String generateId() {
    return 'SV${1000 + Random().nextInt(9000)}';
  }

  // 📝 Text Controllers (Saari fields)
  late final TextEditingController _regIdCtrl;
  final _nameCtrl = TextEditingController();
  final _rollNoCtrl = TextEditingController();
  final _motherTongueCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _fatherQualCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _motherQualCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _contactFCtrl = TextEditingController();
  final _contactMCtrl = TextEditingController();
  final _contactHCtrl = TextEditingController();
  final _localGuardianCtrl = TextEditingController();
  final _permAddressCtrl = TextEditingController();
  final _localAddressCtrl = TextEditingController();

  // 🔽 Dropdown States
  String? _className;
  String? _gender;
  String? _bloodGroup;

  // 📅 Date States
  DateTime? _dob;
  DateTime? _doa;

  // 📷 Image State
  File? _image;
  String? _base64Image;
  bool _isSubmitting = false;

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
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  @override
  void initState() {
    super.initState();
    _regIdCtrl = TextEditingController(text: generateId());
  }

  @override
  void dispose() {
    _regIdCtrl.dispose();
    _nameCtrl.dispose();
    _rollNoCtrl.dispose();
    _motherTongueCtrl.dispose();
    _aadharCtrl.dispose();
    _fatherNameCtrl.dispose();
    _fatherQualCtrl.dispose();
    _motherNameCtrl.dispose();
    _motherQualCtrl.dispose();
    _occupationCtrl.dispose();
    _contactFCtrl.dispose();
    _contactMCtrl.dispose();
    _contactHCtrl.dispose();
    _localGuardianCtrl.dispose();
    _permAddressCtrl.dispose();
    _localAddressCtrl.dispose();
    super.dispose();
  }

  // 📷 Photo Picker Logic (With Base64 Conversion for API)
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    ); // Quality 50 to keep under 2MB
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();

      // Check size < 2MB
      if (bytes.lengthInBytes > 2 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Please upload an image smaller than 2MB.'),
          ),
        );
        return;
      }

      setState(() {
        _image = file;
        _base64Image =
            "data:image/jpeg;base64,${base64Encode(bytes)}"; // React format
      });
    }
  }

  // 📅 Date Picker Helper
  Future<void> _selectDate(BuildContext context, bool isDob) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
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
    if (picked != null) {
      setState(() {
        if (isDob)
          _dob = picked;
        else
          _doa = picked;
      });
    }
  }

  // 🚀 SUBMIT TO API (React logic)
  Future<void> _submitAdmission() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please fill required fields.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // API Payload map (Matching React state exactly)
    final payload = {
      "registrationId": _regIdCtrl.text,
      "fullName": _nameCtrl.text,
      "gender": _gender ?? "",
      "motherTongue": _motherTongueCtrl.text,
      "dob": _dob != null
          ? "${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}"
          : "",
      "doa": _doa != null
          ? "${_doa!.year}-${_doa!.month.toString().padLeft(2, '0')}-${_doa!.day.toString().padLeft(2, '0')}"
          : "",
      "fatherName": _fatherNameCtrl.text,
      "fatherQual": _fatherQualCtrl.text,
      "motherName": _motherNameCtrl.text,
      "motherQual": _motherQualCtrl.text,
      "occupation": _occupationCtrl.text,
      "aadharNo": _aadharCtrl.text,
      "bloodGroup": _bloodGroup ?? "",
      "contactF": _contactFCtrl.text,
      "contactM": _contactMCtrl.text,
      "contactH": _contactHCtrl.text,
      "localGuardian": _localGuardianCtrl.text,
      "className": _className ?? "",
      "rollNo": _rollNoCtrl.text,
      "permAddress": _permAddressCtrl.text,
      "localAddress": _localAddressCtrl.text,
      "photo": _base64Image ?? "",
    };

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/students'), // Emulators localhost
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Student Admission Successful!'),
              backgroundColor: Colors.green,
            ),
          );

          // Form Reset (React jaisa)
          _formKey.currentState!.reset();
          setState(() {
            _regIdCtrl.text = generateId();
            _nameCtrl.clear();
            _rollNoCtrl.clear();
            _motherTongueCtrl.clear();
            _aadharCtrl.clear();
            _fatherNameCtrl.clear();
            _fatherQualCtrl.clear();
            _motherNameCtrl.clear();
            _motherQualCtrl.clear();
            _occupationCtrl.clear();
            _contactFCtrl.clear();
            _contactMCtrl.clear();
            _contactHCtrl.clear();
            _localGuardianCtrl.clear();
            _permAddressCtrl.clear();
            _localAddressCtrl.clear();
            _className = null;
            _gender = null;
            _bloodGroup = null;
            _dob = null;
            _doa = null;
            _image = null;
            _base64Image = null;
          });
        }
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error saving student data.'),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Server Error!'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ====================== UI BUILDER ======================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🟢 MAIN CARD
              Container(
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "New Student Admission",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const Divider(height: 30),

                    // --- 1. STUDENT PARTICULARS ---
                    _buildSectionTitle("1. Student Particulars", isDark),

                    // Photo Upload (React CSS Jaisa)
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF8FAFC),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                image: _image != null
                                    ? DecorationImage(
                                        image: FileImage(_image!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _image == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          size: 30,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "No Photo",
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Max file size: 2MB. Format: JPG, PNG.",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Grid Inputs
                    _buildTextField(
                      "Registration ID",
                      _regIdCtrl,
                      isReadOnly: true,
                      color: const Color(0xFF059669),
                    ),
                    _buildTextField(
                      "Name of the Student (In Block Letters)",
                      _nameCtrl,
                      isRequired: true,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            "Class to Admission",
                            _className,
                            _classes,
                            (val) => setState(() => _className = val),
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField("Roll Number", _rollNoCtrl),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown("Sex", _gender, [
                            'Male',
                            'Female',
                          ], (val) => setState(() => _gender = val)),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildDropdown(
                            "Blood Group",
                            _bloodGroup,
                            _bloodGroups,
                            (val) => setState(() => _bloodGroup = val),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            "Date of Birth",
                            _dob,
                            true,
                            context,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildDateField(
                            "Date of Admission",
                            _doa,
                            false,
                            context,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Mother Tongue",
                            _motherTongueCtrl,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            "Aadhar No.",
                            _aadharCtrl,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),
                    // --- 2. PARENTS DETAILS ---
                    _buildSectionTitle("2. Parents Details", isDark),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Father's Name",
                            _fatherNameCtrl,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            "Father's Qualification",
                            _fatherQualCtrl,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Mother's Name",
                            _motherNameCtrl,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            "Mother's Qualification",
                            _motherQualCtrl,
                          ),
                        ),
                      ],
                    ),
                    _buildTextField("Occupation (Parents)", _occupationCtrl),

                    const SizedBox(height: 25),
                    // --- 3. CONTACT & ADDRESS ---
                    _buildSectionTitle("3. Contact & Address", isDark),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Mob (F) - Father",
                            _contactFCtrl,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            "Mob (M) - Mother",
                            _contactMCtrl,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Mob (H) - Home",
                            _contactHCtrl,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            "Local Guardian",
                            _localGuardianCtrl,
                          ),
                        ),
                      ],
                    ),

                    _buildTextField(
                      "Permanent Address",
                      _permAddressCtrl,
                      maxLines: 2,
                    ),
                    _buildTextField(
                      "Local/Guardian Address",
                      _localAddressCtrl,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 30),

                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitAdmission,
                        icon: _isSubmitting
                            ? const SizedBox()
                            : const Icon(Icons.person_add_alt_1),
                        label: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Submit Admission Form",
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🛠️ HELPER WIDGETS
  Widget _buildSectionTitle(String title, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        border: const Border(
          left: BorderSide(color: Color(0xFF059669), width: 4),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[300] : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
    bool isReadOnly = false,
    bool isRequired = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            maxLines: maxLines,
            readOnly: isReadOnly,
            style: TextStyle(
              color: color,
              fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              filled: isReadOnly,
              fillColor: isReadOnly ? Colors.grey.withValues(alpha: 0.1) : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF059669)),
              ),
            ),
            validator: isRequired
                ? (value) => value!.isEmpty ? 'Required' : null
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: const TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: isRequired
                ? (val) => val == null ? 'Required' : null
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value,
    bool isDob,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 5),
          InkWell(
            onTap: () => _selectDate(context, isDob),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value != null
                        ? "${value.day}/${value.month}/${value.year}"
                        : "DD/MM/YYYY",
                    style: TextStyle(
                      color: value != null
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
