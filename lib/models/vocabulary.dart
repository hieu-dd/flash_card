import 'package:hive/hive.dart';

class Vocabulary extends HiveObject {
  String id;
  String word;
  String phonetic;
  String meaning;
  String example;
  double weight;
  DateTime lastReviewed;

  Vocabulary({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.meaning,
    required this.example,
    this.weight = 50.0,
    required this.lastReviewed,
  });
}

class VocabularyAdapter extends TypeAdapter<Vocabulary> {
  @override
  final int typeId = 0;

  @override
  Vocabulary read(BinaryReader reader) {
    return Vocabulary(
      id: reader.readString(),
      word: reader.readString(),
      phonetic: reader.readString(),
      meaning: reader.readString(),
      example: reader.readString(),
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
    writer.writeDouble(obj.weight);
    writer.writeInt(obj.lastReviewed.millisecondsSinceEpoch);
  }
}
