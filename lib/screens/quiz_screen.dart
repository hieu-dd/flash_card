import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../models/vocabulary.dart';
import '../providers/vocabulary_provider.dart';

class QuizScreen extends StatefulWidget {
  final int wordCount;
  final List<String>? categories;

  const QuizScreen({super.key, required this.wordCount, this.categories});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Vocabulary> _quizWords;
  int _currentIndex = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  final _answerController = TextEditingController();
  bool _isEnglishToVietnamese = true; // Randomly toggled
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _quizWords = Provider.of<VocabularyProvider>(context, listen: false).getQuizWords(widget.wordCount, categories: widget.categories);
    _setupQuestion();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _setupQuestion() {
    _showResult = false;
    _answerController.clear();
    _isEnglishToVietnamese = Random().nextBool();
  }

  void _checkAnswer() {
    if (_showResult) return;

    final currentWord = _quizWords[_currentIndex];
    final userAnswer = _answerController.text.trim().toLowerCase();
    final correctAnswer = _isEnglishToVietnamese ? currentWord.meaning : currentWord.word;
    
    // Simple normalization for comparison
    final normalizedCorrect = correctAnswer.toLowerCase().trim();

    setState(() {
      _isCorrect = userAnswer == normalizedCorrect;
      _showResult = true;
    });

    Provider.of<VocabularyProvider>(context, listen: false).updateWordStatus(currentWord, _isCorrect);
    _speak(currentWord.word);
  }

  void _nextQuestion() {
    if (_currentIndex < _quizWords.length - 1) {
      setState(() {
        _currentIndex++;
        _setupQuestion();
      });
    } else {
      // End of quiz
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session Complete! Great job!')),
      );
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_quizWords.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentWord = _quizWords[_currentIndex];
    final questionText = _isEnglishToVietnamese ? currentWord.word : currentWord.meaning;
    final questionLabel = _isEnglishToVietnamese ? 'Translate to Vietnamese' : 'Translate to English';

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz (${_currentIndex + 1}/${_quizWords.length})'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              questionLabel,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              questionText,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (_isEnglishToVietnamese) ...[
              Text(
                currentWord.phonetic,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () => _speak(currentWord.word),
              ),
            ],
            const SizedBox(height: 32),
            TextField(
              controller: _answerController,
              enabled: !_showResult,
              decoration: InputDecoration(
                labelText: 'Your Answer',
                border: const OutlineInputBorder(),
                suffixIcon: _showResult
                    ? Icon(
                        _isCorrect ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect ? Colors.green : Colors.red,
                      )
                    : null,
              ),
              onSubmitted: (_) => _checkAnswer(),
            ),
            const SizedBox(height: 24),
            if (_showResult) ...[
              if (!_isCorrect)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text('Incorrect!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Correct Answer: ${_isEnglishToVietnamese ? currentWord.meaning : currentWord.word}'),
                      const SizedBox(height: 8),
                      Text(currentWord.phonetic, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('Example: ${currentWord.example}', style: const TextStyle(fontStyle: FontStyle.italic)),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () => _speak(currentWord.word),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Center(
                    child: Text('Correct! Well done.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _nextQuestion,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Next Word'),
                ),
              ),
            ] else ...[
              const Spacer(),
              FilledButton(
                onPressed: _checkAnswer,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Check Answer'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
