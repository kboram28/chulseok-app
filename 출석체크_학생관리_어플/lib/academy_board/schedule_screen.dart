import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'board_common.dart';

// 과제·시험 일정: 학생·학부모는 다가오는 일정 확인, 선생님은 등록·삭제
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<dynamic> schedules = [];
  bool isLoading = true;
  String filter = '전체';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await apiGet('/schedules?user_id=${currentUser(context)['id']}');
      setState(() {
        schedules = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      showMessage(context, '일정을 불러오지 못했어요: $e');
    }
  }

  Future<void> add() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ScheduleWriteScreen()),
    );
    if (saved == true) load();
  }

  Future<void> delete(Map<String, dynamic> s) async {
    final error = await apiSend('DELETE', '/schedules/${s['id']}?teacher_id=${currentUser(context)['id']}');
    if (error != null) return showMessage(context, error);
    showMessage(context, '"${s['title']}" 일정을 삭제했어요.');
    load();
  }

  @override
  Widget build(BuildContext context) {
    final teacher = isTeacher(context);
    final shown = filter == '전체' ? schedules : schedules.where((s) => s['type'] == filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('과제·시험 일정'), backgroundColor: Colors.teal),
      floatingActionButton: teacher
          ? FloatingActionButton.extended(
              onPressed: add,
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('일정 등록'),
            )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      for (final f in ['전체', '과제', '시험'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: filter == f,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: load,
                    child: shown.isEmpty
                        ? EmptyBoard(
                            icon: Icons.event_available,
                            message: teacher ? '등록한 과제·시험 일정이 없어요.' : '다가오는 과제·시험 일정이 없어요.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                            itemCount: shown.length,
                            itemBuilder: (context, i) => ScheduleCard(
                              schedule: shown[i],
                              onDelete: teacher ? () => delete(shown[i]) : null,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final VoidCallback? onDelete;

  const ScheduleCard({super.key, required this.schedule, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final s = schedule;
    final color = scheduleColors[s['type']] ?? Colors.grey;
    final date = DateTime.parse(s['due_date']);
    final daysLeft = (s['days_left'] as num).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Text(s['type'], style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(dDay(daysLeft),
                      style: TextStyle(color: color, fontSize: 12, fontWeight: daysLeft <= 3 ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if ((s['description'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(s['description'], style: TextStyle(color: Colors.grey[700])),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('M월 d일').format(date)} (${'월화수목금토일'[date.weekday - 1]}) · ${s['academy_name']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(icon: const Icon(Icons.delete_outline), color: Colors.grey, onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class ScheduleWriteScreen extends StatefulWidget {
  const ScheduleWriteScreen({super.key});

  @override
  State<ScheduleWriteScreen> createState() => _ScheduleWriteScreenState();
}

class _ScheduleWriteScreenState extends State<ScheduleWriteScreen> {
  String type = '과제';
  DateTime dueDate = DateTime.now().add(const Duration(days: 7));
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  bool submitting = false;

  Future<void> submit() async {
    if (titleController.text.trim().isEmpty) return showMessage(context, '제목을 입력해주세요.');
    setState(() => submitting = true);
    final error = await apiSend('POST', '/schedules', {
      'teacher_id': currentUser(context)['id'],
      'type': type,
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
    });
    if (!mounted) return;
    setState(() => submitting = false);
    if (error != null) return showMessage(context, error);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일정 등록'), backgroundColor: Colors.teal),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '과제', label: Text('과제'), icon: Icon(Icons.assignment)),
              ButtonSegment(value: '시험', label: Text('시험'), icon: Icon(Icons.quiz)),
            ],
            selected: {type},
            onSelectionChanged: (v) => setState(() => type = v.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: type == '과제' ? '과제 내용 (예: 익힘책 42~45쪽)' : '시험 이름 (예: 중간 단원평가)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: type == '과제' ? '메모 (선택)' : '시험 범위 (선택)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            leading: const Icon(Icons.event),
            title: Text(type == '과제' ? '제출일' : '시험일'),
            trailing: Text(DateFormat('yyyy년 M월 d일').format(dueDate), style: const TextStyle(fontSize: 16)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dueDate,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => dueDate = picked);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: submitting ? null : submit,
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }
}
