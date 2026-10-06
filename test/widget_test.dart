import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_notes/app.dart';
import 'package:personal_notes/data/note_repository.dart';
import 'package:personal_notes/models/note.dart';
import 'package:personal_notes/widgets/note_card.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class TestRepository implements NoteRepository {
  List<Note> notes = [];
  bool failSave = false;
  bool failLoad = false;

  @override
  Future<List<Note>> load() async {
    if (failLoad) throw StateError('Read failed');
    return [...notes];
  }

  @override
  Future<void> save(List<Note> value) async {
    if (failSave) throw StateError('Write failed');
    notes = [...value];
  }
}

Note sampleNote() => Note(
  id: 'sample',
  title: 'Ghi chú ban đầu',
  content: 'Nội dung cần nhớ',
  createdAt: DateTime(2026, 10, 6, 9),
  updatedAt: DateTime(2026, 10, 6, 9),
);

Future<void> openNewNote(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

Future<void> enterNote(
  WidgetTester tester,
  String title,
  String content,
) async {
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('note-title')),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(find.byKey(const ValueKey('note-title')), title);
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('note-content')),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(find.byKey(const ValueKey('note-content')), content);
}

Future<void> saveNote(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Lưu ghi chú');
  await tester.scrollUntilVisible(
    button,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Thêm, sửa và mở lại ứng dụng giữ dữ liệu đã lưu', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await tester.pumpWidget(
      NotesApp(repository: SharedPreferencesNoteRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tạo ghi chú đầu tiên'), findsOneWidget);
    await openNewNote(tester);
    await enterNote(
      tester,
      '  Bài tập Flutter  ',
      '  Hoàn thành bài 5\nKiểm tra ứng dụng  ',
    );
    await saveNote(tester);
    expect(find.text('Bài tập Flutter'), findsOneWidget);
    final original = (await SharedPreferencesNoteRepository().load()).single;
    await tester.tap(find.text('Bài tập Flutter'));
    await tester.pumpAndSettle();
    await enterNote(tester, 'Bài tập đã sửa', 'Nội dung mới');
    await saveNote(tester);
    final edited = (await SharedPreferencesNoteRepository().load()).single;
    expect(edited.id, original.id);
    expect(edited.createdAt, original.createdAt);
    expect(edited.content, 'Nội dung mới');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      NotesApp(repository: SharedPreferencesNoteRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bài tập đã sửa'), findsOneWidget);
    expect(find.text('Nội dung mới'), findsOneWidget);
  });

  testWidgets('Không lưu trường trống; quay lại hỏi bỏ thay đổi', (
    tester,
  ) async {
    final repository = TestRepository();
    await tester.pumpWidget(NotesApp(repository: repository));
    await tester.pumpAndSettle();
    await openNewNote(tester);
    await saveNote(tester);
    expect(find.text('Vui lòng nhập tiêu đề.'), findsOneWidget);
    expect(find.text('Vui lòng nhập nội dung.'), findsOneWidget);
    expect(repository.notes, isEmpty);
    await enterNote(tester, 'Bản nháp', 'Chưa lưu');
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục viết'));
    await tester.pumpAndSettle();
    expect(find.text('Bản nháp'), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ thay đổi'));
    await tester.pumpAndSettle();
    expect(find.text('Ghi chú của tôi'), findsOneWidget);
    expect(repository.notes, isEmpty);
  });

  testWidgets('Giữ lâu để xóa: hủy giữ dữ liệu, xác nhận mới xóa', (
    tester,
  ) async {
    final repository = TestRepository()..notes = [sampleNote()];
    await tester.pumpWidget(NotesApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(NoteCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa ghi chú'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(repository.notes, hasLength(1));
    await tester.longPress(find.byType(NoteCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa ghi chú'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(repository.notes, isEmpty);
    expect(find.byType(NoteCard), findsNothing);
  });

  testWidgets('Vuốt xóa có xác nhận và không gây lỗi Dismissible', (
    tester,
  ) async {
    final repository = TestRepository()..notes = [sampleNote()];
    await tester.pumpWidget(NotesApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Xóa ghi chú?'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteCard), findsOneWidget);
    await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(repository.notes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lỗi lưu giữ nội dung để thử lại', (tester) async {
    final repository = TestRepository()..failSave = true;
    await tester.pumpWidget(NotesApp(repository: repository));
    await tester.pumpAndSettle();
    await openNewNote(tester);
    await enterNote(tester, 'Không được mất', 'Nội dung quan trọng');
    await saveNote(tester);
    expect(find.text('Không được mất'), findsOneWidget);
    expect(repository.notes, isEmpty);
    repository.failSave = false;
    await saveNote(tester);
    expect(repository.notes.single.title, 'Không được mất');
    expect(find.text('Ghi chú của tôi'), findsOneWidget);
  });

  testWidgets('Lỗi đọc chặn thêm ghi chú và cho phép thử lại', (tester) async {
    final repository = TestRepository()..failLoad = true;
    await tester.pumpWidget(NotesApp(repository: repository));
    await tester.pumpAndSettle();
    expect(
      find.text('Không thể đọc ghi chú. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .onPressed,
      isNull,
    );
    repository.failLoad = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo ghi chú đầu tiên'), findsOneWidget);
  });

  testWidgets('Tìm theo tiêu đề và nội dung', (tester) async {
    final repository = TestRepository()..notes = [sampleNote()];
    await tester.pumpWidget(NotesApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'CẦN NHỚ');
    await tester.pumpAndSettle();
    expect(find.byType(NoteCard), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'không khớp');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy ghi chú'), findsOneWidget);
    await tester.tap(find.text('Xóa tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteCard), findsOneWidget);
  });

  for (final size in [
    const Size(375, 812),
    const Size(812, 375),
    const Size(1024, 768),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'Giao diện ${size.width}x${size.height}, $brightness, chữ lớn',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final repository = TestRepository()..notes = [sampleNote()];
          await tester.pumpWidget(NotesApp(repository: repository));
          await tester.pumpAndSettle();
          await openNewNote(tester);
          await enterNote(tester, 'Ghi chú mới', 'Nội dung');
          await saveNote(tester);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
