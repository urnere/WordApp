import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:word_app/models/word.dart';
import 'package:word_app/services/isar_service.dart';

class WordList extends StatefulWidget {
  final Function(Word) onEditWord;
  final IsarService isarService;
  const WordList({
    super.key,
    required this.isarService,
    required this.onEditWord,
  });

  @override
  State<WordList> createState() => _WordListState();
}

class _WordListState extends State<WordList> {
  final List<String> _wordTypes = [
    "all",
    "noun",
    "verb",
    "adjective",
    "adverb",
  ];
  String _selectedWordType = "all";
  bool showLearned = false;
  List<Word> _words = [];
  List<Word> _filteredWords = [];
  late Future<List<Word>> _getAllWords;

  void _refreshWord() {
    setState(() {
      _getAllWords = _getWordsDB();
    });
  }

  _deleteWord(Word silinecekKeilme) async {
    await widget.isarService.deleteWord(silinecekKeilme.id);
    _words.removeWhere((element) => element.id == silinecekKeilme.id);
  }

  void _applyFilter() {
    _filteredWords = List.from(_words);
    if (_selectedWordType != "all") {
      _filteredWords =
          _filteredWords
              .where((element) => element.wordType == _selectedWordType)
              .toList();
    }
    if (showLearned) {
      _filteredWords =
          _filteredWords
              .where((element) => element.isLearned == !showLearned)
              .toList();
    }
  }

  _buildFilterCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list),
                const Text("Filtrele"),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Kelime Türü",
                    ),
                    value: _selectedWordType,
                    items:
                        _wordTypes.map((e) {
                          return DropdownMenuItem(value: e, child: Text(e));
                        }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedWordType = value!;
                        _applyFilter();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Öğrendiklerimi gizle"),
                const SizedBox(width: 10),
                Switch(
                  value: showLearned,
                  onChanged: (value) {
                    setState(() {
                      showLearned = !showLearned;
                      _applyFilter();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getAllWords = _getWordsDB();
  }

  _toggleUpdateWord(Word oankiKelime) async {
    await widget.isarService.toggleWorldLearn(oankiKelime.id);
    final index = _words.indexWhere((element) => element.id == oankiKelime.id);
    var degistirilenKelime = _words[index];
    degistirilenKelime.isLearned = !degistirilenKelime.isLearned;
    setState(() {});
  }

  Future<List<Word>> _getWordsDB() async {
    var dbKelime = await widget.isarService.getAllWord();
    _words = dbKelime;
    return dbKelime;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterCard(),
        Expanded(
          child: FutureBuilder<List<Word>>(
            future: _getAllWords,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                Center(child: Text("Hata var: ${snapshot.error.toString()}"));
              }
              if (snapshot.hasData) {
                return snapshot.data?.length == 0
                    ? const Center(child: Text("Lütfen kelime ekleyin"))
                    : _buildListView(snapshot.data!);
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  _buildListView(List<Word> data) {
    _applyFilter();
    return ListView.builder(
      itemBuilder: (context, index) {
        var oankiKelime = _filteredWords[index];
        return Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => _deleteWord(oankiKelime),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    " ${oankiKelime.englishWord} Kelimesini silmek istediğinize emin misiniz?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text("Hayır"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text("Evet"),
                    ),
                  ],
                );
              },
            );
          },
          background: Container(
            padding: const EdgeInsets.only(right: 10),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                widget.onEditWord(oankiKelime);
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          oankiKelime.englishWord,
                          style: TextStyle(
                            decoration:
                                oankiKelime.isLearned
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text(
                          oankiKelime.turkishWord,
                          style: TextStyle(
                            decoration:
                                oankiKelime.isLearned
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                          ),
                        ),
                        leading: Chip(
                          label: Text(
                            oankiKelime.wordType,
                            style: TextStyle(
                              decoration:
                                  oankiKelime.isLearned
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                            ),
                          ),
                        ),
                        trailing: Switch(
                          value: oankiKelime.isLearned,
                          onChanged: (value) => _toggleUpdateWord(oankiKelime),
                        ),
                      ),
                      if (oankiKelime.story != null &&
                          oankiKelime.story!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lightbulb),
                                  Text(
                                    "Hatırlatıcı Not",
                                    style: TextStyle(
                                      decoration:
                                          oankiKelime.isLearned
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  oankiKelime.story ??
                                      "Bu kelime hakkında bir hikaye yok",
                                  style: TextStyle(
                                    decoration:
                                        oankiKelime.isLearned
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (oankiKelime.imagesBytes != null)
                        Image.memory(
                          Uint8List.fromList(oankiKelime.imagesBytes!),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      itemCount: _filteredWords.length,
    );
  }
}
