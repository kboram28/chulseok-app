import 'dart:convert';
import 'package:apiintegration/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../UserProvider.dart';

// 공지사항 · 질의응답 · 과제/시험 화면에서 같이 쓰는 도우미

Map<String, dynamic> currentUser(BuildContext context) =>
    Provider.of<UserProvider>(context, listen: false).userData;

bool isTeacher(BuildContext context) => currentUser(context)['role'] == '선생님';

Future<dynamic> apiGet(String path) async {
  final response = await http.get(Uri.parse('$apiBaseUrl$path'));
  final body = json.decode(utf8.decode(response.bodyBytes));
  if (response.statusCode != 200) throw Exception(body['message'] ?? '요청 실패');
  return body;
}

// 성공하면 null, 실패하면 서버가 준 오류 메시지
Future<String?> apiSend(String method, String path, [Map<String, dynamic>? body]) async {
  final request = http.Request(method, Uri.parse('$apiBaseUrl$path'))
    ..headers['Content-Type'] = 'application/json; charset=UTF-8';
  if (body != null) request.body = json.encode(body);
  final response = await http.Response.fromStream(await request.send());
  if (response.statusCode >= 200 && response.statusCode < 300) return null;
  try {
    return json.decode(utf8.decode(response.bodyBytes))['message'] ?? '요청 실패';
  } catch (_) {
    return '요청 실패 (${response.statusCode})';
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String dDay(int daysLeft) => daysLeft == 0 ? 'D-DAY' : 'D-$daysLeft';

const Map<String, Color> scheduleColors = {'과제': Colors.blue, '시험': Colors.red};

// 제목 + 내용(+ 선택 항목)을 받는 작성 화면. 저장하면 true 를 돌려주며 닫힘
class BoardWriteScreen extends StatefulWidget {
  final String title;
  final String submitLabel;
  final Future<String?> Function(String title, String content) onSubmit;

  const BoardWriteScreen({super.key, required this.title, required this.onSubmit, this.submitLabel = '등록'});

  @override
  State<BoardWriteScreen> createState() => _BoardWriteScreenState();
}

class _BoardWriteScreenState extends State<BoardWriteScreen> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  bool submitting = false;

  Future<void> submit() async {
    if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
      showMessage(context, '제목과 내용을 입력해주세요.');
      return;
    }
    setState(() => submitting = true);
    final error = await widget.onSubmit(titleController.text.trim(), contentController.text.trim());
    if (!mounted) return;
    setState(() => submitting = false);
    if (error != null) {
      showMessage(context, error);
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.teal),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: '제목', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: contentController,
            maxLines: 8,
            decoration: const InputDecoration(labelText: '내용', border: OutlineInputBorder(), alignLabelWithHint: true),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: submitting ? null : submit,
            child: Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}

// 비어 있을 때 보여주는 안내
class EmptyBoard extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyBoard({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}
