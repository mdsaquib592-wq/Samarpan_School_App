import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final String _baseUrl = 'http://10.0.2.2:5000/api';
  bool _isBackingUp = false;
  String? _backupStatus;
  String? _errorStatus;

  Future<void> _handleBackup() async {
    setState(() {
      _isBackingUp = true;
      _backupStatus = null;
      _errorStatus = null;
    });

    try {
      // 🟢 Server ki backup API ko call lagayenge
      final response = await http.get(Uri.parse('$_baseUrl/backup/download'));

      if (response.statusCode == 200) {
        setState(() {
          _backupStatus =
              "✅ Backup successfully generated on the Server!\n(To download to mobile, install url_launcher package)";
        });
      } else {
        setState(() {
          _errorStatus = "Backup file generate nahi ho payi. Server error!";
        });
      }
    } catch (error) {
      setState(() {
        _errorStatus =
            "Server se connect nahi ho pa raha hai. Kripya connection check karein.";
      });
    } finally {
      setState(() {
        _isBackingUp = false;
      });
    }
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
            width: double.infinity,
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
                      Icons.security_rounded,
                      size: 36,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "System Settings",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Database Backup",
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
              ],
            ),
          ),

          // 🚀 MAIN CONTENT AREA
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_download_rounded,
                      size: 80,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Secure Your School Data",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Take a complete database backup of all students, teachers, fees, and attendance records.",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // 💾 BACKUP CARD
                    Container(
                      width: double.infinity,
                      // 🚀 YAHAN PAR ERROR FIX KIYA HAI!
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade200,
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
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.computer_rounded,
                            size: 50,
                            color: Color(0xFF64748b),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "Local Device Backup",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Click the button below to instantly generate a '.sql' backup file.",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),

                          // STATUS MESSAGES
                          if (_backupStatus != null)
                            Container(
                              padding: const EdgeInsets.all(15),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF059669,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _backupStatus!,
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          if (_errorStatus != null)
                            Container(
                              padding: const EdgeInsets.all(15),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _errorStatus!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // ACTION BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: _isBackingUp ? null : _handleBackup,
                              icon: _isBackingUp
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.download_rounded,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _isBackingUp
                                    ? "Processing Backup..."
                                    : "Download Backup Now",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                disabledBackgroundColor: Colors.grey.shade400,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: _isBackingUp ? 0 : 5,
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
          ),
        ],
      ),
    );
  }
}
