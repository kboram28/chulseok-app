import 'package:apiintegration/api_config.dart';
import 'dart:convert';
import 'package:apiintegration/community/freeboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'freeboard_detail_screen.dart';
import 'package:provider/provider.dart';
import '../UserProvider.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<dynamic> freeBoardPosts = []; // 자유게시판 게시글 목록
  bool isLoading = true; // 로딩 상태

  @override
  void initState() {
    super.initState();
    fetchFreeBoardPosts(); // 자유게시판 데이터 로드
  }

  // 자유게시판 데이터 가져오기
  Future<void> fetchFreeBoardPosts() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userData['id'];
    final apiUrl = "$apiBaseUrl/freeboard?user_id=$userId";

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)); // UTF-8로 디코딩
        setState(() {
          freeBoardPosts = data['posts'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load free board posts');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('자유게시판 데이터를 불러오는데 실패했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '커뮤니티',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // 알림 기능 추가
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 프로필 섹션
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildProfileButton('프로필 1', context),
                  _buildProfileButton('프로필 2', context),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.teal, size: 40),
                    onPressed: () {
                      _showAddProfileDialog(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 자유게시판 섹션
              _buildFreeBoardSection(context),

              const SizedBox(height: 20),

              // 상담 및 질문 / 공지사항
              Row(
                children: [
                  Expanded(
                    child: _buildBoardSection(
                      context,
                      title: '상담 및 질문',
                      columnHeaders: ['번호', '제목', '이름', '답변'],
                      rowCount: 5,
                      // 데이터 추가 시 여기에 데이터 및 로직 추가
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBoardSection(
                      context,
                      title: '공지사항',
                      columnHeaders: ['번호', '제목', '이름', '날짜'],
                      rowCount: 5,
                      // 데이터 추가 시 여기에 데이터 및 로직 추가
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: '학원'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
        ],
      ),
    );
  }

  Widget _buildProfileButton(String label, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 프로필 상세보기 동작
      },
      child: Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.teal,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFreeBoardSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // 섹션 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '자유게시판',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FreeBoardScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    '더보기',
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
              ],
            ),
            const Divider(thickness: 1),
            // 테이블 헤더
            Row(
              children: const [
                Expanded(
                  flex: 1,
                  child: Text('번호', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('제목', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('작성자', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('날짜', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(thickness: 1),
            // 게시글 목록
            Column(
              children: freeBoardPosts.take(5).map((post) {
                return GestureDetector(
                  onTap: () {
                    // 게시글 상세보기로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FreeBoardDetailScreen(postId: post['id']),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${post['id']}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            post['title'] ?? '제목 없음',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            post['author_name'] ?? '알 수 없음',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            post['created_at']?.substring(0, 10) ?? '날짜 없음',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardSection(
      BuildContext context, {
        required String title,
        required List<String> columnHeaders,
        required int rowCount,
        // 필요한 경우 데이터를 인자로 추가
      }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // 섹션 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // 더보기 동작
                  },
                  child: const Text(
                    '더보기',
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
              ],
            ),
            const Divider(thickness: 1),
            // 테이블 헤더
            Row(
              children: columnHeaders
                  .map(
                    (header) => Expanded(
                  child: Text(
                    header,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
                  .toList(),
            ),
            const Divider(thickness: 1),
            // 데이터 행들 (현재는 빈 데이터로 표시)
            Column(
              children: List.generate(
                rowCount,
                    (index) => Row(
                  children: columnHeaders
                      .map(
                        (header) => Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: const Text(''), // 실제 데이터로 교체 필요
                      ),
                    ),
                  )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('프로필 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('자녀 프로필 추가'),
                onTap: () {
                  // 자녀 프로필 추가 동작
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('학원 프로필 추가'),
                onTap: () {
                  // 학원 프로필 추가 동작
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }
}
