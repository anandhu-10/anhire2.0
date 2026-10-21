import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/interview_provider.dart';
import '../../widgets/app_components.dart';

class MockInterviewScreen extends ConsumerStatefulWidget {
  const MockInterviewScreen({super.key});

  @override
  ConsumerState<MockInterviewScreen> createState() =>
      _MockInterviewScreenState();
}

class _MockInterviewScreenState extends ConsumerState<MockInterviewScreen> {
  final _roleController = TextEditingController();
  final _companyController = TextEditingController();

  String _selectedRole = 'Software Engineer';
  String _selectedCompany = 'Google';

  final List<String> _roleSuggestions = [
    'Software Engineer',
    'Frontend Developer',
    'Backend Developer',
    'Full Stack Developer',
    'Data Analyst',
    'Data Scientist',
    'DevOps Engineer',
    'QA Engineer',
    'Product Manager',
  ];

  final List<String> _companySuggestions = [
    'Google',
    'Microsoft',
    'Amazon',
    'TCS',
    'Infosys',
    'Accenture',
    'Wipro',
    'Cognizant',
    'IBM',
    'Deloitte',
    'Flipkart',
    'Zoho',
  ];

  @override
  void initState() {
    super.initState();
    _roleController.text = _selectedRole;
    _companyController.text = _selectedCompany;
  }

  @override
  void dispose() {
    _roleController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _handleStartInterview() async {
    final role = _roleController.text.trim();
    final company = _companyController.text.trim();

    if (role.isEmpty || company.isEmpty) return;

    final notifier = ref.read(interviewProvider.notifier);
    await notifier.startInterview(role, company);

    final state = ref.read(interviewProvider);
    if (state.status == InterviewStatus.answering &&
        state.activeSessionId != null &&
        mounted) {
      context.go('/interview-runner/${state.activeSessionId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final interviewState = ref.watch(interviewProvider);
    final isLoading = interviewState.status == InterviewStatus.generating;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.appRootBg,
      appBar: AppBar(
        title: Text(
          'Mock Interview Setup',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner Card
                AppCard(
                  padding: const EdgeInsets.all(26.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF7C3AED,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.record_voice_over_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Mock Interview',
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: context.appTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Practice with tailored technical & behavioral questions designed for your target company recruitment round',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: context.appTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Divider(color: context.appBorder),
                      const SizedBox(height: 20),

                      if (interviewState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  interviewState.errorMessage!,
                                  style: GoogleFonts.inter(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Target Role Selection
                      Text(
                        'Target Job Role',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Popular Role Quick Selection Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _roleSuggestions.take(5).map((r) {
                            final isSel = _selectedRole == r;
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: 8.0,
                                bottom: 8.0,
                              ),
                              child: ChoiceChip(
                                label: Text(
                                  r,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSel
                                        ? (isDark
                                              ? Colors.white
                                              : AppColors.primary)
                                        : context.appTextSecondary,
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: AppColors.primary.withValues(
                                  alpha: isDark ? 0.25 : 0.12,
                                ),
                                backgroundColor: context.appSurfaceAlt,
                                side: BorderSide(
                                  color: isSel
                                      ? AppColors.primary
                                      : context.appBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _selectedRole = r;
                                      _roleController.text = r;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      DropdownButtonFormField<String>(
                        value: _roleSuggestions.contains(_selectedRole)
                            ? _selectedRole
                            : null,
                        dropdownColor: context.appSurface,
                        style: GoogleFonts.inter(
                          color: context.appTextPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Or select from full catalogue',
                          prefixIcon: Icon(
                            Icons.work_outline_rounded,
                            color: context.appTextSecondary,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: context.appSurfaceAlt,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: context.appBorder),
                          ),
                        ),
                        items: _roleSuggestions.map((r) {
                          return DropdownMenuItem(value: r, child: Text(r));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedRole = val;
                              _roleController.text = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _roleController,
                        style: GoogleFonts.inter(
                          color: context.appTextPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Custom Role Title',
                          hintText: 'e.g. Flutter Mobile Developer',
                          prefixIcon: Icon(
                            Icons.edit_outlined,
                            color: context.appTextSecondary,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: context.appSurfaceAlt,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: context.appBorder),
                          ),
                        ),
                        onChanged: (val) => setState(() {}),
                      ),
                      const SizedBox(height: 22),

                      // Target Company Selection
                      Text(
                        'Target Recruiter / Company',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quick Company Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _companySuggestions.take(6).map((c) {
                            final isSel = _selectedCompany == c;
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: 8.0,
                                bottom: 8.0,
                              ),
                              child: ChoiceChip(
                                label: Text(
                                  c,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSel
                                        ? (isDark
                                              ? Colors.white
                                              : AppColors.primary)
                                        : context.appTextSecondary,
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: AppColors.primary.withValues(
                                  alpha: isDark ? 0.25 : 0.12,
                                ),
                                backgroundColor: context.appSurfaceAlt,
                                side: BorderSide(
                                  color: isSel
                                      ? AppColors.primary
                                      : context.appBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _selectedCompany = c;
                                      _companyController.text = c;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      DropdownButtonFormField<String>(
                        value: _companySuggestions.contains(_selectedCompany)
                            ? _selectedCompany
                            : null,
                        dropdownColor: context.appSurface,
                        style: GoogleFonts.inter(
                          color: context.appTextPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Or select company from list',
                          prefixIcon: Icon(
                            Icons.business_outlined,
                            color: context.appTextSecondary,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: context.appSurfaceAlt,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: context.appBorder),
                          ),
                        ),
                        items: _companySuggestions.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCompany = val;
                              _companyController.text = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _companyController,
                        style: GoogleFonts.inter(
                          color: context.appTextPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Custom Company Name',
                          hintText: 'e.g. Stripe, Palantir, Razorpay',
                          prefixIcon: Icon(
                            Icons.edit_outlined,
                            color: context.appTextSecondary,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: context.appSurfaceAlt,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: context.appBorder),
                          ),
                        ),
                        onChanged: (val) => setState(() {}),
                      ),
                      const SizedBox(height: 28),

                      // Start Interview Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              (isLoading ||
                                  _roleController.text.trim().isEmpty ||
                                  _companyController.text.trim().isEmpty)
                              ? null
                              : _handleStartInterview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: context.appBorder,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Generating 6 Tailored Questions...',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Start Interview Simulation',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
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
      ),
    );
  }
}
