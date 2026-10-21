import 'package:flutter/material.dart';
import 'board_common.dart';

// 상담 및 질문: 학생·학부모는 학원 선생님에게 질문하고 답변 확인, 선생님은 들어온 질문에 답변
class QnaScreen extends StatefulWidget {
  const QnaScreen({super.key});

  @override
  State<QnaScreen> createState() => _QnaScreenState();
}

class _QnaScreenState extends State<QnaScreen> {
  List<dynamic> questions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await apiGet('/questions?user_id=${currentUser(context)['id']}');
      setState(() {
        questions = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      showMessage(context, '질문을 불러오지 못했어요: $e');
    }
  }

  Future<void> ask() async {
    final userId = currentUser(context)['id'];
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BoardWriteScreen(
          title: '선생님께 질문하기',
          onSubmit: (title, content) =>
              apiSend('POST', '/questions', {'user_id': userId, 'title': title, 'content': content}),
        ),
      ),
    );
    if (saved == true) load();
  }

  Future<void> open(Map<String, dynamic> question) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => QnaDetailScreen(question: question)),
    );
    if (changed == true) load();
  }

  @override
  Widget build(BuildContext context) {
    final teacher = isTeacher(context);
    return Scaffold(
      appBar: AppBar(title: const Text('상담 및 질문'), backgroundColor: Colors.teal),
      floatingActionButton: teacher
          ? null
          : FloatingActionButton.extended(
              onPressed: ask,
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.help_outline),
              label: const Text('질문하기'),
            ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: questions.isEmpty
                  ? EmptyBoard(
                      icon: Icons.forum_outlined,
                      message: teacher ? '아직 들어온 질문이 없어요.' : '궁금한 점을 학원 선생님께 물어보세요.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: questions.length,
                      itemBuilder: (context, i) {
                        final q = questions[i];
                        final answered = q['answer'] != null;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () => open(q),
                            title: Text(q['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              teacher
                                  ? '${q['asker']} (${q['asker_role']}) · ${(q['created_at'] ?? '').toString().substring(0, 10)}'
                                  : '${q['academy_name']} · ${(q['created_at'] ?? '').toString().substring(0, 10)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: AnswerStatusChip(answered: answered),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class AnswerStatusChip extends StatelessWidget {
  final bool answered;

  const AnswerStatusChip({super.key, required this.answered});

  @override
  Widget build(BuildContext context) {
    final color = answered ? Colors.teal : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(answered ? '답변완료' : '답변대기',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class QnaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> question;

  const QnaDetailScreen({super.key, required this.question});

  @override
  State<QnaDetailScreen> createState() => _QnaDetailScreenState();
}

class _QnaDetailScreenState extends State<QnaDetailScreen> {
  final answerController = TextEditingController();
  bool submitting = false;

  Future<void> submitAnswer() async {
    final answer = answerController.text.trim();
    if (answer.isEmpty) return;
    setState(() => submitting = true);
    final error = await apiSend('POST', '/questions/${widget.question['id']}/answer',
        {'teacher_id': currentUser(context)['id'], 'answer': answer});
    if (!mounted) return;
    setState(() => submitting = false);
    if (error != null) return showMessage(context, error);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final answered = q['answer'] != null;
    final canAnswer = isTeacher(context) && !answered;

    return Scaffold(
      appBar: AppBar(title: const Text('질문 상세'), backgroundColor: Colors.teal),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: Text(q['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              AnswerStatusChip(answered: answered),
            ],
          ),
          const SizedBox(height: 6),
          Text('${q['asker']} (${q['asker_role']}) · ${q['academy_name']} · ${(q['created_at'] ?? '').toString().substring(0, 10)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(q['content'] ?? '', style: const TextStyle(height: 1.5)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('답변', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (answered)
            Card(
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q['answer'], style: const TextStyle(height: 1.5)),
                    const SizedBox(height: 8),
                    Text('${q['answerer'] ?? '선생님'} · ${(q['answered_at'] ?? '').toString().substring(0, 10)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ],
                ),
              ),
            )
          else if (canAnswer) ...[
            TextField(
              controller: answerController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: '답변을 입력하세요.', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: submitting ? null : submitAnswer,
              child: const Text('답변 등록'),
            ),
          ] else
            Text('선생님이 확인 후 답변해 드릴 거예요.', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
