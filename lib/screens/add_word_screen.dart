import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:word_app/models/word.dart';
import 'package:word_app/services/isar_service.dart';

class AddWord extends StatefulWidget {
  final IsarService isarService;
  final VoidCallback onSave;
  final Word? wordToEdit;
  const AddWord({
    super.key,
    required this.isarService,
    required this.onSave,
    this.wordToEdit,
  });

  @override
  State<AddWord> createState() => _AddWordState();
}

class _AddWordState extends State<AddWord> {
  final _formKey = GlobalKey<FormState>();
  final _englishWordController = TextEditingController();
  final _turkishWordController = TextEditingController();
  final _storyController = TextEditingController();
  String _selectedWordType = "noun";
  final List<String> _wordTypes = ["noun", "verb", "adjective", "adverb"];
  bool _isLearned = false;
  final ImagePicker _imagePicker = ImagePicker();
  File? _image;

  @override
  void initState() {
    super.initState();
    if (widget.wordToEdit != null) {
      var updatingWord = widget.wordToEdit!;
      _englishWordController.text = updatingWord.englishWord;
      _turkishWordController.text = updatingWord.turkishWord;
      _storyController.text = updatingWord.story!;
      _selectedWordType = updatingWord.wordType;
      _isLearned = updatingWord.isLearned;
    }
  }

  @override
  void dispose() {
    _englishWordController.dispose();
    _turkishWordController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  void _resimSec() async {
    await _imagePicker.pickImage(source: ImageSource.gallery).then((value) {
      if (value != null) {
        setState(() {
          _image = File(value.path);
        });
      }
    });
  }

  Future<void> _saveWord() async {
    if (_formKey.currentState!.validate()) {
      var englishWord = _englishWordController.text;
      var turkishWord = _turkishWordController.text;
      var story = _storyController.text;
      var word = Word(
        englishWord: englishWord,
        turkishWord: turkishWord,
        isLearned: _isLearned,
        wordType: _selectedWordType,
        story: story,
      );

      if (widget.wordToEdit == null) {
        word.imagesBytes = _image != null ? await _image!.readAsBytes() : null;

        await widget.isarService.saveWord(word);
      } else {
        word.id = widget.wordToEdit!.id;
        word.imagesBytes =
            _image != null
                ? await _image!.readAsBytes()
                : widget.wordToEdit!.imagesBytes;
        await widget.isarService.updateWord(word);
      }

      widget.onSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 10),
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an English word';
                }
                return null;
              },
              controller: _englishWordController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "English Word",
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an Turkish word';
                }
                return null;
              },
              controller: _turkishWordController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Turkish Word",
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              value: _selectedWordType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Word Type",
              ),
              items:
                  _wordTypes.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedWordType = value.toString();
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter story';
                }
                return null;
              },
              maxLines: 3,
              controller: _storyController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Story",
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Learned"),
                const SizedBox(width: 16),
                Switch(
                  value: _isLearned,
                  onChanged: (value) {
                    setState(() {
                      _isLearned = !_isLearned;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resimSec,
              label: const Text("Resim Ekle"),
              icon: const Icon(Icons.image),
            ),
            const SizedBox(height: 16),
            if (_image != null || widget.wordToEdit?.imagesBytes != null) ...[
              if (_image != null)
                Image.file(_image!, height: 150, fit: BoxFit.cover)
              else if (widget.wordToEdit?.imagesBytes != null)
                Image.memory(
                  Uint8List.fromList(widget.wordToEdit!.imagesBytes!),
                  height: 150,
                  fit: BoxFit.cover,
                ),
            ],

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveWord,
              child:
                  widget.wordToEdit == null
                      ? const Text("Save")
                      : const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
