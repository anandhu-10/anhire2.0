import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/constants/app_colors.dart';

class ResumeAnalyzerScreen extends StatelessWidget {
  const ResumeAnalyzerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compactBreakpoint;
    const int overallScore = 82;

    Color scoreColor = Colors.red;
    if (overallScore >= 50 && overallScore <= 75) scoreColor = Colors.orange;
    if (overallScore > 75) scoreColor = Colors.green;

    final sections = [
      {'name': 'Summary & Objective', 'score': 90, 'feedback': 'Strong opening statement with relevant metrics.'},
      {'name': 'Work Experience', 'score': 85, 'feedback': 'Action verbs used effectively. Quantify achievements further.'},
      {'name': 'Technical Skills', 'score': 75, 'feedback': 'Good core technologies listed. Add cloud infrastructure tools.'},
      {'name': 'Education & Certifications', 'score': 95, 'feedback': 'Degree, branch, CGPA, and university formatted cleanly.'},
      {'name': 'Projects', 'score': 80, 'feedback': 'Links and live demos included. Highlight technologies in titles.'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume ATS Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxCardWidthMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Score Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: CircularProgressIndicator(
                                  value: overallScore / 100,
                                  strokeWidth: 12,
                                  color: scoreColor,
                                  backgroundColor: scoreColor.withOpacity(0.15),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$overallScore',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: scoreColor,
                                    ),
                                  ),
                                  const Text(
                                    '/ 100',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('ATS Compatibility Score', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Your resume ranks in the top 15% of candidates for Software Engineer roles.',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Section Breakdown Cards (1 Column on Compact, 2 Columns on Medium/Expanded)
                Text('Section Breakdown', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                if (isCompact) ...[
                  ...sections.map((sec) => _buildSectionCard(
                        context,
                        sec['name'] as String,
                        sec['score'] as int,
                        sec['feedback'] as String,
                      )),
                ] else ...[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 90,
                    ),
                    itemCount: sections.length,
                    itemBuilder: (context, idx) {
                      final sec = sections[idx];
                      return _buildSectionCard(
                        context,
                        sec['name'] as String,
                        sec['score'] as int,
                        sec['feedback'] as String,
                      );
                    },
                  ),
                ],
                const SizedBox(height: 20),

                // Missing Keywords Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Missing High-Impact Keywords', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['System Design', 'Kubernetes', 'CI/CD Pipelines', 'Microservices', 'GraphQL'].map((kw) {
                            return Chip(
                              label: Text(kw),
                              backgroundColor: Colors.red.withOpacity(0.1),
                              labelStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Suggestions List
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Actionable Optimization Tips', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _buildTipRow('1', 'Incorporate missing keywords (e.g. Microservices, CI/CD) into project bullet points.'),
                        _buildTipRow('2', 'Use standard font headings so ATS parsers do not miscategorize sections.'),
                        _buildTipRow('3', 'Quantify project results (e.g., "Reduced API latency by 35%").'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Re-upload Button
                SizedBox(
                  width: double.infinity,
                  height: AppBreakpoints.minTouchTarget,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/profile-setup'),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Re-upload Resume PDF'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String name, int score, String feedback) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '$score',
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(feedback, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(String numStr, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: const Color(0xFF6750A4),
            child: Text(numStr, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
