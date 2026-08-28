import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/user_repository.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _companyInputController = TextEditingController();
  final _cgpaController = TextEditingController();

  String _selectedBranch = 'CSE';
  String _selectedSemester = 'Semester 7';
  final List<String> _targetCompanies = ['Google', 'Microsoft', 'Amazon'];
  bool _isLoading = false;

  final List<String> _branches = [
    'CSE',
    'ECE',
    'EEE',
    'ME',
    'CE',
    'IT',
    'AI & DS',
  ];

  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  final List<String> _suggestedRoles = [
    'Software Engineer',
    'Data Analyst',
    'Full Stack Developer',
    'DevOps Engineer',
    'Frontend Developer',
  ];

  final List<String> _suggestedCompanies = [
    'Google',
    'Microsoft',
    'Amazon',
    'TCS',
    'Infosys',
    'Wipro',
    'Meta',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      _nameController.text = user.displayName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _companyInputController.dispose();
    _cgpaController.dispose();
    super.dispose();
  }

  void _addCompany(String company) {
    final trimmed = company.trim();
    if (trimmed.isNotEmpty && !_targetCompanies.contains(trimmed)) {
      setState(() {
        _targetCompanies.add(trimmed);
        _companyInputController.clear();
      });
    }
  }

  void _removeCompany(String company) {
    setState(() {
      _targetCompanies.remove(company);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_targetCompanies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one target company')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final user = ref.read(authStateProvider).value;
        if (user == null) throw Exception("Not authenticated");

        final profile = ProfileModel(
          uid: user.uid,
          fullName: _nameController.text.trim(),
          branch: _selectedBranch,
          targetSemester: _selectedSemester,
          preferredRole: _roleController.text.trim(),
          targetCompanies: _targetCompanies,
          cgpa: double.tryParse(_cgpaController.text.trim()),
          createdAt: DateTime.now(),
        );

        await ref.read(userRepositoryProvider).createProfile(profile);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Onboarding'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardWidthSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Bar
                LinearProgressIndicator(
                  value: 0.8,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step 1 of 1',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '80% Completed',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header + Avatar
                          Center(
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 44,
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Icon(
                                        Icons.person_outline,
                                        size: 48,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: theme.colorScheme.primary,
                                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Let's set up your profile",
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Personalize your AI placement recommendations',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Full Name
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                          ),
                          const SizedBox(height: 16),

                          // Row: Branch & Target Semester Dropdowns
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedBranch,
                                  decoration: const InputDecoration(
                                    labelText: 'Branch',
                                    prefixIcon: Icon(Icons.school),
                                  ),
                                  items: _branches
                                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedBranch = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedSemester,
                                  decoration: const InputDecoration(
                                    labelText: 'Semester',
                                    prefixIcon: Icon(Icons.timeline),
                                  ),
                                  items: _semesters
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedSemester = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Preferred Role with suggestion chips
                          TextFormField(
                            controller: _roleController,
                            decoration: const InputDecoration(
                              labelText: 'Preferred Role',
                              prefixIcon: Icon(Icons.work_outline),
                              hintText: 'e.g. Software Engineer',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter preferred role' : null,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _suggestedRoles.map((role) {
                              return ChoiceChip(
                                label: Text(role, style: const TextStyle(fontSize: 11)),
                                selected: _roleController.text == role,
                                onSelected: (sel) {
                                  if (sel) setState(() => _roleController.text = role);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Target Companies Chip Input
                          Text(
                            'Target Companies',
                            style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _companyInputController,
                                  decoration: const InputDecoration(
                                    hintText: 'Add company (e.g. Google)',
                                    prefixIcon: Icon(Icons.business),
                                  ),
                                  onSubmitted: _addCompany,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _addCompany(_companyInputController.text),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Added company pills
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _targetCompanies.map((c) {
                              return Chip(
                                label: Text(c),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => _removeCompany(c),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          // Suggestions
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _suggestedCompanies.map((c) {
                              return ActionChip(
                                label: Text('+ $c', style: const TextStyle(fontSize: 11)),
                                onPressed: () => _addCompany(c),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // CGPA Input
                          TextFormField(
                            controller: _cgpaController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'CGPA (Optional)',
                              prefixIcon: Icon(Icons.grade),
                              hintText: 'e.g. 8.5',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Resume Upload Dropzone Placeholder
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.5),
                                style: BorderStyle.solid,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 40,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload Resume PDF',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Drag and drop PDF or click to browse (PDF up to 5MB)',
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'Complete Setup',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
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
