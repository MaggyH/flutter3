import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  await Hive.openBox('notes');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NoteListScreen(),
    );
  }
}

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  late Box _notesBox;
  String _noteName = 'No noteName';

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    _notesBox = Hive.box('notes');
    _fetchNotes();
  }

  Future<void> _addNote(String title, String content) async {
    await _notesBox.add({'title': title, 'content': content});
    _fetchNotes();
  }

  Future<void> _deleteNote(int index) async {
    await _notesBox.deleteAt(index);
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _noteName =
          _notesBox.get('title', defaultValue: 'No noteName') ?? 'No noteName';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
      ),
      body: FutureBuilder(
        future: _fetchNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: _notesBox.length,
            itemBuilder: (context, index) {
              final note = _notesBox.getAt(index);
              return ListTile(
                title: Text(note['title']),
                subtitle: Text(note['content']),
                trailing: IconButton(
                    onPressed: () async {
                      bool? confirmDelete =
                          await _showDeleteConfirmationDialog(context);
                      if (confirmDelete == true) {
                        _deleteNote(index); // 삭제 메소드 호출
                      }
                    },
                    icon: const Icon(Icons.delete)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await _showAddNoteDialog(context);
          if (result != null) {
            _addNote(result['title']!, result['content']!);
          }
        },
      ),
    );
  }

  Future<Map<String, String>?> _showAddNoteDialog(BuildContext context) {
    String? title;
    String? content;
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  title = value;
                },
                decoration: const InputDecoration(hintText: 'Enter note title'),
              ),
              TextField(
                onChanged: (value) {
                  content = value;
                },
                decoration:
                    const InputDecoration(hintText: 'Enter note content'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(context)
                    .pop({'title': title!, 'content': content!});
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
