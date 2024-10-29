import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

// 앱의 진입점
void main() async {
  // Flutter가 비동기 코드 실행을 위해 필요한 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // 앱의 문서 디렉토리 경로를 가져옵니다. 이 경로는 Hive 데이터베이스 파일이 저장될 위치입니다.
  final appDocumentDir = await getApplicationDocumentsDirectory();
  
  // Hive 초기화 및 문서 디렉토리 경로 설정
  Hive.init(appDocumentDir.path);
  
  // 'notes'라는 이름의 Hive 박스를 엽니다. 이 박스가 로컬 저장소 역할을 합니다.
  await Hive.openBox('notes');
  
  // Flutter 애플리케이션 시작
  runApp(const MyApp());
}

// 애플리케이션의 메인 위젯
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 애플리케이션의 홈 화면을 NoteListScreen으로 설정
    return const MaterialApp(
      home: NoteListScreen(),
    );
  }
}

// 노트 목록 화면 위젯
class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  // Hive Box를 저장할 변수 선언
  late Box _notesBox;
 
  
  // 노트를 저장할 빈 리스트 초기화
  List<dynamic> _list = [];
 
  @override
  void initState() {
    super.initState();
    // Hive를 초기화하고 노트 데이터를 불러오는 함수 호출
    _initializeHive();
  }

  // Hive 초기화 및 노트 데이터 불러오기
  Future<void> _initializeHive() async {
    // 'notes'라는 이름의 Hive 박스를 가져옵니다.
    _notesBox = Hive.box('notes');

    setState(() {});
    
    // 현재 Hive 박스에 저장된 데이터를 _list에 할당하여 화면에 표시
    _fetchNotes();
  }

  // 새로운 노트를 추가하는 함수
  Future<void> _addNote(String title, String content) async {
    // title과 content가 포함된 노트를 Hive 박스에 추가
    await _notesBox.add({'title': title, 'content': content});
    
    // 노트 추가 후 목록을 다시 불러와 화면을 갱신
    _fetchNotes();
  }

  // Hive 박스에서 데이터를 가져와 _list에 할당하는 함수
  Future<void> _fetchNotes() async {

    setState(() {});
    setState(() {
      // Hive 박스에 저장된 모든 데이터를 리스트로 변환하여 _list에 저장
      _list = _notesBox.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 앱바에 'Notes' 제목 표시
        title: const Text('Notes'),
      ),
      // FutureBuilder를 사용해 비동기 방식으로 노트 데이터를 화면에 표시
      body: FutureBuilder(
        // _fetchNotes() 함수를 Future로 전달하여 데이터가 준비되기를 기다림
        future: _fetchNotes(),
        builder: (context, snapshot) {
          // 데이터가 준비되지 않았다면 로딩 인디케이터 표시
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 데이터가 준비되면 ListView를 통해 노트 목록 표시
          return ListView.builder(
            // 노트의 개수를 itemCount에 설정하여 리스트 길이 지정
            itemCount: _notesBox.length,
            itemBuilder: (context, index) {
  
              final note = _notesBox.getAt(index);
              // _list에서 index에 해당하는 노트를 가져옵니다.
              final note = _list[index];
              return ListTile(
                // 노트 제목 표시
                title: Text(note['title']),
                // 노트 내용 표시
                subtitle: Text(note['content']),
              );
            },
          );
        },
      ),
      // 노트를 추가할 수 있는 FloatingActionButton 추가
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        // 버튼을 클릭하면 노트를 추가할 수 있는 다이얼로그 표시
        onPressed: () async {
          // 다이얼로그에서 입력된 데이터를 받아옵니다.
          final result = await _showAddNoteDialog(context);
          // 입력된 데이터가 있으면 _addNote 함수로 노트를 추가
          if (result != null) {
            _addNote(result['title']!, result['content']!);
          }
        },
      ),
    );
  }

  // 노트를 추가하기 위해 사용자에게 제목과 내용을 입력받는 다이얼로그 표시
  Future<Map<String, String>?> _showAddNoteDialog(BuildContext context) {
    String? title;
    String? content;
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          // 다이얼로그 제목 설정
          title: const Text('Add Note'),
          // 다이얼로그 내용 - 텍스트 필드 2개로 구성
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 제목 입력 필드
              TextField(
                onChanged: (value) {
                  title = value;
                },
                decoration: const InputDecoration(hintText: 'Enter note title'),
              ),
              // 내용 입력 필드
              TextField(
                onChanged: (value) {
                  content = value;
                },
                decoration: const InputDecoration(hintText: 'Enter note content'),
              ),
            ],
          ),
          // 다이얼로그의 액션 버튼들 (취소 및 추가)
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              // 취소 버튼 클릭 시 다이얼로그 닫기
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              // 추가 버튼 클릭 시 제목과 내용을 담은 맵을 반환하고 다이얼로그 닫기
              onPressed: () {
                Navigator.of(context).pop({'title': title!, 'content': content!});
              },
            ),
          ],
        );
      },
    );
  }
}
