import 'package:apiintegration/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../UserProvider.dart';

class FreeBoardDetailScreen extends StatefulWidget {
  final int postId;

  const FreeBoardDetailScreen({super.key, required this.postId});

  @override
  State<FreeBoardDetailScreen> createState() => _FreeBoardDetailScreenState();
}

class _FreeBoardDetailScreenState extends State<FreeBoardDetailScreen> {
  Map<String, dynamic>? post; // 게시글 데이터
  List<dynamic> comments = []; // 댓글 데이터
  bool isLoading = true; // 로딩 상태
  final TextEditingController commentController = TextEditingController();
  bool isSubmitting = false;

  // 댓글 작성
  Future<void> submitComment() async {
    final content = commentController.text.trim();
    final userId = Provider.of<UserProvider>(context, listen: false).userData['id'];
    if (content.isEmpty || userId == null) return;

    setState(() => isSubmitting = true);
    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/freeboardcomment"),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: json.encode({"post_id": widget.postId, "user_id": userId, "content": content}),
      );
      if (response.statusCode == 201) {
        final comment = json.decode(utf8.decode(response.bodyBytes))['comment'];
        setState(() => comments = [...comments, comment]);
        commentController.clear();
        FocusScope.of(context).unfocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 등록 실패: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  // 서버에서 데이터 가져오기
  Future<void> fetchData() async {
    final apiUrl = "$apiBaseUrl/freeboardA?postId=${widget.postId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data); // 응답 데이터 디버깅
        setState(() {
          post = data['post'];
          comments = data['comments'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching post: $e'); // 오류 디버깅
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터를 불러오는데 실패했습니다: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData(); // 초기화 시 데이터 가져오기
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (post == null) {
      return Scaffold(
        body: Center(
          child: Text('게시글을 찾을 수 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '게시글 상세보기',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 글 제목 및 정보
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post!['title'],
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '작성자: ${post!['author_name']}',
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      Text(
                        '날짜: ${post!['created_at'].substring(0, 10)}',
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '조회수: ${post!['views']}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 글 내용
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    post!['content'],
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 댓글 영역
            const Text(
              '댓글',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: comments.isEmpty
                  ? const Center(child: Text('댓글이 없습니다.'))
                  : ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment['content'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '작성자: ${comment['author']}',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            Text(
                              comment['created_at'].substring(0, 10),
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 댓글 입력
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      onSubmitted: (_) => submitComment(),
                      decoration: InputDecoration(
                        hintText: '댓글을 입력하세요.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : submitComment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    child: const Text('작성'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
