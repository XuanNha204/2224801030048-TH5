import 'package:flutter_test/flutter_test.dart';
import 'package:personal_notes/data/note_repository.dart';
import 'package:personal_notes/models/note.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('Lưu và đọc lại tiếng Việt, nhiều dòng, ID và thời gian', () async {
    final note = Note(
      id: 'note-1',
      title: 'Kế hoạch học tập',
      content: 'Học Flutter\nÔn bài "ghi chú" ✨',
      createdAt: DateTime(2026, 10, 6, 9, 30),
      updatedAt: DateTime(2026, 10, 6, 10, 45),
    );
    final repository = SharedPreferencesNoteRepository();
    expect(await repository.load(), isEmpty);
    await repository.save([note]);
    final reloaded = await SharedPreferencesNoteRepository().load();
    expect(reloaded.single.toJson(), note.toJson());
    await repository.save([]);
    expect(await SharedPreferencesNoteRepository().load(), isEmpty);
  });

  test(
    'Dữ liệu lỗi được giữ nguyên, không bị coi là danh sách trống',
    () async {
      await SharedPreferencesAsync().setString(
        SharedPreferencesNoteRepository.storageKey,
        'invalid json',
      );
      await expectLater(
        SharedPreferencesNoteRepository().load(),
        throwsFormatException,
      );
      expect(
        await SharedPreferencesAsync().getString(
          SharedPreferencesNoteRepository.storageKey,
        ),
        'invalid json',
      );
    },
  );
}
