import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/profile_model.dart';
import '../repositories/user_repository.dart';
import 'auth_provider.dart';

final profileProvider = StreamProvider<ProfileModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.profileStream(user.uid).map((profile) {
    if (profile == null && AppConstants.USE_MOCK_DATA) {
      return ProfileModel(
        uid: user.uid,
        fullName: user.displayName ?? (user.email?.split('@').first ?? 'Student'),
        branch: 'CSE',
        targetSemester: 'Semester 7',
        preferredRole: 'Software Engineer',
        targetCompanies: ['Google', 'Microsoft', 'Amazon'],
        createdAt: DateTime.now(),
      );
    }
    return profile;
  });
});
