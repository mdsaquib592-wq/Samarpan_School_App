import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // FAQs List
  final List<Map<String, String>> _faqs = [
    {
      "question": "How to generate a Fee Receipt?",
      "answer":
          "Go to 'Fee Management' > Select 'Ledger' tab > Search for the student ID > Click 'View Receipt' and then hit the Print button.",
    },
    {
      "question": "How do I take a Database Backup?",
      "answer":
          "Navigate to 'Database Backup' from the sidebar menu and click 'Download Backup Now' to save a .sql file securely.",
    },
    {
      "question": "Can I publish a Notice only for Teachers?",
      "answer":
          "Yes, while publishing a notice in the 'Notice Board', select the category 'Teacher Marquee notice'. It will only be visible to staff.",
    },
    {
      "question": "How to add a new subject to a class?",
      "answer":
          "Go to 'Courses' under Academics. Select the class from the top dropdown, then click the floating '+ New Subject' button.",
    },
  ];

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
            child: Row(
              children: [
                const Icon(
                  Icons.help_outline_rounded,
                  size: 36,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Assistance",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Help & Support",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🚀 MAIN CONTENT AREA
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📞 CONTACT CARDS ROW
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isMobile = constraints.maxWidth < 600;
                      return Flex(
                        direction: isMobile ? Axis.vertical : Axis.horizontal,
                        children: [
                          Expanded(
                            flex: isMobile ? 0 : 1,
                            child: _buildContactCard(
                              "School Administration",
                              "For admission & general queries.",
                              Icons.school_rounded,
                              "Samarpan Vidyalaya",
                              "+91 8789765575",
                              "info@samarpan.edu",
                              isDark,
                            ),
                          ),
                          SizedBox(
                            width: isMobile ? 0 : 20,
                            height: isMobile ? 20 : 0,
                          ),
                          Expanded(
                            flex: isMobile ? 0 : 1,
                            child: _buildContactCard(
                              "Technical Support",
                              "For app bugs & system updates.",
                              Icons.code_rounded,
                              "Universe Logic",
                              "Saquib & Md Parwez Alam",
                              "support@universelogic.in",
                              isDark,
                              isTech: true,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 35),

                  // 💬 FAQ SECTION
                  Row(
                    children: [
                      const Icon(
                        Icons.question_answer_rounded,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Frequently Asked Questions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  Container(
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
                                blurRadius: 15,
                                offset: const Offset(0, 5),
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
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: Column(
                        children: _faqs.map((faq) {
                          int index = _faqs.indexOf(faq);
                          return Column(
                            children: [
                              ExpansionTile(
                                iconColor: const Color(0xFF059669),
                                collapsedIconColor: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                title: Text(
                                  faq['question']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(
                                      left: 15,
                                      right: 15,
                                      bottom: 20,
                                      top: 5,
                                    ),
                                    child: Text(
                                      faq['answer']!,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                        height: 1.5,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (index != _faqs.length - 1)
                                Divider(
                                  height: 1,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.shade100,
                                  indent: 15,
                                  endIndent: 15,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      "Samarpan Vidyalaya ERP v1.0.0\nDesigned & Developed by Universe Logic",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎫 REUSABLE CONTACT CARD
  Widget _buildContactCard(
    String title,
    String desc,
    IconData icon,
    String name,
    String sub1,
    String sub2,
    bool isDark, {
    bool isTech = false,
  }) {
    Color themeColor = isTech ? Colors.blueAccent : const Color(0xFF059669);

    return Container(
      padding: const EdgeInsets.all(25),
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
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
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
                  color: themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: themeColor, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: themeColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isTech ? Icons.group_rounded : Icons.phone_rounded,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sub1,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.email_rounded, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sub2,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text(
                    "Call",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.email_rounded, size: 16),
                  label: const Text(
                    "Email",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF0F172A)
                        : Colors.grey.shade100,
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
