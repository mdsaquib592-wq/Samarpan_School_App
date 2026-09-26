import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Naya: API Call ke liye
import 'dart:convert'; // Naya: JSON parse karne ke liye
import 'package:shared_preferences/shared_preferences.dart'; // Naya: Session save karne ke liye

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // Loading spinner ke liye

  // 🚀 FIX: Asli API Call Backend ke sath
  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username aur Password dono zaroori hain!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Android Emulator ke liye localhost ki jagah 10.0.2.2 use hota hai
    final url = Uri.parse('http://10.0.2.2:5000/api/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        // 🟢 Login Success: Data save karein
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userRole', data['role'] ?? '');

        // User ka naam save karein (agar backend se nahi aata toh username save karein)
        String name = _usernameController.text;
        if (data['user'] != null && data['user']['name'] != null) {
          name = data['user']['name'];
        } else if (data['user'] != null && data['user']['username'] != null) {
          name = data['user']['username'];
        }
        await prefs.setString('adminName', name);

        // 🚀 Dashboard par bhejein
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        // 🔴 Login Failed: Error message dikhayein
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Login fail ho gaya!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("API Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Server se connect nahi ho paya. Kya Node.js backend chalu hai?',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(30.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF8FAFC),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black45
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 35,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Image.asset(
                      isDark ? 'assets/night.png' : 'assets/SAMARPAN-LOGO.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Title
                  Text(
                    "Samarpan School",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Login to your Portal",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Username Input
                  TextField(
                    controller: _usernameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Username / Login ID",
                      hintStyle: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                      enabledBorder: _outlineBorder(isDark),
                      focusedBorder: _focusBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Password Input
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                      enabledBorder: _outlineBorder(isDark),
                      focusedBorder: _focusBorder(),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Forgot Password
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF2F2F2F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _outlineBorder(bool isDark) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
      ),
    );
  }

  OutlineInputBorder _focusBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
    );
  }
}
