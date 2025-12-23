import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../models/vocabulary.dart';
import '../providers/vocabulary_provider.dart';

enum QuizAnswerTarget { english, vietnamese, random }

class QuizScreen extends StatefulWidget {
  final int wordCount;
  final List<String>? categories;
  final QuizAnswerTarget answerTarget;

  const QuizScreen({
    super.key,
    required this.wordCount,
    this.categories,
    this.answerTarget = QuizAnswerTarget.random,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Vocabulary> _quizWords;
  int _currentIndex = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  bool _canProceed =
      false; // New state to control if user can go to next question
  final _answerController = TextEditingController();
  bool _isEnglishToVietnamese = true; // Randomly toggled
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _quizWords = Provider.of<VocabularyProvider>(
      context,
      listen: false,
    ).getQuizWords(widget.wordCount, categories: widget.categories);
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
    _canProceed = false;
    _answerController.clear();

    switch (widget.answerTarget) {
      case QuizAnswerTarget.english:
        _isEnglishToVietnamese = false; // Question VN -> Answer EN
        break;
      case QuizAnswerTarget.vietnamese:
        _isEnglishToVietnamese = true; // Question EN -> Answer VN
        break;
      case QuizAnswerTarget.random:
        _isEnglishToVietnamese = Random().nextBool();
        break;
    }
  }

  String _getCorrectAnswer() {
    final currentWord = _quizWords[_currentIndex];
    return _isEnglishToVietnamese ? currentWord.meaning : currentWord.word;
  }

  String _removeDiacritics(String str) {
    const withDiacritics =
        'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ';
    const withoutDiacritics =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';

    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return str;
  }

  String _normalizeAnswer(String input) {
    final lower = input
        .toLowerCase()
        .replaceAll(" ", "")
        .replaceAll(",", "")
        .replaceAll(".", "")
        .replaceAll("!", "")
        .replaceAll("?", "")
        .replaceAll(";", "")
        .replaceAll(":", "")
        .replaceAll("\n", "")
        .trim();
    return _removeDiacritics(lower);
  }

  void _checkAnswer() {
    if (_showResult) return;

    final currentWord = _quizWords[_currentIndex];
    final userAnswer = _answerController.text;
    final correctAnswer = _getCorrectAnswer();

    final normalizedUser = _normalizeAnswer(userAnswer);
    final normalizedCorrect = _normalizeAnswer(correctAnswer);

    setState(() {
      _isCorrect = normalizedUser == normalizedCorrect;
      _showResult = true;
      _canProceed = _isCorrect;
    });

    Provider.of<VocabularyProvider>(
      context,
      listen: false,
    ).updateWordStatus(currentWord, _isCorrect);
    _speak(currentWord.word);
  }

  void _checkRetry(String value) {
    // Only called when answer was wrong and result is shown
    final correctAnswer = _getCorrectAnswer();

    final normalizedCorrect = _normalizeAnswer(correctAnswer);
    final normalizedRetry = _normalizeAnswer(value);

    setState(() {
      // Allow proceed if user types exactly the correct answer (normalized)
      _canProceed = normalizedRetry == normalizedCorrect;
    });
  }

  void _markAsCorrect() {
    final currentWord = _quizWords[_currentIndex];
    // User claims they were correct. Update provider to reflect success.
    Provider.of<VocabularyProvider>(
      context,
      listen: false,
    ).updateWordStatus(currentWord, true);

    setState(() {
      _isCorrect = true;
      _canProceed = true;
    });

    // Auto proceed or let user click next?
    // Requirement says "Next to next question", let's move automatically or just enable Next.
    // "Option 1... next sang câu tiếp theo" implies action.
    // Let's just move to next question immediately for better UX if they click the button.
    _nextQuestion();
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
    if (_quizWords.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentWord = _quizWords[_currentIndex];
    final questionText = _isEnglishToVietnamese
        ? currentWord.word
        : currentWord.meaning;
    final questionLabel = _isEnglishToVietnamese
        ? 'Translate to Vietnamese'
        : 'Translate to English';

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz (${_currentIndex + 1}/${_quizWords.length})'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        questionLabel,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        questionText,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_isEnglishToVietnamese) ...[
                        Text(
                          currentWord.phonetic,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
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
                        enabled:
                            !_showResult ||
                            !_isCorrect, // Allow editing if incorrect to retry
                        onChanged: (value) {
                          if (_showResult && !_isCorrect) {
                            _checkRetry(value);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Your Answer',
                          border: const OutlineInputBorder(),
                          suffixIcon: _showResult
                              ? Icon(
                                  _isCorrect
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _isCorrect ? Colors.green : Colors.red,
                                )
                              : null,
                        ),
                        onSubmitted: (_) {
                          if (!_showResult) {
                            _checkAnswer();
                          }
                        },
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
                                const Text(
                                  'Incorrect!',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Correct Answer: ${_getCorrectAnswer()}'),
                                const SizedBox(height: 8),
                                Text(
                                  currentWord.phonetic,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Example: ${currentWord.example}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.volume_up),
                                      onPressed: () => _speak(currentWord.word),
                                    ),
                                    TextButton.icon(
                                      onPressed: _markAsCorrect,
                                      icon: const Icon(Icons.check),
                                      label: const Text("I was correct"),
                                    ),
                                  ],
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
                              child: Text(
                                'Correct! Well done.',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _canProceed ? _nextQuestion : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _canProceed
                                  ? 'Next Word'
                                  : 'Type correct answer to continue',
                            ),
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
              ),
            ),
          );
        },
      ),
    );
  }
}
