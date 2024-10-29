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
  List<dynamic> _list = [];
  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    // Hive에서 Box를 가져온 후 Box에서 fetch
    _notesBox = Hive.box('notes');
    _fetchNotes();
  }

  Future<void> _addNote(String title, String content) async {
    // Box에 노트를 추가한 후 Box에서 fetch
    await _notesBox.add({'title': title, 'content': content});
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    // notesBox에서 값을 가져와 _list에 할당하고 setState()로 상태 변화를 알림
    setState(() {
      _list = _notesBox.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
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
              final note = _list[index];
              return ListTile(
                title: Text(note['title']),
                subtitle: Text(note['content']),
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
}
