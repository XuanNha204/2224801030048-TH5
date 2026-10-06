import 'package:flutter/material.dart';

import '../data/note_repository.dart';
import '../models/note.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final NoteRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  List<Note> _notes = [];
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final notes = await widget.repository.load();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (!mounted) return;
      setState(() => _notes = notes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Không thể đọc ghi chú. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persist(List<Note> nextNotes) async {
    if (_saving) throw StateError('Đang lưu ghi chú');
    setState(() => _saving = true);
    try {
      await widget.repository.save(nextNotes);
      nextNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) setState(() => _notes = nextNotes);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openEditor([Note? note]) async {
    if (_saving || _loading || _loadError != null) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          note: note,
          onSave: (savedNote) => _persist([
            savedNote,
            ..._notes.where((item) => item.id != savedNote.id),
          ]),
        ),
      ),
    );
    if (mounted && saved == true) {
      _message(note == null ? 'Đã thêm ghi chú.' : 'Đã cập nhật ghi chú.');
    }
  }

  Future<void> _delete(Note note) async {
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ghi chú?'),
        content: Text(
          'Bạn có muốn xóa “${note.title}”? Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _saving) return;
    try {
      await _persist(_notes.where((item) => item.id != note.id).toList());
      if (mounted) _message('Đã xóa ghi chú.');
    } catch (_) {
      if (mounted) _message('Không thể xóa ghi chú. Vui lòng thử lại.');
    }
  }

  Future<void> _showActions(Note note) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Chỉnh sửa ghi chú'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Xóa ghi chú'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') await _openEditor(note);
    if (action == 'delete') await _delete(note);
  }

  Widget _emptyState({required bool searching}) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            searching ? Icons.search_off_rounded : Icons.edit_note_rounded,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            searching
                ? 'Không tìm thấy ghi chú'
                : 'Một ý tưởng mới bắt đầu ở đây',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            searching
                ? 'Thử tìm bằng tiêu đề hoặc nội dung khác.'
                : 'Ghi lại ý tưởng, công việc và những điều bạn muốn nhớ.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (searching)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              child: const Text('Xóa tìm kiếm'),
            )
          else
            FilledButton.icon(
              onPressed: _saving ? null : () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Tạo ghi chú đầu tiên'),
            ),
        ],
      ),
    ),
  );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    final query = _query.trim().toLowerCase();
    final visible = _notes
        .where(
          (note) =>
              note.title.toLowerCase().contains(query) ||
              note.content.toLowerCase().contains(query),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm ghi chú...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              query.isEmpty
                  ? '${_notes.length} ghi chú · Mới cập nhật'
                  : '${visible.length} kết quả',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_saving) const LinearProgressIndicator(),
        Expanded(
          child: visible.isEmpty
              ? _emptyState(searching: query.isNotEmpty)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 104),
                  itemCount: visible.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final note = visible[index];
                    return Dismissible(
                      key: ValueKey(note.id),
                      direction: _saving
                          ? DismissDirection.none
                          : DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        await _delete(note);
                        // Xóa khỏi danh sách sau khi ghi xuống bộ nhớ thành công.
                        return false;
                      },
                      child: NoteCard(
                        note: note,
                        enabled: !_saving,
                        onEdit: () => _openEditor(note),
                        onDelete: () => _delete(note),
                        onLongPress: () => _showActions(note),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ghi chú của tôi'),
      leading: Icon(
        Icons.notes_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _body(),
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _loading || _saving || _loadError != null
          ? null
          : () => _openEditor(),
      tooltip: 'Thêm ghi chú',
      icon: const Icon(Icons.add),
      label: const Text('Thêm ghi chú'),
    ),
  );
}
