 <div align="center">

# AllerScan

An offline-first Flutter application that scans food labels, extracts ingredients with on-device OCR, and highlights allergens using a personalized profile. Built as the COMP‑4983 Capstone project (Fall 2025).

</div>

---

## Table of Contents

1. [Features](#features)
2. [Project Structure](#project-structure)
3. [Localization & Language Switching](#localization--language-switching)
4. [Allergen Detection Pipeline](#allergen-detection-pipeline)
5. [Getting Started](#getting-started)
6. [Running the App](#running-the-app)
7. [Troubleshooting](#troubleshooting)
8. [Roadmap](#roadmap)

---

## Features

- **Label Scanning** – Capture or upload images of ingredient labels on-device.
- **Enhanced OCR** – Multiple Tesseract configurations (English & French) improve recognition without leaving the device.
- **Personalized Profiles** – Users specify their name, allergen list (standard + custom), avatar, and preferred language.
- **Dynamic Language Switching** – Entire UI instantly reflects the profile language (English ↔ Français) using a lightweight `LanguageProvider`.
- **Allergen Warnings** – Clearly labeled results screen shows confirmed detections and the ingredient list for review.
- **Offline Operation** – No network calls during OCR or allergen detection, preserving privacy.

---

## Project Structure

```
lib/
  main.dart                 # App entry point & global providers
  services/
    language_provider.dart  # UI strings + language persistence
    profile_service.dart    # SharedPreferences persistence
  models/
    user_profile.dart       # Profile data model
  screens/
    onboarding_screen.dart  # Profile creation wizard
    home_screen.dart        # Dashboard & navigation hub
    upload_screen.dart      # Image capture / OCR trigger
    results_screen.dart     # Allergen detection results
    profile_screen.dart     # Profile view/edit/delete
  utils/
    allergen_detector.dart  # Dictionary-based matching logic
    text_normalization.dart # Helpers for cleaned OCR text
assets/
  tessdata/                 # Tesseract language data
  allergens_*.json          # Allergen dictionaries (EN/FR)
l10n/                       # Provider-based string maps (EN/FR)
```

---

## Localization & Language Switching

- `LanguageProvider` stores all translated UI strings and allergen labels for English (`en`) and French (`fr`).
- The provider persists the last selected language with `SharedPreferences` so the app re-opens in the expected locale.
- Onboarding and Profile screens update the provider whenever the user toggles languages, refreshing the entire UI instantly.
- After profile deletion the language resets to English, ensuring new users start with the default experience.

To add or update strings:
1. Edit `lib/services/language_provider.dart` in the `_localizedStrings` section.
2. Reference strings using `context.watch<LanguageProvider>().text('key')` or `strings['key']` from the provider.

---

## Allergen Detection Pipeline

1. **OCR Stage** – `upload_screen.dart` invokes `flutter_tesseract_ocr` with multiple PSM/OEM configurations and a character whitelist to maximise accuracy.
2. **Text Normalization** – `text_normalization.dart` filters and lowercases OCR output, isolating the ingredient section.
3. **Dictionary Matching** – `allergen_detector.dart` compares normalized text with language-specific dictionaries (`allergens_en.json`, `allergens_fr.json`).
4. **Results Presentation** – `results_screen.dart` highlights confirmed matches ("Contains") and lists the cleaned ingredient text for manual review. The optional "May Contain" warning has been removed per latest UX requirements.

---

## Getting Started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) SDK **3.9.0 or later**
- Android Studio or VS Code with Flutter tooling
- Java 11+ (for Android builds)
- Android device or emulator (iOS not yet configured)

> **Note:** The project uses the Flutter stable channel. Run `flutter upgrade` if you encounter tooling mismatches.

### Initial Setup

```bash
git clone https://github.com/Manav5703/AllerScan.git
cd AllerScan
flutter pub get
```

If you clean the project (`flutter clean`), ensure the `.dart_tool` directory can be recreated (particularly on OneDrive—remove restrictive permissions if needed).

---

## Running the App

```bash
# Connect a device or start an emulator
flutter devices

# Run the app in debug mode
flutter run

# Build a release APK (optional)
flutter build apk --release
```

During the first launch:
1. Step through the onboarding wizard.
2. Select allergens (standard + custom) and a display language.
3. Use the Home screen to scan a product label and review results.

---

## Troubleshooting

| Issue | Fix |
| ----- | --- |
| **`package:provider/provider.dart` not found** | Run `flutter pub get` to ensure dependencies are installed. |
| **Permission errors under `l10n/` or `.dart_tool/`** | Remove Deny ACLs (common with OneDrive). Recreate folders with `mkdir -Force` and retry. |
| **`May Contain` section still visible** | Ensure you pulled the latest changes; only "Contains" is rendered now. |
| **OCR inaccurate on French labels** | Confirm onboarding/profile language is set to French so the French dictionary loads. |
| **Slow build / verbose logs** | Clean the build cache with `flutter clean` and rerun `flutter pub get`. |

---

## Roadmap

- iOS build support and platform testing
- Expand allergen dictionaries for additional locales
- Unit tests for profile persistence and language switching
- Optional cloud sync for profiles (while preserving privacy controls)

---

## License

This project is currently under academic development. Licensing will be determined prior to public release.