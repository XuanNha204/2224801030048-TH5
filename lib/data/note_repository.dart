import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

abstract interface class NoteRepository {
  Future<List<Note>> load();
  Future<void> save(List<Note> notes);
}

class SharedPreferencesNoteRepository implements NoteRepository {
  SharedPreferencesNoteRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'personal_notes_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<Note>> load() async {
    final raw = await _preferences.getString(storageKey);
    if (raw == null) return [];
    // Không ghi đè dữ liệu nếu JSON bị lỗi. Màn hình chính cho phép thử lại.
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Note.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> save(List<Note> notes) => _preferences.setString(
    storageKey,
    jsonEncode(notes.map((note) => note.toJson()).toList()),
  );
}
