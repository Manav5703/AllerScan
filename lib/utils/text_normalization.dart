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
    final replacements = <String, String>{
      'peamut': 'peanut',
      'arachide': 'peanut',
      'oeuf': 'egg',
      'soyabean': 'soybean',
      'vheat': 'wheat',
      'gluen': 'gluten'
    };
    String s = normalizeBasic(input);
    replacements.forEach((k, v) {
      s = s.replaceAll(k, v);
    });
    return s;
  }

  static List<String> splitLines(String text) {
    return text.split('\n').map((l) => l.trim()).toList();
  }
}