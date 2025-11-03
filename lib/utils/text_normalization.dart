import 'package:characters/characters.dart';

class TextNormalization {
  static String normalizeBasic(String input) {
    String s = input.toLowerCase();
    s = _stripDiacritics(s);
    s = s.replaceAll(RegExp(r'[_•·\t]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static String _stripDiacritics(String input) {
    const Map<String, String> map = {
      'á':'a','à':'a','ä':'a','â':'a','ã':'a','å':'a','ā':'a',
      'é':'e','è':'e','ë':'e','ê':'e','ē':'e',
      'í':'i','ì':'i','ï':'i','î':'i','ī':'i',
      'ó':'o','ò':'o','ö':'o','ô':'o','õ':'o','ō':'o',
      'ú':'u','ù':'u','ü':'u','û':'u','ū':'u',
      'ç':'c','ñ':'n','ß':'ss'
    };
    final buffer = StringBuffer();
    for (final ch in input.characters) {
      buffer.write(map[ch] ?? ch);
    }
    return buffer.toString();
  }

  static String normalizeForMatching(String input) {
    // More comprehensive replacements, especially for French terms
    final replacements = <String, String>{
      // Common OCR errors
      'peamut': 'peanut',
      'vheat': 'wheat',
      'gluen': 'gluten',
      'soyabean': 'soybean',
      
      // French to English mappings for better matching
      'arachide': 'peanut',
      'arachides': 'peanut',
      'cacahuete': 'peanut',
      'cacahuetes': 'peanut',
      'oeuf': 'egg',
      'oeufs': 'egg',
      'lait': 'milk',
      'soja': 'soy',
      'ble': 'wheat',
      'farine': 'flour',
      'poisson': 'fish',
      'crustace': 'shellfish',
      'crustaces': 'shellfish',
      'sesame': 'sesame',
      'moutarde': 'mustard',
      'sulfite': 'sulphite',
      'sulfites': 'sulphites',
      'noix': 'nut'
    };
    
    String s = normalizeBasic(input);
    String original = s;
    
    replacements.forEach((k, v) {
      if (s.contains(k)) {
        s = s.replaceAll(k, v);
      }
    });
    
    if (original != s) {
      print('TEXT NORMALIZED: "$original" -> "$s"');
    }
    
    return s;
  }

  static List<String> splitLines(String text) {
    return text.split('\n').map((l) => l.trim()).toList();
  }
}