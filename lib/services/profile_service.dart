import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileService {
  static const String _profileKey = 'user_profile';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';

  // Save user profile
  Future<bool> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, profile.toJsonString());
      await prefs.setBool(_hasCompletedOnboardingKey, true);
      return true;
    } catch (e) {
      print('Error saving profile: $e');
      return false;
    }
  }

  // Load user profile
  Future<UserProfile?> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileString = prefs.getString(_profileKey);
      if (profileString == null) return null;
      return UserProfile.fromJsonString(profileString);
    } catch (e) {
      print('Error loading profile: $e');
      return null;
    }
  }

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }

  // Delete profile (for logout or reset)
  Future<bool> deleteProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
      await prefs.remove(_hasCompletedOnboardingKey);
      return true;
    } catch (e) {
      print('Error deleting profile: $e');
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile(UserProfile profile) async {
    return await saveProfile(profile);
  }
}
