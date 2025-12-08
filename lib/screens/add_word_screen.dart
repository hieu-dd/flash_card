import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/vocabulary_provider.dart';

class AddWordScreen extends StatefulWidget {
  const AddWordScreen({super.key});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _phoneticController = TextEditingController();
  final _meaningController = TextEditingController();
  final _exampleController = TextEditingController();
  final _categoryController = TextEditingController();

  void _saveWord() {
    if (_formKey.currentState!.validate()) {
      Provider.of<VocabularyProvider>(context, listen: false).addWord(
        _wordController.text.trim(),
        _phoneticController.text.trim(),
        _meaningController.text.trim(),
        _exampleController.text.trim(),
        _categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim(),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VocabularyProvider>(context, listen: false);
    final existingCategories = provider.categories.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Word')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _wordController,
                decoration: const InputDecoration(labelText: 'Word (e.g. Environment)', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneticController,
                decoration: const InputDecoration(labelText: 'Phonetic (e.g. /.../)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _meaningController,
                decoration: const InputDecoration(labelText: 'Meaning (Vietnamese)', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _exampleController,
                decoration: const InputDecoration(labelText: 'Example Sentence', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category (Optional)', border: OutlineInputBorder()),
              ),

              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saveWord,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Save Word'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
