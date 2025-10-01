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
      final label = _classifySection(line); // "", "contains", "may_contain", "ingredients"
      if (label.isEmpty && !_isLikelyIngredientsContext(normalizedLines, i)) continue;

      final section = label.isNotEmpty ? label : "ingredients";
      final hard = section == "contains";
      final baseConfidence = section == "contains" ? 1.0 : section == "may_contain" ? 0.7 : 0.6;

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
              confidence: baseConfidence,
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
                confidence: baseConfidence - 0.15,
              ));
            }
          }
        }
      });
    }

    // Remove negated lines like "free from", "does not contain"
    return hits.where((h) => !_negated(lines[h.lineIndex])).toList();
  }

  String _classifySection(String line) {
    if (line.contains('contains:') || line.startsWith('contains ')) return 'contains';
    if (line.contains('may contain') || line.contains('may contain:')) return 'may_contain';
    if (line.startsWith('ingredients') || line.contains('ingredients:')) return 'ingredients';
    return '';
  }

  bool _isLikelyIngredientsContext(List<String> normalizedLines, int i) {
    for (int k = 1; k <= 2; k++) {
      final j = i - k;
      if (j >= 0) {
        final prev = normalizedLines[j];
        if (prev.startsWith('ingredients') || prev.contains('ingredients:')) return true;
      }
    }
    return false;
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