import 'package:flutter/material.dart';

import 'app.dart';
import 'data/note_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(NotesApp(repository: SharedPreferencesNoteRepository()));
}
