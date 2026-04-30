import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shiftipoz/models/user_model.dart';
import 'package:shiftipoz/services/user_service.dart';
import 'dart:developer' as dev;

// This line is CRITICAL for the code generator to work
part 'user_provider.g.dart';

@riverpod
Future<UserModel?> userProfile(Ref ref, String uid) async {
  // It's better to use a provider for the service,
  // but creating it directly works if UserService has a default constructor.
  final userService = UserService();

  dev.log("Fetching profile for user: $uid", name: "UserProfileProvider");

  // Assuming getUserData(uid) is the method in your UserService
  return await userService.getUserData(uid);
}
