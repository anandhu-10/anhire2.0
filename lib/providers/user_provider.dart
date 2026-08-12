import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import '../repositories/user_repository.dart';
import 'auth_provider.dart';

final profileProvider = StreamProvider<ProfileModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.profileStream(user.uid);
});
