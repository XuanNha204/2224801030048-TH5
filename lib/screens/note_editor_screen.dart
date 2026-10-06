import 'package:flutter/material.dart';

import '../models/note.dart';
import '../widgets/note_card.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.note, required this.onSave});

  final Note? note;
  final Future<void> Function(Note note) onSave;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final String _id;
  late final DateTime _createdAt;
  bool _saving = false;
  bool _allowPop = false;
  bool _showingDiscardDialog = false;
  String? _saveError;

  bool get _dirty =>
      _title.text != (widget.note?.title ?? '') ||
      _content.text != (widget.note?.content ?? '');

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title ?? '');
    _content = TextEditingController(text: widget.note?.content ?? '');
    _createdAt = widget.note?.createdAt ?? DateTime.now();
    _id = widget.note?.id ?? _createdAt.microsecondsSinceEpoch.toString();
    _title.addListener(_changed);
    _content.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_saving || _showingDiscardDialog) return;
    if (_dirty) {
      _showingDiscardDialog = true;
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bỏ thay đổi chưa lưu?'),
          content: const Text(
            'Nội dung vừa nhập chưa được lưu. Bạn có muốn thoát?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tiếp tục viết'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Bỏ thay đổi'),
            ),
          ],
        ),
      );
      _showingDiscardDialog = false;
      if (discard != true) return;
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    // PopScope cần được rebuild trước khi pop route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, false);
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final note = Note(
      id: _id,
      title: _title.text.trim(),
      content: _content.text.trim(),
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
    );
    try {
      await widget.onSave(note);
      if (!mounted) return;
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError =
            'Không thể lưu ghi chú. Nội dung vẫn được giữ để bạn thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    canPop: _allowPop || (!_dirty && !_saving),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: _saving ? null : _leave,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.note == null ? 'Thêm ghi chú' : 'Chỉnh sửa ghi chú'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    widget.note == null
                        ? 'Bạn muốn ghi nhớ điều gì?'
                        : 'Tiếp tục ý tưởng của bạn',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.note == null
                        ? 'Đặt một tiêu đề và viết theo cách của bạn.'
                        : 'Tạo lúc ${formatNoteDate(widget.note!.createdAt)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const ValueKey('note-title'),
                    controller: _title,
                    readOnly: _saving,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề',
                      hintText: 'Ví dụ: Ý tưởng cho hôm nay',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập tiêu đề.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const ValueKey('note-content'),
                    controller: _content,
                    readOnly: _saving,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 8,
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung',
                      hintText: 'Viết ghi chú của bạn ở đây...',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập nội dung.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  if (_saveError != null) ...[
                    Text(
                      _saveError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(18),
                    ),
                    icon: _saving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_saving ? 'Đang lưu...' : 'Lưu ghi chú'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
