import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/vocabulary.dart';

class VocabularyProvider extends ChangeNotifier {
  late Box<Vocabulary> _box;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  List<Vocabulary> get words {
    if (!_isInitialized) return [];
    var allWords = _box.values.toList();
    allWords.sort((a, b) => b.weight.compareTo(a.weight)); // Sort by weight descending
    return allWords;
  }

  int get totalWords => _isInitialized ? _box.length : 0;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(VocabularyAdapter());
    _box = await Hive.openBox<Vocabulary>('vocabularyBox');
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> addWord(String word, String phonetic, String meaning, String example) async {
    final newWord = Vocabulary(
      id: const Uuid().v4(),
      word: word,
      phonetic: phonetic,
      meaning: meaning,
      example: example,
      lastReviewed: DateTime.now(),
    );
    await _box.put(newWord.id, newWord);
    notifyListeners();
  }

  // Adaptive Weighted Random Selection
  List<Vocabulary> getQuizWords(int count) {
    if (words.isEmpty) return [];
    
    final selectedWords = <Vocabulary>[];
    final availableWords = List<Vocabulary>.from(words);
    final random = Random();

    count = min(count, availableWords.length);

    for (int i = 0; i < count; i++) {
      double totalWeight = availableWords.fold(0, (sum, item) => sum + item.weight);
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
