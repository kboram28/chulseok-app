import 'package:apiintegration/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../UserProvider.dart';

class FreeBoardWriteScreen extends StatelessWidget {
  const FreeBoardWriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

    // 글 등록 API 호출
    Future<void> submitPost(String title, String content, int userId) async {
      const apiUrl = "$apiBaseUrl/freeboardwrite";

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            "Content-Type": "application/json; charset=UTF-8", // 여기 추가
          },
          body: json.encode({
            "title": title,
            "user_id": userId, // Flutter에서 user_id만 전달
            "content": content,
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('글이 성공적으로 등록되었습니다.')),
          );
          Navigator.pop(context); // 이전 화면으로 돌아가기
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('글 등록 실패: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네트워크 오류: $e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('글 작성',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '제목',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: '제목을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '내용',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: contentController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: '내용을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final String title = titleController.text;
                  final String content = contentController.text;

                  // Provider에서 user_id 가져오기
                  final userData = Provider.of<UserProvider>(context, listen: false).userData;
                  final userId = userData['id'];

                  if (title.isNotEmpty && content.isNotEmpty && userId != null) {
                    // API 호출
                    submitPost(title, content, userId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('모든 필드를 입력하고 사용자 정보를 확인해주세요.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('등록', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
