import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'text_normalization.dart';

class AllergenHit {
  final String allergenKey;
  final String matchedTerm;
  final String section;          // "contains" | "may_contain" | "ingredients"
  final int lineIndex;
  final int start;
  final int end;
  final bool hard;
  final double confidence;

  AllergenHit({
    required this.allergenKey,
    required this.matchedTerm,
    required this.section,
    required this.lineIndex,
    required this.start,
    required this.end,
    required this.hard,
    required this.confidence,
  });
}

class AllergenDictionary {
  final Map<String, List<String>> allergenToTerms;
  AllergenDictionary(this.allergenToTerms);

  static Future<AllergenDictionary> loadEnglish() async {
    final data = await rootBundle.loadString('assets/allergens_en.json');
    final map = json.decode(data) as Map<String, dynamic>;
    final dict = <String, List<String>>{};
    map.forEach((k, v) {
      final terms = (v['synonyms'] as List).cast<String>()
          .map((t) => TextNormalization.normalizeForMatching(t))
          .toList();
      // Prefer longer phrases first
      terms.sort((a, b) => b.length.compareTo(a.length));
      dict[k] = terms;
    });
    return AllergenDictionary(dict);
  }
}

class AllergenDetector {
  final AllergenDictionary dict;
  final bool enableFuzzy;

  AllergenDetector(this.dict, {this.enableFuzzy = true});

  List<AllergenHit> detect(String rawText) {
    final lines = TextNormalization.splitLines(rawText);
    final normalizedLines = lines.map(TextNormalization.normalizeForMatching).toList();

    final hits = <AllergenHit>[];
    for (int i = 0; i < normalizedLines.length; i++) {
      final line = normalizedLines[i];
      final label = _classifySection(line);
      if (label.isEmpty && !_isLikelyIngredientsContext(normalizedLines, i)) continue;

      final section = label.isNotEmpty ? label : "ingredients";
      final hard = section == "contains";

      // Enhanced confidence scoring based on section and match quality
      final baseConfidence = _getBaseConfidence(section, line);
      final contextMultiplier = _getContextMultiplier(normalizedLines, i, section);
      final finalConfidence = baseConfidence * contextMultiplier;

      dict.allergenToTerms.forEach((allergen, terms) {
        for (final term in terms) {
          final idx = line.indexOf(term);
          if (idx >= 0) {
            hits.add(AllergenHit(
              allergenKey: allergen,
              matchedTerm: term,
              section: section,
              lineIndex: i,
              start: idx,
              end: idx + term.length,
              hard: hard,
              confidence: finalConfidence,
            ));
          } else if (enableFuzzy) {
            final fuzzyIdx = _fuzzyFind(line, term);
            if (fuzzyIdx != null) {
              hits.add(AllergenHit(
                allergenKey: allergen,
                matchedTerm: term,
                section: section,
                lineIndex: i,
                start: fuzzyIdx.item1,
                end: fuzzyIdx.item2,
                hard: hard,
                confidence: (finalConfidence - 0.15).clamp(0.1, 1.0),
              ));
            }
          }
        }
      });
    }

    // Remove duplicates and low confidence hits
    final uniqueHits = _deduplicateHits(hits);

    // Remove negated lines like "free from", "does not contain"
    return uniqueHits.where((h) => !_negated(lines[h.lineIndex])).toList();
  }

  double _getBaseConfidence(String section, String line) {
    switch (section) {
      case 'contains':
        return 1.0; // Highest confidence for explicit contains
      case 'may_contain':
        // Higher confidence if multiple may_contain patterns are found
        int patternCount = 0;
        final mayContainPatterns = [
          'may contain', 'may also contain', 'may be present', 'traces of',
          'produced in a facility', 'cross-contamination'
        ];
        for (final pattern in mayContainPatterns) {
          if (line.contains(pattern)) patternCount++;
        }
        return 0.6 + (patternCount * 0.05); // 0.6 to 0.85
      case 'ingredients':
        return 0.5; // Medium confidence for ingredients list
      default:
        return 0.3; // Low confidence for unknown sections
    }
  }

  double _getContextMultiplier(List<String> normalizedLines, int currentIndex, String section) {
    double multiplier = 1.0;

    // Check for surrounding context clues
    for (int offset = -2; offset <= 2; offset++) {
      final checkIndex = currentIndex + offset;
      if (checkIndex >= 0 && checkIndex < normalizedLines.length && checkIndex != currentIndex) {
        final contextLine = normalizedLines[checkIndex];

        // Positive context (increases confidence)
        if (contextLine.contains('allergen') || contextLine.contains('warning') ||
            contextLine.contains('caution') || contextLine.contains('note')) {
          multiplier += 0.1;
        }

        // Negative context (decreases confidence)
        if (contextLine.contains('nutrition') || contextLine.contains('calories') ||
            contextLine.contains('serving') || contextLine.contains('net weight')) {
          multiplier -= 0.2;
        }
      }
    }

    return multiplier.clamp(0.3, 1.5);
  }

