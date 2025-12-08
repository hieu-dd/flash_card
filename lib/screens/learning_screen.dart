import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../models/vocabulary.dart';
import '../providers/vocabulary_provider.dart';

class LearningScreen extends StatefulWidget {
  final int wordCount;
  final List<String>? categories;

  const LearningScreen({super.key, required this.wordCount, this.categories});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  late List<Vocabulary> _learningWords;
  int _currentIndex = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  Vocabulary? _selectedOption;
  late List<Vocabulary> _currentOptions;
  bool _isEnglishQuestion = true; // Randomly toggled per question
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _learningWords = Provider.of<VocabularyProvider>(context, listen: false)
        .getQuizWords(widget.wordCount, categories: widget.categories);
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
    if (_currentIndex >= _learningWords.length) return;

    _showResult = false;
    _selectedOption = null;
    _isEnglishQuestion = Random().nextBool();
    
    final currentWord = _learningWords[_currentIndex];
    
    // Get distractors
    final provider = Provider.of<VocabularyProvider>(context, listen: false);
    final distractors = provider.getLearningOptions(currentWord, 4);
    
    _currentOptions = [currentWord, ...distractors];
    _currentOptions.shuffle();
  }

  void _checkAnswer(Vocabulary selected) {
    if (_showResult) return;

    final currentWord = _learningWords[_currentIndex];
    final isCorrect = selected.id == currentWord.id;

    setState(() {
      _isCorrect = isCorrect;
      _showResult = true;
      _selectedOption = selected;
    });

    Provider.of<VocabularyProvider>(context, listen: false)
        .updateWordStatus(currentWord, isCorrect);

    // Auto play pronunciation if correct or just always? 
    // User asked: "đồng thời có thêm tính năng phát âm để ngườid dùng nghe từ đó phát âm như nào"
    // I'll play it when result is shown.
    _speak(currentWord.word);
  }

  void _nextQuestion() {
    if (_currentIndex < _learningWords.length - 1) {
      setState(() {
        _currentIndex++;
        _setupQuestion();
      });
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Learning Session Complete!')),
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
    if (_learningWords.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentWord = _learningWords[_currentIndex];
    final questionText = _isEnglishQuestion ? currentWord.word : currentWord.meaning;
    final questionLabel = _isEnglishQuestion ? 'Select the meaning' : 'Select the English word';

    return Scaffold(
      appBar: AppBar(
        title: Text('Learning (${_currentIndex + 1}/${_learningWords.length})'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (_isEnglishQuestion) ...[
              const SizedBox(height: 8),
              Text(
                currentWord.phonetic,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
             if (_isEnglishQuestion)
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () => _speak(currentWord.word),
              ),
            const SizedBox(height: 32),
            ..._currentOptions.map((option) {
              final isSelected = _selectedOption == option;
              final isCorrectOption = option.id == currentWord.id;
              
              Color? backgroundColor;
              if (_showResult) {
                if (isCorrectOption) {
                  backgroundColor = Colors.green.shade100;
                } else if (isSelected && !isCorrectOption) {
                  backgroundColor = Colors.red.shade100;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(
                      color: _showResult && (isCorrectOption || (isSelected && !isCorrectOption))
                          ? (isCorrectOption ? Colors.green : Colors.red)
                          : Colors.grey.shade300,
                    ),
                  ),
                  onPressed: _showResult ? null : () => _checkAnswer(option),
                  child: Text(
                    _isEnglishQuestion ? option.meaning : option.word,
                    style: TextStyle(
                      fontSize: 16,
                      color: _showResult && (isCorrectOption || isSelected) 
                          ? Colors.black 
                          : null,
                    ),
                  ),
                ),
              );
            }),
            if (_showResult) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isCorrect ? Colors.green.shade200 : Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      _isCorrect ? 'Correct!' : 'Incorrect',
                      style: TextStyle(
                        color: _isCorrect ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!_isCorrect)
                      Text('Correct answer: ${_isEnglishQuestion ? currentWord.meaning : currentWord.word}'),
                    const SizedBox(height: 8),
                    Text(currentWord.phonetic, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text('Example:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(currentWord.example, style: const TextStyle(fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () => _speak(currentWord.word),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _nextQuestion,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Next'),
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}
