import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/interview_provider.dart';

class MockInterviewScreen extends ConsumerStatefulWidget {
  const MockInterviewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MockInterviewScreen> createState() => _MockInterviewScreenState();
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
    if (state.status == InterviewStatus.answering && state.activeSessionId != null && mounted) {
      context.go('/interview-runner/${state.activeSessionId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final interviewState = ref.watch(interviewProvider);
    final isLoading = interviewState.status == InterviewStatus.generating;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Mock Interview Setup', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.bgDark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner Card
                Card(
                  color: AppColors.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.chipBorder, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppColors.bgPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.record_voice_over, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Mock Interview',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Practice with AI-generated questions tailored to your target role and company',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        if (interviewState.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Text(
                              interviewState.errorMessage!,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Target Role Selection
                        const Text(
                          'Target Role',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _roleSuggestions.contains(_selectedRole) ? _selectedRole : null,
                          dropdownColor: AppColors.bgCard,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Select or type role',
                            prefixIcon: const Icon(Icons.work_outline, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.bgDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.chipBorder),
                            ),
                          ),
                          items: _roleSuggestions.map((r) {
                            return DropdownMenuItem(
                              value: r,
                              child: Text(r, style: const TextStyle(color: AppColors.textPrimary)),
                            );
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
                        const SizedBox(height: 8),
                        TextField(
                          controller: _roleController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Or enter custom role',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            hintText: 'e.g. Mobile Developer',
                            prefixIcon: const Icon(Icons.edit, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.bgDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.chipBorder),
                            ),
                          ),
                          onChanged: (val) => setState(() {}),
                        ),
                        const SizedBox(height: 20),

                        // Target Company Selection
                        const Text(
                          'Target Company',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _companySuggestions.contains(_selectedCompany) ? _selectedCompany : null,
                          dropdownColor: AppColors.bgCard,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Select or type company',
                            prefixIcon: const Icon(Icons.business, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.bgDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.chipBorder),
                            ),
                          ),
                          items: _companySuggestions.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c, style: const TextStyle(color: AppColors.textPrimary)),
                            );
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
                        const SizedBox(height: 8),
                        TextField(
                          controller: _companyController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Or enter custom company',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            hintText: 'e.g. TechCorp Solutions',
                            prefixIcon: const Icon(Icons.edit, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.bgDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.chipBorder),
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
                            onPressed: (isLoading ||
                                    _roleController.text.trim().isEmpty ||
                                    _companyController.text.trim().isEmpty)
                                ? null
                                : _handleStartInterview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bgPurple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.chipBorder,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Generating 6 Tailored Questions...',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Start Interview',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
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
}
