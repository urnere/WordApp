import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:word_app/models/word.dart';

class IsarService {
  late Isar isar;

  init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open([WordSchema], directory: dir.path);
      debugPrint("Isar çalıştı ${dir.path}");
    } catch (e) {
      debugPrint("Isar init olurken hata $e");
    }
  }

  Future<void> saveWord(Word word) async {
    try {
      await isar.writeTxn(() async {
        await isar.words.put(word);
      });
    } catch (e) {
      debugPrint("EKleme yapılırken hata oluştu: $e");
    }
  }

  Future<void> deleteWord(int id) async {
    try {
      await isar.writeTxn(() async {
        final success = await isar.words.delete(id);
        debugPrint('Recipe deleted: $success');
      });
    } catch (e) {
      debugPrint("EKleme yapılırken hata oluştu: $e");
    }
  }

  Future<void> updateWord(Word word) async {
    try {
      await isar.writeTxn(() async {
        final id = await isar.words.put(word);
        debugPrint("$id' li  ${word.englishWord} kelimesi güncellendi");
      });
    } catch (e) {
      debugPrint("EKleme yapılırken hata oluştu: $e");
    }
  }

  Future<List<Word>> getAllWord() async {
    try {
      final words = await isar.words.where().findAll();
      return words;
    } catch (e) {
      debugPrint("Hata: $e");
      return [];
    }
  }

  Future<void> toggleWorldLearn(int id) async {
    try {
      await isar.writeTxn(() async {
        final word = await isar.words.get(id);
        if (word != null) {
          word.isLearned = !word.isLearned;
          await isar.words.put(word);
          debugPrint("Kelime güncellendi");
        }
      });
    } catch (e) {
      debugPrint("Kelime bulunamadı");
    }
  }
}
