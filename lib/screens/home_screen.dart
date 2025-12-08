import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/vocabulary_provider.dart';
import 'add_word_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _startLearning(BuildContext context) {
    final provider = Provider.of<VocabularyProvider>(context, listen: false);
    if (provider.totalWords == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some words first!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        int maxWords = min(20, provider.totalWords);
        int count = min(5, maxWords);
        return AlertDialog(
          title: const Text('Start Learning'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('How many words? ($count)'),
                  if (maxWords > 1)
                    Slider(
                      value: count.toDouble(),
                      min: 1,
                      max: maxWords.toDouble(),
                      divisions: maxWords - 1,
                      label: count.toString(),
                      onChanged: (value) {
                        setState(() {
                          count = value.toInt();
                        });
                      },
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(wordCount: count),
                  ),
                );
              },
              child: const Text('Start'),
            ),
          ],
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
                          _buildStatItem('Total Words', '${provider.totalWords}'),
                          _buildStatItem('To Review', '${provider.words.where((w) => w.weight > 50).length}'),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _startLearning(context),
                      icon: const Icon(Icons.school),
                      label: const Text('Start Learning'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
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
                        title: Text(word.word, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${word.phonetic} • ${word.meaning}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getWeightColor(word.weight),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'W: ${word.weight.toStringAsFixed(1)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
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
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
