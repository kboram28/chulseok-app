import 'package:flutter/material.dart';
import 'board_common.dart';

// 공지사항: 학생·학부모는 다니는 학원 공지 보기, 선생님은 소속 학원 공지 작성·삭제
class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  List<dynamic> notices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await apiGet('/notices?user_id=${currentUser(context)['id']}');
      setState(() {
        notices = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      showMessage(context, '공지를 불러오지 못했어요: $e');
    }
  }

  Future<void> write() async {
    final teacherId = currentUser(context)['id'];
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BoardWriteScreen(
          title: '공지 작성',
          onSubmit: (title, content) =>
              apiSend('POST', '/notices', {'teacher_id': teacherId, 'title': title, 'content': content}),
        ),
      ),
    );
    if (saved == true) load();
  }

  Future<void> delete(Map<String, dynamic> notice) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공지 삭제'),
        content: Text('"${notice['title']}" 공지를 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    final error = await apiSend('DELETE', '/notices/${notice['id']}?teacher_id=${currentUser(context)['id']}');
    if (error != null) return showMessage(context, error);
    load();
  }

  @override
  Widget build(BuildContext context) {
    final teacher = isTeacher(context);
    return Scaffold(
      appBar: AppBar(title: const Text('공지사항'), backgroundColor: Colors.teal),
      floatingActionButton: teacher
          ? FloatingActionButton.extended(
              onPressed: write,
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit),
              label: const Text('공지 작성'),
            )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: notices.isEmpty
                  ? EmptyBoard(
                      icon: Icons.campaign,
                      message: teacher ? '아직 작성한 공지가 없어요.' : '학원에서 올린 공지가 아직 없어요.\n학원을 등록하면 공지를 받아볼 수 있어요.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: notices.length,
                      itemBuilder: (context, i) {
                        final n = notices[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            initiallyExpanded: i == 0,
                            leading: const Icon(Icons.campaign, color: Colors.teal),
                            title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '${n['academy_name']} · ${n['author']} · ${(n['created_at'] ?? '').toString().substring(0, 10)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            expandedCrossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['content'] ?? '', style: const TextStyle(height: 1.5)),
                              if (teacher)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => delete(n),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    label: const Text('삭제', style: TextStyle(color: Colors.red)),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
