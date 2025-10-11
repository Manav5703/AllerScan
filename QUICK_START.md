# AllerScan - Quick Start Guide

## 🚀 Getting Started

### Install Dependencies
```bash
cd allerscan
flutter pub get
```

### Run the App
```bash
flutter run
```

## 📱 App Flow

### First Launch
```
Splash Screen (0.5s)
    ↓
Onboarding Screen
    ↓
Step 1: Choose Avatar + Enter Name
    ↓
Step 2: Select Allergens
    ↓
Step 3: Set Language + Review
    ↓
Home Screen (Personalized)
```

### Subsequent Launches
```
Splash Screen (0.5s)
    ↓
Home Screen (Personalized)
```

## 🎯 Key Features

### ✅ Onboarding (First-Time Users)
- **Step 1:** Profile Setup
  - Choose avatar emoji
  - Enter name
  
- **Step 2:** Allergen Selection
  - Select from 11 standard allergens
  - Add custom allergens
  
- **Step 3:** Preferences
  - Choose language (EN/FR)
  - Review profile summary

### 🏠 Home Screen
- Personalized greeting with avatar
- Allergen summary card
- Large "Scan Product Label" button
- "How it works" guide

### 👤 Profile Screen
- **View Mode:**
  - Display profile info
  - Show all allergens
  - Delete profile option
  
- **Edit Mode:**
  - Update name, avatar, language
  - Modify allergen list
  - Save changes

### 📸 Scan Screen (Existing)
- Take photo or upload image
- Crop ingredient label
- OCR text extraction
- Allergen detection

## 🎨 UI Components

### Standard Allergens (11 Total)
1. 🥛 Milk & Dairy
2. 🥚 Eggs
3. 🥜 Peanuts
4. 🌰 Tree Nuts
5. 🫘 Soy
6. 🌾 Wheat/Gluten
7. 🐟 Fish
8. 🦐 Shellfish
9. 🫘 Sesame
10. 🌭 Mustard
11. 🧪 Sulphites

### Avatar Options
👤 😊 🙂 😎 🤓 👨 👩 🧑

### Color Scheme
- **Primary:** Teal (#00897B)
- **Allergen Alert:** Red
- **Custom Allergen:** Orange
- **Background:** White
- **Text:** Black87

## 📂 New Files Created

```
lib/
├── models/
│   └── user_profile.dart
├── services/
│   └── profile_service.dart
└── screens/
    ├── onboarding_screen.dart
    └── profile_screen.dart
```

## 🔧 Modified Files

```
lib/
├── main.dart              # Added routing & initial screen
└── screens/
    └── home_screen.dart   # Added profile display
```

## 📦 Dependencies Added

```yaml
shared_preferences: ^2.2.2
```

## 🧪 Testing the Profile System

### Test Onboarding:
1. Launch app (first time)
2. Complete all 3 onboarding steps
3. Verify profile saved
4. Check home screen shows profile

### Test Profile Edit:
1. Tap profile icon in app bar
2. Tap edit icon
3. Modify profile fields
4. Save changes
5. Verify updates on home screen

### Test Profile Delete:
1. Go to profile screen
2. Tap "Delete Profile"
3. Confirm deletion
4. App should return to onboarding

### Test Persistence:
1. Create profile
2. Close app completely
3. Relaunch app
4. Verify profile loads correctly

## 🐛 Troubleshooting

### Issue: App shows blank screen
**Solution:** Run `flutter clean && flutter pub get`

### Issue: SharedPreferences not working
**Solution:** Check platform-specific setup (should work out of the box)

### Issue: Navigation errors
**Solution:** Ensure all routes are registered in `main.dart`

### Issue: Profile not saving
**Solution:** Check console for errors, verify permissions

## 📝 Usage Examples

### Creating a Profile
```dart
final profile = UserProfile(
  name: 'John',
  allergens: ['milk', 'peanuts'],
  customAllergens: ['corn'],
  language: 'en',
  avatarEmoji: '😊',
);
await ProfileService().saveProfile(profile);
```

### Loading a Profile
```dart
final profile = await ProfileService().loadProfile();
if (profile != null) {
  print('Welcome ${profile.name}!');
}
```

## 🎯 Next Development Steps

1. **Integrate with Scan Results:**
   - Compare detected allergens with user profile
   - Highlight user-specific allergens
   - Show personalized warnings

2. **Add French Translation:**
   - Translate all UI strings
   - Use language preference

3. **Enhance Profile:**
   - Add profile photo option
   - Multiple profiles support
   - Export/import functionality

4. **Improve UX:**
   - Add animations
   - Tutorial tooltips
   - Better error handling

## 💡 Tips

- **Profile data** is stored locally using SharedPreferences
- **No internet required** for profile functionality
- **Allergen list** matches the detection system in `allergens_en.json`
- **UI is responsive** and works on various screen sizes
- **Material Design** principles followed throughout

## 📞 Support

For issues or questions:
1. Check console logs for errors
2. Verify all dependencies installed
3. Ensure Flutter SDK is up to date
4. Review implementation in PROFILE_IMPLEMENTATION.md
