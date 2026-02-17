import 'package:flutter/material.dart';

import '../models/note_item.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<NoteItem> _notes = <NoteItem>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await StorageService.loadNotes();
    setState(() => _notes = notes);
  }

  Future<void> _persist() async {
    await StorageService.saveNotes(_notes);
  }

  Future<void> _openEditor({NoteItem? note}) async {
    final titleController = TextEditingController(text: note?.title ?? '');
    final bodyController = TextEditingController(text: note?.content ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note == null ? 'New note' : 'Edit note'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyController,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Content'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) return;

    setState(() {
      if (note == null) {
        _notes = [
          NoteItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title.isEmpty ? 'Untitled' : title,
            content: body,
            updatedAt: DateTime.now(),
          ),
          ..._notes,
        ];
      } else {
        _notes = _notes
            .map(
              (n) => n.id == note.id
                  ? n.copyWith(
                      title: title.isEmpty ? 'Untitled' : title,
                      content: body,
                      updatedAt: DateTime.now(),
                    )
                  : n,
            )
            .toList();
      }
    });

    LoggerService.info(note == null ? 'Note added' : 'Note updated');
    _persist();
  }

  void _delete(NoteItem note) {
    setState(() => _notes.removeWhere((n) => n.id == note.id));
    LoggerService.warning('Note removed');
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _notes.isEmpty
          ? const Center(child: Text('No notes yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  child: ListTile(
                    title: Text(note.title),
                    subtitle: Text(
                      note.content.isEmpty ? '(empty)' : note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(note),
                    ),
                    onTap: () => _openEditor(note: note),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
