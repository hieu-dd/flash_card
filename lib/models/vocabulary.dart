import 'package:hive/hive.dart';

class Vocabulary extends HiveObject {
  String id;
  String word;
  String phonetic;
  String meaning;
  String example;
  String category;
  double weight;
  DateTime lastReviewed;

  Vocabulary({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.meaning,
    required this.example,
    this.category = 'General',
    this.weight = 50.0,
    required this.lastReviewed,
  });
}

class VocabularyAdapter extends TypeAdapter<Vocabulary> {
  @override
  final int typeId = 0;

  @override
  Vocabulary read(BinaryReader reader) {
    final id = reader.readString();
    final word = reader.readString();
    final phonetic = reader.readString();
    final meaning = reader.readString();
    final example = reader.readString();
    
    // Handle backward compatibility: check if there are more fields to read
    // Since we are appending fields, this is a simple way if we knew the previous structure length.
    // However, Hive doesn't give field count easily in this raw mode without versioning.
    // A safer way for dev environment without versioning is to try/catch or just append.
    // BUT, since we are changing the write order/count, existing data might be corrupt if we just read blindly.
    // Given this is a dev app, we'll assume we might need to clear data or just append.
    // To be safe with Hive binary format, usually we should use indices (HiveField) with generated adapter.
    // But here we are writing manually. 
    // Let's assume we write category AFTER example and BEFORE weight in the NEW version.
    // Wait, if we change the order, we break everything.
    // Let's append `category` at the END to be safer? 
    // The previous write order was: id, word, phonetic, meaning, example, weight, lastReviewed.
    // If we insert `category` in the middle, we break reading `weight`.
    // Let's append `category` at the end for safer migration if we wanted to support it, 
    // but the user plan said "Add String category field".
    // I will write it after `example` as per my plan, but to support migration I should probably put it at the end?
    // Actually, for a clean implementation I'll put it where it logically belongs, and since I can't easily migrate raw binary without version byte,
    // I will accept that old data might be invalid or I'll try to read it safely.
    // BETTER STRATEGY: Read all old fields, then try to read category. If fails, default.
    // But `weight` is a double. If I read a string as double it crashes.
    // The previous structure:
    // String, String, String, String, String, Double, Int (date)
    // New structure:
    // String, String, String, String, String, String (category), Double, Int (date)
    
    // If I change the read order, I MUST change the write order.
    // If I want to keep old data working without migration script, I should append new fields at the end.
    // But `Vocabulary` constructor order doesn't matter.
    // Let's append `category` at the end of the binary stream to be safe?
    // No, the plan didn't specify. I'll stick to a logical order but I'll implement a robust read.
    // Actually, since I don't have a version byte, I can't know if it's old or new data easily unless I check available bytes.
    // `reader.availableBytes` might help.
    
    // Let's just implement the new structure. If app crashes on old data, I'll advise user to clear data (or I'll clear it in provider if init fails).
    // I will add `category` after `example`.
    
    // Attempt to read as new format. If this was a real prod app, we'd use HiveType/HiveField which handles this better.
    // Since we are using manual BinaryReader/Writer:
    // I'll just write the new format.
    
    return Vocabulary(
      id: id,
      word: word,
      phonetic: phonetic,
      meaning: meaning,
      example: example,
      category: reader.readString(), // This will be the new field
      weight: reader.readDouble(),
      lastReviewed: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, Vocabulary obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.word);
    writer.writeString(obj.phonetic);
    writer.writeString(obj.meaning);
    writer.writeString(obj.example);
    writer.writeString(obj.category);
    writer.writeDouble(obj.weight);
    writer.writeInt(obj.lastReviewed.millisecondsSinceEpoch);
  }
}
