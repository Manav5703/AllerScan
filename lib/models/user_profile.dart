import 'dart:convert';

class UserProfile {
  final String name;
  final List<String> allergens;
  final List<String> customAllergens;
  final String language; // 'en' or 'fr'
  final String? avatarEmoji;
  final String? avatarPhotoPath; // Path to custom profile photo

  UserProfile({
    required this.name,
    required this.allergens,
    this.customAllergens = const [],
    this.language = 'en',
    this.avatarEmoji,
    this.avatarPhotoPath,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'allergens': allergens,
      'customAllergens': customAllergens,
      'language': language,
      'avatarEmoji': avatarEmoji,
      'avatarPhotoPath': avatarPhotoPath,
    };
  }

  // Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String,
      allergens: List<String>.from(json['allergens'] as List),
      customAllergens: json['customAllergens'] != null
          ? List<String>.from(json['customAllergens'] as List)
          : [],
      language: json['language'] as String? ?? 'en',
      avatarEmoji: json['avatarEmoji'] as String?,
      avatarPhotoPath: json['avatarPhotoPath'] as String?,
    );
  }

  // Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Create from JSON string
  factory UserProfile.fromJsonString(String jsonString) {
    return UserProfile.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  // Get all allergens (standard + custom)
  List<String> getAllAllergens() {
    return [...allergens, ...customAllergens];
  }

  // Copy with method for updates
  UserProfile copyWith({
    String? name,
    List<String>? allergens,
    List<String>? customAllergens,
    String? language,
    String? avatarEmoji,
    String? avatarPhotoPath,
  }) {
    return UserProfile(
      name: name ?? this.name,
      allergens: allergens ?? this.allergens,
      customAllergens: customAllergens ?? this.customAllergens,
      language: language ?? this.language,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarPhotoPath: avatarPhotoPath ?? this.avatarPhotoPath,
    );
  }
  
  // Check if user has a custom photo
  bool hasCustomPhoto() {
    return avatarPhotoPath != null && avatarPhotoPath!.isNotEmpty;
  }
}
