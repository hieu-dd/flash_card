import 'dart:math';

import 'package:flash_cards/data/environment_data.dart';
import 'package:flash_cards/data/food_data.dart';
import 'package:flash_cards/data/pet_data.dart';
import 'package:flash_cards/data/travel_data.dart';
import 'package:flash_cards/data/common/a_common_data.dart';
import 'package:flash_cards/data/common/b_common_data.dart';
import 'package:flash_cards/data/common/c_common_data.dart';
import 'package:flash_cards/data/common/d_common_data.dart';
import 'package:flash_cards/data/common/e_common_data.dart';
import 'package:flash_cards/data/common/f_common_data.dart';
import 'package:flash_cards/data/common/g_common_data.dart';
import 'package:flash_cards/data/common/h_common_data.dart';
import 'package:flash_cards/data/common/i_common_data.dart';
import 'package:flash_cards/data/common/j_common_data.dart';
import 'package:flash_cards/data/common/k_common_data.dart';
import 'package:flash_cards/data/common/l_common_data.dart';
import 'package:flash_cards/data/common/m_common_data.dart';
import 'package:flash_cards/data/common/n_common_data.dart';
import 'package:flash_cards/data/common/o_common_data.dart';
import 'package:flash_cards/data/common/p_common_data.dart';
import 'package:flash_cards/data/common/q_common_data.dart';
import 'package:flash_cards/data/common/r_common_data.dart';
import 'package:flash_cards/data/common/s_common_data.dart';
import 'package:flash_cards/data/common/t_common_data.dart';
import 'package:flash_cards/data/common/u_common_data.dart';
import 'package:flash_cards/data/common/v_common_data.dart';
import 'package:flash_cards/data/common/w_common_data.dart';
import 'package:flash_cards/data/common/y_common_data.dart';
import 'package:flash_cards/models/vocabulary.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class VocabularyProvider extends ChangeNotifier {
  late Box<Vocabulary> _box;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  List<Vocabulary> get words {
    if (!_isInitialized) return [];
    var allWords = _box.values.toList();
    allWords.sort(
      (a, b) => b.weight.compareTo(a.weight),
    ); // Sort by weight descending
    return allWords;
  }

  Set<String> get categories {
    if (!_isInitialized) return {};
    return _box.values.map((w) => w.category).toSet();
  }

  int get totalWords => _isInitialized ? _box.length : 0;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(VocabularyAdapter());
    _box = await Hive.openBox<Vocabulary>('vocabularyBox');

    await _seedDefaultData();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _seedDefaultData() async {
    final allDefaults = [
      ...environmentVocabulary,
      ...foodVocabulary,
      ...travelVocabulary,
      ...petVocabulary,
      ...aCommonVocabulary,
      ...bCommonVocabulary,
      ...cCommonVocabulary,
      ...dCommonVocabulary,
      ...eCommonVocabulary,
      ...fCommonVocabulary,
      ...gCommonVocabulary,
      ...hCommonVocabulary,
      ...iCommonVocabulary,
      ...jCommonVocabulary,
      ...kCommonVocabulary,
      ...lCommonVocabulary,
      ...mCommonVocabulary,
      ...nCommonVocabulary,
      ...oCommonVocabulary,
      ...pCommonVocabulary,
      ...qCommonVocabulary,
      ...rCommonVocabulary,
      ...sCommonVocabulary,
      ...tCommonVocabulary,
      ...uCommonVocabulary,
      ...vCommonVocabulary,
      ...wCommonVocabulary,
      ...yCommonVocabulary,
    ];

    if (_box.isEmpty) {
      for (var item in allDefaults) {
        await _addVocabularyFromMap(item);
      }
    } else {
      // Check for missing default words
      final existingKeys = _box.values
          .map((v) => '${v.word}|${v.category}')
          .toSet();

      for (var item in allDefaults) {
        final key = '${item['word']}|${item['category'] ?? 'General'}';
        if (!existingKeys.contains(key)) {
          await _addVocabularyFromMap(item);
        }
      }
    }
  }

  Future<void> _addVocabularyFromMap(Map<String, String> item) async {
    final newWord = Vocabulary(
      id: const Uuid().v4(),
      word: item['word']!,
      phonetic: item['phonetic']!,
      meaning: item['meaning']!,
      example: item['example']!,
      category: item['category'] ?? 'General',
      lastReviewed: DateTime.now(),
    );
    await _box.put(newWord.id, newWord);
  }

  Future<void> addWord(
    String word,
    String phonetic,
    String meaning,
    String example,
    String category,
  ) async {
    final newWord = Vocabulary(
      id: const Uuid().v4(),
      word: word,
      phonetic: phonetic,
      meaning: meaning,
      example: example,
      category: category,
      lastReviewed: DateTime.now(),
    );
    await _box.put(newWord.id, newWord);
    notifyListeners();
  }

  // Adaptive Weighted Random Selection
  List<Vocabulary> getQuizWords(int count, {List<String>? categories}) {
    if (words.isEmpty) return [];

    var availableWords = List<Vocabulary>.from(words);

    if (categories != null && categories.isNotEmpty) {
      availableWords = availableWords
          .where((w) => categories.contains(w.category))
          .toList();
    }

    if (availableWords.isEmpty) return [];

    final selectedWords = <Vocabulary>[];
    final random = Random();

    count = min(count, availableWords.length);

    for (int i = 0; i < count; i++) {
      double totalWeight = availableWords.fold(
        0,
        (sum, item) => sum + item.weight,
      );
      // If totalWeight is 0 (shouldn't happen with min weight 1.0), avoid NaN
      if (totalWeight == 0) totalWeight = 1;

      double randomWeight = random.nextDouble() * totalWeight;

      double currentSum = 0;
      for (var word in availableWords) {
        currentSum += word.weight;
        if (currentSum >= randomWeight) {
          selectedWords.add(word);
          availableWords.remove(word);
          break;
        }
      }
    }
    return selectedWords;
  }

  // Get distractors for learning mode
  List<Vocabulary> getLearningOptions(Vocabulary correctWord, int count) {
    if (words.isEmpty) return [];

    // Try to get words from same category first
    var sameCategoryWords = words
        .where(
          (w) => w.category == correctWord.category && w.id != correctWord.id,
        )
        .toList();

    // If not enough, fill with other words
    if (sameCategoryWords.length < count) {
      final otherWords = words
          .where(
            (w) => w.category != correctWord.category && w.id != correctWord.id,
          )
          .toList();
      otherWords.shuffle();
      sameCategoryWords.addAll(
        otherWords.take(count - sameCategoryWords.length),
      );
    }

    sameCategoryWords.shuffle();
    return sameCategoryWords.take(count).toList();
  }

  Future<void> updateWordStatus(Vocabulary word, bool isCorrect) async {
    if (isCorrect) {
      // Reduce weight, min 1.0
      word.weight = max(1.0, word.weight * 0.6);
    } else {
      // Increase weight, max 100.0
      word.weight = min(100.0, word.weight + 20.0);
    }
    word.lastReviewed = DateTime.now();
    await word.save();
    notifyListeners();
  }
}
