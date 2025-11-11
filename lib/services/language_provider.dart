import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const _prefsKey = 'app_language_code';

  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;
  bool get isFrench => _currentLanguage == 'fr';

  static const Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'appTitle': 'AllerScan',
      'welcomeTitle': 'Welcome to AllerScan',
      'welcomeSubtitle': 'Your personal allergy detection assistant',
      'chooseAvatar': 'Choose your avatar',
      'uploadCustomPhoto': 'Upload Custom Photo',
      'customPhotoSelected': 'Custom Photo Selected',
      'tapToChange': 'Tap to change',
      'chooseFromGallery': 'Choose from gallery',
      'orLabel': 'OR',
      'chooseEmojiAvatar': 'Choose an emoji avatar',
      'whatsYourName': "What's your name?",
      'enterYourName': 'Enter your name',
      'pleaseEnterYourName': 'Please enter your name',
      'selectYourAllergens': 'Select Your Allergens',
      'chooseAllAllergens': 'Choose all allergens you need to avoid',
      'addCustomAllergens': 'Add Custom Allergens',
      'hintCustomAllergens': 'e.g., Corn, Celery',
      'almostDone': 'Almost Done!',
      'reviewYourProfile': 'Review your profile',
      'summary': 'Summary',
      'allergensToAvoid': 'Allergens to avoid:',
      'noneSelected': 'None selected',
      'backCta': 'Back',
      'nextCta': 'Next',
      'startCta': 'Get Started',
      'chooseLanguage': 'Choose Your Language',
      'languageHelp': 'Select your preferred language for allergen detection',
      'languageInfo': 'Allergens will be displayed in English and detection will work best with English labels.',
      'languageInfoFr': 'Les allergènes seront affichés en français et la détection fonctionnera mieux avec les étiquettes en français.',
      'avatarLabel': 'Avatar',
      'nameLabel': 'Name',
      'languageLabel': 'Language',
      'allergensLabel': 'Allergens',
      'customAllergensLabel': 'Custom Allergens',
      'saveChanges': 'Save Changes',
      'profileTitle': 'Profile',
      'editProfile': 'Edit Profile',
      'myAllergens': 'My Allergens',
      'standardAllergens': 'Standard Allergens',
      'customAllergensTitle': 'Custom Allergens',
      'noAllergensSelected': 'No allergens selected',
      'deleteProfile': 'Delete Profile',
      'deleteProfileQuestion': 'Are you sure you want to delete your profile? This action cannot be undone.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'profileNotFound': 'No profile found. Please complete onboarding.',
      'profileUpdated': 'Profile updated successfully!',
      'profileUpdateFailed': 'Failed to update profile. Please try again.',
      'profileSaved': 'Profile saved successfully',
      'profileSaveFailed': 'Failed to save profile. Please try again.',
      'failedDelete': 'Failed to delete profile. Please try again.',
      'languageEnglish': 'English',
      'languageFrench': 'Français',
      'languageBadgeEnglish': '🇬🇧 English',
      'languageBadgeFrench': '🇫🇷 Français',
      'customPhoto': 'Custom Photo Selected',
      'customPhotoPrompt': 'Choose from gallery',
      'customPhotoTap': 'Tap to change',
      'chooseAllergensPrompt': 'Choose all allergens you need to avoid',
      'addCustomAllergensHint': 'e.g., Corn, Celery',
      'customAllergensPrompt': 'Add Custom Allergens',
      'languageSummaryLabel': 'Language',
      'deleteProfileSuccess': 'Profile deleted successfully',
      'initialLoadingText': 'AllerScan',
      'initialLoadingSubtitle': 'Preparing your experience...',
      'homeWelcomeBack': 'Welcome back,',
      'homeDefaultUser': 'User',
      'homeYourAllergens': 'Your Allergens',
      'homeScanTitle': 'Scan Product Label',
      'homeScanSubtitle': 'Take a photo or upload an image',
      'homeHowItWorks': 'How it works',
      'homeStep1Title': '1. Capture',
      'homeStep1Description': 'Take a photo of the ingredient label',
      'homeStep2Title': '2. Analyze',
      'homeStep2Description': 'We scan for allergens in the ingredients',
      'homeStep3Title': '3. Results',
      'homeStep3Description': 'Get instant alerts about your allergens',
      'uploadAppBarTitle': 'Scan Label',
      'uploadSheetTitle': 'Select Image Source',
      'uploadCameraTitle': 'Camera',
      'uploadCameraSubtitle': 'Take a new photo',
      'uploadGalleryTitle': 'Gallery',
      'uploadGallerySubtitle': 'Choose from gallery',
      'uploadInstructions': 'Position the ingredient label clearly in the frame for best results',
      'uploadNoImageTitle': 'No image selected',
      'uploadNoImageSubtitle': 'Tap the button below to get started',
      'uploadPrimaryButton': 'Capture or Select Image',
      'uploadPrimaryButtonChange': 'Change Image',
      'uploadTipsTitle': 'Tips for best results',
      'uploadTipLighting': 'Ensure good lighting',
      'uploadTipFocus': 'Keep the label flat and in focus',
      'uploadTipShadows': 'Avoid shadows and glare',
      'uploadTipFullLabel': 'Capture the entire ingredients section',
      'uploadProcessingTitle': 'Analyzing with enhanced OCR...',
      'uploadProcessingSubtitle': 'Testing multiple recognition modes for best accuracy',
      'cropAppBarTitle': 'Crop Image',
      'cropInstructionTitle': 'Drag the corners to crop the image',
      'cropInstructionSubtitle': 'Focus on the ingredients label for best results',
      'done': 'Done',
      'resultsAppBarTitle': 'Scan Results',
      'resultsDangerTitle': 'DANGER! Your Allergens Found!',
      'resultsWarningTitle': 'WARNING: Your Allergens Detected!',
      'resultsSafeTitle': 'Safe for You',
      'resultsDangerSubtitle': "This product contains allergens you're allergic to",
      'resultsWarningSubtitle': 'This product contains some of your allergens',
      'resultsSafeSubtitle': "This product doesn't contain your allergens",
      'resultsDetectedListPrefix': 'Detected:',
      'resultsAllDetected': 'All Detected Allergens',
      'resultsContainsTitle': 'Contains',
      'resultsContainsDescription': 'These allergens are confirmed in this product',
      'resultsMayContainTitle': 'May Contain',
      'resultsMayContainDescription': 'These allergens were detected in the ingredients list',
      'resultsIngredientsDetected': 'Ingredients Detected',
      'resultsScanAnother': 'Scan Another',
      'resultsHomeButton': 'Home',
      'resultsPersonalWarningTitle': 'WARNING: Your Allergens Detected!',
      'resultsPersonalSafeTitle': 'Your Safe Allergens',
      'resultsPersonalDetectedDescription': 'These allergens from your profile were detected in this product',
      'resultsPersonalSafeDescription': 'These allergens from your profile were not detected in this product',
    },
    'fr': {
      'appTitle': 'AllerScan',
      'welcomeTitle': 'Bienvenue sur AllerScan',
      'welcomeSubtitle': "Votre assistant personnel de détection des allergies",
      'chooseAvatar': 'Choisissez votre avatar',
      'uploadCustomPhoto': 'Télécharger une photo personnalisée',
      'customPhotoSelected': 'Photo personnalisée sélectionnée',
      'tapToChange': 'Appuyez pour changer',
      'chooseFromGallery': 'Choisir depuis la galerie',
      'orLabel': 'OU',
      'chooseEmojiAvatar': 'Choisissez un avatar emoji',
      'whatsYourName': 'Comment vous appelez-vous ?',
      'enterYourName': 'Entrez votre nom',
      'pleaseEnterYourName': 'Veuillez entrer votre nom',
      'selectYourAllergens': 'Sélectionnez vos allergènes',
      'chooseAllAllergens': 'Choisissez tous les allergènes à éviter',
      'addCustomAllergens': 'Ajouter des allergènes personnalisés',
      'hintCustomAllergens': 'ex. Maïs, Céleri',
      'almostDone': 'Presque terminé !',
      'reviewYourProfile': 'Vérifiez votre profil',
      'summary': 'Résumé',
      'allergensToAvoid': 'Allergènes à éviter :',
      'noneSelected': 'Aucun sélectionné',
      'backCta': 'Retour',
      'nextCta': 'Suivant',
      'startCta': 'Commencer',
      'chooseLanguage': 'Choisissez Votre Langue',
      'languageHelp': 'Sélectionnez votre langue préférée pour la détection des allergènes',
      'languageInfo': 'Allergens will be displayed in English and detection will work best with English labels.',
      'languageInfoFr': 'Les allergènes seront affichés en français et la détection fonctionnera mieux avec les étiquettes en français.',
      'avatarLabel': 'Avatar',
      'nameLabel': 'Nom',
      'languageLabel': 'Langue',
      'allergensLabel': 'Allergènes',
      'customAllergensLabel': 'Allergènes personnalisés',
      'saveChanges': 'Enregistrer les modifications',
      'profileTitle': 'Profil',
      'editProfile': 'Modifier le profil',
      'myAllergens': 'Mes allergènes',
      'standardAllergens': 'Allergènes standard',
      'customAllergensTitle': 'Allergènes personnalisés',
      'noAllergensSelected': 'Aucun allergène sélectionné',
      'deleteProfile': 'Supprimer le profil',
      'deleteProfileQuestion': 'Êtes-vous sûr de vouloir supprimer votre profil ? Cette action est irréversible.',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'profileNotFound': 'Aucun profil trouvé. Veuillez terminer l\'intégration.',
      'profileUpdated': 'Profil mis à jour avec succès !',
      'profileUpdateFailed': 'Échec de la mise à jour du profil. Veuillez réessayer.',
      'profileSaved': 'Profil enregistré avec succès',
      'profileSaveFailed': "Échec de l'enregistrement du profil. Veuillez réessayer.",
      'failedDelete': 'Échec de la suppression du profil. Veuillez réessayer.',
      'languageEnglish': 'English',
      'languageFrench': 'Français',
      'languageBadgeEnglish': '🇬🇧 English',
      'languageBadgeFrench': '🇫🇷 Français',
      'customPhoto': 'Photo personnalisée sélectionnée',
      'customPhotoPrompt': 'Choisir depuis la galerie',
      'customPhotoTap': 'Appuyez pour changer',
      'chooseAllergensPrompt': 'Choisissez tous les allergènes à éviter',
      'addCustomAllergensHint': 'ex. Maïs, Céleri',
      'customAllergensPrompt': 'Ajouter des allergènes personnalisés',
      'languageSummaryLabel': 'Langue',
      'deleteProfileSuccess': 'Profil supprimé avec succès',
      'initialLoadingText': 'AllerScan',
      'initialLoadingSubtitle': 'Préparation de votre expérience...',
      'homeWelcomeBack': 'Bon retour,',
      'homeDefaultUser': 'Utilisateur',
      'homeYourAllergens': 'Vos allergènes',
      'homeScanTitle': 'Scanner une étiquette',
      'homeScanSubtitle': 'Prenez une photo ou téléchargez une image',
      'homeHowItWorks': 'Comment ça marche',
      'homeStep1Title': '1. Capturer',
      'homeStep1Description': "Prenez une photo de l'étiquette des ingrédients",
      'homeStep2Title': '2. Analyser',
      'homeStep2Description': "Nous analysons les ingrédients pour trouver des allergènes",
      'homeStep3Title': '3. Résultats',
      'homeStep3Description': 'Recevez des alertes instantanées sur vos allergènes',
      'uploadAppBarTitle': 'Scanner une étiquette',
      'uploadSheetTitle': "Sélectionner la source d'image",
      'uploadCameraTitle': 'Appareil photo',
      'uploadCameraSubtitle': 'Prendre une nouvelle photo',
      'uploadGalleryTitle': 'Galerie',
      'uploadGallerySubtitle': 'Choisir depuis la galerie',
      'uploadInstructions': "Positionnez clairement l'étiquette des ingrédients dans le cadre pour de meilleurs résultats",
      'uploadNoImageTitle': 'Aucune image sélectionnée',
      'uploadNoImageSubtitle': 'Appuyez sur le bouton ci-dessous pour commencer',
      'uploadPrimaryButton': 'Capturer ou sélectionner une image',
      'uploadPrimaryButtonChange': "Changer d'image",
      'uploadTipsTitle': 'Conseils pour de meilleurs résultats',
      'uploadTipLighting': 'Assurez une bonne luminosité',
      'uploadTipFocus': "Gardez l'étiquette plate et nette",
      'uploadTipShadows': 'Évitez les ombres et les reflets',
      'uploadTipFullLabel': "Capturez toute la section des ingrédients",
      'uploadProcessingTitle': "Analyse avec OCR amélioré...",
      'uploadProcessingSubtitle': 'Test de plusieurs modes de reconnaissance pour une meilleure précision',
      'cropAppBarTitle': "Recadrer l'image",
      'cropInstructionTitle': "Faites glisser les coins pour recadrer l'image",
      'cropInstructionSubtitle': "Concentrez-vous sur l'étiquette des ingrédients pour de meilleurs résultats",
      'done': 'Terminer',
      'resultsAppBarTitle': 'Résultats du scan',
      'resultsDangerTitle': 'DANGER! Vos allergènes trouvés !',
      'resultsWarningTitle': 'ATTENTION: Vos allergènes détectés !',
      'resultsSafeTitle': 'Sûr pour vous',
      'resultsDangerSubtitle': 'Ce produit contient des allergènes auxquels vous êtes allergique',
      'resultsWarningSubtitle': 'Ce produit contient certains de vos allergènes',
      'resultsSafeSubtitle': 'Ce produit ne contient pas vos allergènes',
      'resultsDetectedListPrefix': 'Détecté :',
      'resultsAllDetected': 'Tous les allergènes détectés',
      'resultsContainsTitle': 'Contient',
      'resultsContainsDescription': 'Ces allergènes sont confirmés dans ce produit',
      'resultsMayContainTitle': 'Peut contenir',
      'resultsMayContainDescription': "Ces allergènes ont été détectés dans la liste des ingrédients",
      'resultsIngredientsDetected': 'Ingrédients détectés',
      'resultsScanAnother': 'Scanner un autre',
      'resultsHomeButton': 'Accueil',
      'resultsPersonalWarningTitle': 'ATTENTION: Vos allergènes détectés !',
      'resultsPersonalSafeTitle': 'Allergènes non détectés',
      'resultsPersonalDetectedDescription': 'Ces allergènes de votre profil ont été détectés dans ce produit',
      'resultsPersonalSafeDescription': "Ces allergènes de votre profil n'ont pas été détectés dans ce produit",
    },
  };

  static const Map<String, Map<String, String>> _allergenLabels = {
    'en': {
      'milk': '🥛 Milk & Dairy',
      'eggs': '🥚 Eggs',
      'peanuts': '🥜 Peanuts',
      'tree_nuts': '🌰 Tree Nuts',
      'soy': '🫘 Soy',
      'wheat': '🌾 Wheat/Gluten',
      'fish': '🐟 Fish',
      'shellfish': '🦐 Shellfish',
      'sesame': '🫘 Sesame',
      'mustard': '🌭 Mustard',
      'sulphites': '🧪 Sulphites',
    },
    'fr': {
      'milk': '🥛 Lait & Produits laitiers',
      'eggs': '🥚 Œufs',
      'peanuts': '🥜 Arachides',
      'tree_nuts': '🌰 Noix',
      'soy': '🫘 Soja',
      'wheat': '🌾 Blé/Gluten',
      'fish': '🐟 Poisson',
      'shellfish': '🦐 Crustacés',
      'sesame': '🫘 Sésame',
      'mustard': '🌭 Moutarde',
      'sulphites': '🧪 Sulfites',
    },
  };

  Map<String, String> get strings => _localizedStrings[_currentLanguage] ?? _localizedStrings['en']!;

  Map<String, String> get allergenLabels =>
      Map<String, String>.from(_allergenLabels[_currentLanguage] ?? _allergenLabels['en']!);

  String text(String key) => strings[key] ?? key;

  Map<String, String> stringsFor(String languageCode) {
    return Map<String, String>.from(_localizedStrings[languageCode] ?? _localizedStrings['en']!);
  }

  Map<String, String> allergenLabelsFor(String languageCode) {
    return Map<String, String>.from(_allergenLabels[languageCode] ?? _allergenLabels['en']!);
  }

  String languageName(String code) {
    switch (code) {
      case 'fr':
        return _localizedStrings[_currentLanguage]?['languageFrench'] ?? 'Français';
      case 'en':
      default:
        return _localizedStrings[_currentLanguage]?['languageEnglish'] ?? 'English';
    }
  }

  String languageBadge(String code) {
    switch (code) {
      case 'fr':
        return strings['languageBadgeFrench'] ?? '🇫🇷 Français';
      case 'en':
      default:
        return strings['languageBadgeEnglish'] ?? '🇬🇧 English';
    }
  }

  Future<void> loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && _localizedStrings.containsKey(saved)) {
        _currentLanguage = saved;
        notifyListeners();
      }
    } catch (_) {
      // Ignore errors; default language will be used.
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (!_localizedStrings.containsKey(languageCode)) return;
    if (_currentLanguage == languageCode) return;

    _currentLanguage = languageCode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, languageCode);
    } catch (_) {
      // Ignore persistence errors.
    }
  }
}
