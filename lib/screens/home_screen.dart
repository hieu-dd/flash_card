import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/vocabulary_provider.dart';
import 'add_word_screen.dart';
import 'quiz_screen.dart';
import 'learning_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _startQuiz(BuildContext context) {
    _showSetupDialog(context, isQuiz: true);
  }

  void _startLearning(BuildContext context) {
    _showSetupDialog(context, isQuiz: false);
  }

  void _showSetupDialog(BuildContext context, {required bool isQuiz}) {
    final provider = Provider.of<VocabularyProvider>(context, listen: false);
    if (provider.totalWords == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add some words first!')));
      return;
    }

    final allCategories = provider.categories.toList();
    allCategories.sort();

    showDialog(
      context: context,
      builder: (context) {
        int maxWords = min(20, provider.totalWords);
        int count = min(20, maxWords);
        List<String> selectedCategories = [];
        bool studyAll = false;
        QuizAnswerTarget selectedAnswerTarget = QuizAnswerTarget.random;

        return StatefulBuilder(
          builder: (context, setState) {
            // Recalculate max words based on selected categories
            int availableWordsCount = provider.totalWords;
            if (selectedCategories.isNotEmpty) {
              availableWordsCount = provider.words
                  .where((w) => selectedCategories.contains(w.category))
                  .length;
            }

            // Adjust count if needed
            int currentMax = min(20, availableWordsCount);

            if (studyAll) {
              count = availableWordsCount;
            } else {
              if (currentMax == 0) {
                count = 0;
              } else if (count > currentMax) {
                count = currentMax;
              } else if (count == 0 && currentMax > 0) {
                count = min(20, currentMax);
              }
            }

            return AlertDialog(
              title: Text(isQuiz ? 'Start Quiz' : 'Start Learning'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: studyAll,
                          onChanged: (value) {
                            setState(() {
                              studyAll = value ?? false;
                              if (studyAll) {
                                count = availableWordsCount;
                              } else {
                                count = min(20, currentMax);
                              }
                            });
                          },
                        ),
                        const Text('Study All Words'),
                      ],
                    ),
                    if (!studyAll) ...[
                      Text('How many words? ($count)'),
                      if (currentMax > 1)
                        Slider(
                          value: count.toDouble(),
                          min: 1,
                          max: currentMax.toDouble(),
                          divisions: currentMax - 1,
                          label: count.toString(),
                          onChanged: (value) {
                            setState(() {
                              count = value.toInt();
                            });
                          },
                        )
                      else if (currentMax == 0)
                        const Text(
                          'No words available for selected categories.',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Select Categories (Empty = All):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: allCategories.map((category) {
                        return FilterChip(
                          label: Text(category),
                          selected: selectedCategories.contains(category),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                selectedCategories.add(category);
                              } else {
                                selectedCategories.remove(category);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (isQuiz) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Target Answer Language:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Column(
                        children: [
                          RadioListTile<QuizAnswerTarget>(
                            title: const Text('Random (Mix)'),
                            value: QuizAnswerTarget.random,
                            groupValue: selectedAnswerTarget,
                            onChanged: (val) =>
                                setState(() => selectedAnswerTarget = val!),
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<QuizAnswerTarget>(
                            title: const Text('English'),
                            subtitle: const Text('Question: VN -> Answer: EN'),
                            value: QuizAnswerTarget.english,
                            groupValue: selectedAnswerTarget,
                            onChanged: (val) =>
                                setState(() => selectedAnswerTarget = val!),
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<QuizAnswerTarget>(
                            title: const Text('Vietnamese'),
                            subtitle: const Text('Question: EN -> Answer: VN'),
                            value: QuizAnswerTarget.vietnamese,
                            groupValue: selectedAnswerTarget,
                            onChanged: (val) =>
                                setState(() => selectedAnswerTarget = val!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: count > 0
                      ? () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => isQuiz
                                  ? QuizScreen(
                                      wordCount: count,
                                      categories: selectedCategories,
                                      answerTarget: selectedAnswerTarget,
                                    )
                                  : LearningScreen(
                                      wordCount: count,
                                      categories: selectedCategories,
                                    ),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Start'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VocabularyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary Dashboard'),
        centerTitle: true,
      ),
      body: provider.words.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.library_books, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No words yet.\nTap + to add your first word!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Total Words',
                            '${provider.totalWords}',
                          ),
                          _buildStatItem(
                            'To Review',
                            '${provider.words.where((w) => w.weight > 50).length}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        FilledButton.icon(
                          onPressed: () => _startQuiz(context),
                          icon: const Icon(Icons.quiz),
                          label: const Text('Start Quiz'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _startLearning(context),
                          icon: const Icon(Icons.school),
                          label: const Text('Start Learning'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.words.length,
                    itemBuilder: (context, index) {
                      final word = provider.words[index];
                      return ListTile(
                        title: Text(
                          word.word,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${word.phonetic} • ${word.meaning}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getWeightColor(word.weight),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'W: ${word.weight.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddWordScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getWeightColor(double weight) {
    if (weight < 30) return Colors.green;
    if (weight < 70) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
