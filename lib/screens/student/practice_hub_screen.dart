import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';

class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compactBreakpoint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Hub'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice & Master',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a module to sharpen your technical and analytical skills',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Responsive Cards Layout (Stacked on Mobile, Row on Medium/Expanded)
                if (isCompact) ...[
                  Column(
                    children: [
                      _buildPracticeCard(
                        context,
                        title: 'CODING PRACTICE',
                        description: '30 Problems available',
                        tags: ['Easy: 10', 'Medium: 15', 'Hard: 5'],
                        icon: Icons.code,
                        iconBgColor: const Color(0xFF6750A4),
                        onTap: () => context.go('/coding-problems'),
                      ),
                      const SizedBox(height: 16),
                      _buildPracticeCard(
                        context,
                        title: 'APTITUDE TEST',
                        description: '30 Questions available',
                        tags: ['Quantitative', 'Logical', 'Verbal'],
                        icon: Icons.psychology,
                        iconBgColor: const Color(0xFFED6C02),
                        onTap: () => context.go('/aptitude'),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildPracticeCard(
                          context,
                          title: 'CODING PRACTICE',
                          description: '30 Problems available',
                          tags: ['Easy: 10', 'Medium: 15', 'Hard: 5'],
                          icon: Icons.code,
                          iconBgColor: const Color(0xFF6750A4),
                          onTap: () => context.go('/coding-problems'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPracticeCard(
                          context,
                          title: 'APTITUDE TEST',
                          description: '30 Questions available',
                          tags: ['Quantitative', 'Logical', 'Verbal'],
                          icon: Icons.psychology,
                          iconBgColor: const Color(0xFFED6C02),
                          onTap: () => context.go('/aptitude'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),

                // Roadmap Banner Card
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.alt_route, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personalized Learning Roadmap',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Follow a structured week-by-week timeline tailored for your target roles',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/roadmap'),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('View Roadmap'),
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

  Widget _buildPracticeCard(
    BuildContext context, {
    required String title,
    required String description,
    required List<String> tags,
    required IconData icon,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFEADDFF),
                    child: Icon(Icons.arrow_forward, color: Color(0xFF6750A4), size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