  List<AllergenHit> _deduplicateHits(List<AllergenHit> hits) {
    final unique = <String, AllergenHit>{};

    for (final hit in hits) {
      final key = '${hit.allergenKey}_${hit.section}_${hit.lineIndex}';

      if (unique.containsKey(key)) {
        // Keep the hit with higher confidence
        if (hit.confidence > unique[key]!.confidence) {
          unique[key] = hit;
        }
      } else {
        unique[key] = hit;
      }
    }

    return unique.values.toList();
  }

  bool _isLikelyIngredientsContext(List<String> normalizedLines, int i) {
    // Look for ingredients context in a wider range
    for (int k = 1; k <= 3; k++) {
      final j = i - k;
      if (j >= 0) {
        final prev = normalizedLines[j];
        if (prev.startsWith('ingredients') || prev.contains('ingredients:') ||
            prev.startsWith('ingrédients') || prev.contains('ingrédients:')) {
          return true;
        }
      }
    }

    // Look for common ingredient indicators in current or adjacent lines
    for (int k = -1; k <= 1; k++) {
      final checkIndex = i + k;
      if (checkIndex >= 0 && checkIndex < normalizedLines.length) {
        final checkLine = normalizedLines[checkIndex];
        // Check if line contains common ingredient patterns
        if (_looksLikeIngredients(checkLine)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _looksLikeIngredients(String line) {
    // Common ingredient list patterns
    final ingredientIndicators = [
      'wheat flour', 'sugar', 'salt', 'water', 'oil', 'corn', 'rice',
      'milk powder', 'egg', 'soy', 'modified', 'artificial', 'natural',
      'preservative', 'color', 'flavor', 'extract', 'syrup', 'protein',
      'starch', 'gum', 'lecithin', 'citric', 'sodium', 'calcium', 'potassium'
    ];

    final lowerLine = line.toLowerCase();
    int matches = 0;

    for (final indicator in ingredientIndicators) {
      if (lowerLine.contains(indicator)) {
        matches++;
      }
    }

    // If multiple ingredient indicators are found, likely ingredients section
    return matches >= 2;
  }

  String _classifySection(String line) {
    // Enhanced "contains" patterns
    if (line.contains('contains:') || line.startsWith('contains ') ||
        line.contains('contains,') || line.contains('contains.') ||
        line.contains('allergens:') || line.startsWith('allergens ')) {
      return 'contains';
    }

    // Enhanced "may contain" patterns - more comprehensive detection
    final mayContainPatterns = [
      'may contain',
      'may also contain',
      'may be present',
      'possible traces',
      'traces of',
      'trace amounts',
      'produced in a facility',
      'manufactured in a facility',
      'may have come into contact',
      'possible cross-contamination',
      'cross-contamination',
      'allergen information',
      'allergy information',
      'allergy advice',
      'warning: may contain',
      'caution: may contain',
      'note: may contain',
      'may include',
      'might contain',
      'could contain',
      'sometimes contains',
      'occasionally contains',
    ];

    final lowerLine = line.toLowerCase();
    for (final pattern in mayContainPatterns) {
      if (lowerLine.contains(pattern)) {
        return 'may_contain';
      }
    }

    // Enhanced ingredients patterns
    if (line.startsWith('ingredients') || line.contains('ingredients:') ||
        line.startsWith('ingrédients') || line.contains('ingrédients:') ||
        line.contains('ingredient list') || line.contains('list of ingredients')) {
      return 'ingredients';
    }

    return '';
  }

  bool _negated(String originalLine) {
    final s = TextNormalization.normalizeBasic(originalLine);
    if (s.contains('free from ') || s.contains('free-from ')) return true;
    if (s.contains('does not contain')) return true;
    if (s.contains('without ')) return true;
    return false;
  }

  // FIX: return a nullable class type, not a record
  _IndexPair? _fuzzyFind(String haystack, String needle) {
    if (needle.length < 4) return null;
    final window = needle.length;
    for (int i = 0; i + window <= haystack.length; i++) {
      final segment = haystack.substring(i, i + window);
      if (_editDistanceLeq(segment, needle, 1)) {
        return _IndexPair(i, i + window);
      }
    }
    return null;
  }

  // FIX: use substring to access characters in Dart strings
  bool _editDistanceLeq(String a, String b, int maxEdits) {
    if ((a.length - b.length).abs() > maxEdits) return false;
    int edits = 0;
    int i = 0, j = 0;
    while (i < a.length && j < b.length) {
      final ai = a.substring(i, i + 1);
      final bj = b.substring(j, j + 1);
      if (ai == bj) {
        i++; j++;
      } else {
        edits++;
        if (edits > maxEdits) return false;
        // Try substitution, insertion, deletion
        final canSub = (i + 1 < a.length && j + 1 < b.length) &&
            (a.substring(i + 1, i + 2) == b.substring(j + 1, j + 2));
        final canDel = (i + 1 < a.length) &&
            (a.substring(i + 1, i + 2) == bj);
        final canIns = (j + 1 < b.length) &&
            (ai == b.substring(j + 1, j + 2));
        if (canSub) { i++; j++; }
        else if (canDel) { i++; }
        else if (canIns) { j++; }
        else { i++; j++; }
      }
    }
    edits += (a.length - i) + (b.length - j);
    return edits <= maxEdits;
  }
}

class _IndexPair {
  final int item1;
  final int item2;
  _IndexPair(this.item1, this.item2);
}