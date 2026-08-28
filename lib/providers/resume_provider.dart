import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/cloudinary_service.dart';
import '../core/services/gemini_service.dart';
import '../core/services/pdf_service.dart';
import '../models/resume_report_model.dart';
import '../repositories/resume_repository.dart';
import 'auth_provider.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

final resumeRepositoryProvider = Provider<ResumeRepository>((ref) {
  return ResumeRepository();
});

final latestResumeReportProvider = StreamProvider<ResumeReportModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(resumeRepositoryProvider).latestReportStream(user.uid);
});
