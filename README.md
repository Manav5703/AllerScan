# AllerScan – Food Label Allergen Scanner (Android)

[![GitHub last commit](https://img.shields.io/github/last-commit/Manav5703/AllerScan)](https://github.com/Manav5703/AllerScan/commits/main)
[![Flutter](https://img.shields.io/badge/Flutter-3.22+-blue?logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Platform-Android-green?logo=android)](https://developer.android.com)

**AllerScan** is a lightweight, offline Android app that lets users scan packaged-food labels, extracts the ingredient list with **Tesseract OCR**, and instantly flags allergens using a **Canadian bilingual (EN/FR) lexicon**.  
The app is built for the **COMP 4983 Capstone** under supervision of **Dr. Lydia Bouzar-Benlabiod**.

---

## Table of Contents
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Installation (Developer)](#installation-developer)
- [Running the App](#running-the-app)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [License](#license)

---

## Features
| Status | Feature |
|--------|---------|
| Done | **Camera / Gallery image capture** (`image_picker`) |
| Done | **Tesseract OCR** with English + French trained data (`flutter_tesseract_ocr`) |
| Done | **Bilingual allergen lexicon** (JSON) – 14 priority allergens per Health Canada |
| Done | **Rule-based detection** (lexicon lookup) |
| Done | **Enhanced OCR** – image cropping, contrast, PSM tuning for soft-allergen detection |
| Done | **Allergen alerts** – red chips, haptic feedback (`vibration`) |
| Done | **User profile & onboarding** – avatar (emoji only), personal allergen list |
| Done | **Full-app localisation** (`LanguageProvider`) – EN / FR switch |
| Done | **Android-only** (iOS scope removed) |

---

## Tech Stack
| Layer | Technology |
|-------|------------|
| **Framework** | Flutter 3.22+ (Dart 3) |
| **OCR** | `flutter_tesseract_ocr` with on-device English/French configs |
| **Image handling** | `image_picker`, `image_cropper` |
| **State / Localisation** | `provider` (`LanguageProvider`) |
| **Persistence** | `shared_preferences` (profile data) |
| **Allergen data** | JSON dictionaries (`assets/allergens_en.json`, `assets/allergens_fr.json`) |
| **IDE** | VS Code / Android Studio |

---

## Installation (Developer)
```bash
# 1. Clone the repo
git clone https://github.com/Manav5703/AllerScan.git
cd AllerScan

# 2. Get dependencies
flutter pub get

# 3. Verify assets are in place
#    - assets/allergens_en.json
#    - assets/allergens_fr.json
#    - assets/tessdata/eng.traineddata (if using English OCR configs)
#    - assets/tessdata/fra.traineddata (if using French OCR configs)
```

---

## Running the App
```bash
# Connect an Android device (USB debugging ON) or start an emulator
flutter run
```

The app launches on **Android 5.0+**.  
All processing is **offline** – no network permission required.

---

## Testing
```bash
# Unit tests
flutter test

# Widget tests (example)
flutter test test/widget_test.dart
```

---

## Troubleshooting
| Issue | Suggested Fix |
|-------|----------------|
| Missing allergen strings | Ensure `assets/allergens_en.json` and `assets/allergens_fr.json` exist and are listed in `pubspec.yaml`. Run `flutter pub get`. |
| OCR returns empty text | Check lighting, crop tighter, and confirm the selected language matches the package language so the right configs load. |
| Language doesn’t switch | Confirm `LanguageProvider.changeLanguage` is called and `SharedPreferences` isn’t blocked by OS permissions. Delete the profile to reset if needed. |
| Build errors on Windows/OneDrive | Remove restrictive ACLs, then rerun `flutter clean` followed by `flutter pub get`. |

---

## Roadmap
- Reinstate iOS/web/desktop scaffolds once Android feature set stabilizes.
- Expand allergen dictionaries to cover additional locales.
- Add widget/unit tests for language switching, profile persistence, and allergen detection.
- Explore optional encrypted cloud backup for profiles.

## License
```
MIT License – see LICENSE file
```

---

**Author** – Manav Patel   
**Supervisor** – Dr. Lydia Bouzar-Benlabiod  
**Date** – November 11, 2025

---

*Happy scanning – stay safe from allergens!*
