import 'dart:convert';
import 'package:apiintegration/api_config.dart';
import 'package:apiintegration/academy_search/academy_search.dart';
import 'package:apiintegration/attendance.dart';
import 'package:apiintegration/community/profile_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../UserProvider.dart';
import 'my_info.dart';

// 선생님 홈: 소속 학원 수강생 출결 체크
class TeacherHomeScreen extends StatefulWidget {
  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [TeacherMainHome(), AcademyListScreen(), MyInfoScreen()];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: '출결'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: '학원'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
        ],
      ),
    );
  }
}

class TeacherMainHome extends StatefulWidget {
  @override
  State<TeacherMainHome> createState() => _TeacherMainHomeState();
}

class _TeacherMainHomeState extends State<TeacherMainHome> {
  Map<String, dynamic>? academy;
  List<dynamic> students = [];
  bool isLoading = true;

  dynamic get teacherId => Provider.of<UserProvider>(context, listen: false).userData['id'];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // 소속 학원과 오늘 수강생 출결 불러오기
  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      final academyRes = await http.get(Uri.parse('$apiBaseUrl/teacher/academy?teacher_id=$teacherId'));
      if (academyRes.statusCode != 200) {
        setState(() {
          academy = null;
          students = [];
          isLoading = false;
        });
        return;
      }
      final studentsRes = await http.get(Uri.parse('$apiBaseUrl/teacher/students?teacher_id=$teacherId'));
      setState(() {
        academy = json.decode(utf8.decode(academyRes.bodyBytes));
        students = json.decode(utf8.decode(studentsRes.bodyBytes))['students'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('불러오기 실패: $e')));
    }
  }

  // 같은 상태를 다시 누르면 체크 취소
  Future<void> setStatus(Map<String, dynamic> student, String status) async {
    final newStatus = student['status'] == status ? '' : status;
    final previous = student['status'];
    setState(() => student['status'] = newStatus.isEmpty ? null : newStatus);

    final response = await http.post(
      Uri.parse('$apiBaseUrl/attendance'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"teacher_id": teacherId, "student_id": student['id'], "status": newStatus}),
    );
    if (response.statusCode != 200) {
      setState(() => student['status'] = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('출결 저장 실패: ${json.decode(utf8.decode(response.bodyBytes))['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('출석'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.forum),
            tooltip: '커뮤니티',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CommunityScreen()),
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: academy == null ? _noAcademy() : _attendanceList(),
            ),
    );
  }

  Widget _noAcademy() {
    return ListView(
      padding: EdgeInsets.all(24),
      children: [
        SizedBox(height: 40),
        Icon(Icons.school, size: 64, color: Colors.teal),
        SizedBox(height: 16),
        Text('소속 학원을 등록해주세요', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('학원 상세 화면에서 [등록]을 누르면 그 학원의 선생님으로 등록돼요.', textAlign: TextAlign.center),
        SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => AcademyListScreen()));
            loadData();
          },
          child: Text('학원 찾기'),
        ),
      ],
    );
  }

  Widget _attendanceList() {
    final now = DateTime.now();
    final today = '${DateFormat('M월 d일').format(now)} (${'월화수목금토일'[now.weekday - 1]})';
    final counts = {for (final s in attendanceColors.keys) s: students.where((st) => st['status'] == s).length};
    final unchecked = students.where((st) => st['status'] == null).length;

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.teal.shade50,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(academy!['academy_name'] ?? '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('$today 출결 · 수강생 ${students.length}명'),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final e in counts.entries) _countChip(e.key, e.value, attendanceColors[e.key]!),
                    _countChip('미체크', unchecked, Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        if (students.isEmpty)
          Padding(
            padding: EdgeInsets.all(32),
            child: Text('아직 이 학원에 등록한 학생이 없어요.', textAlign: TextAlign.center),
          ),
        for (final s in students)
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['name'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(s['phone_number'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  for (final status in attendanceColors.keys)
                    Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(status),
                        selected: s['status'] == status,
                        selectedColor: attendanceColors[status]!.withOpacity(0.25),
                        labelStyle: TextStyle(
                          color: s['status'] == status ? attendanceColors[status] : Colors.black87,
                          fontWeight: s['status'] == status ? FontWeight.bold : FontWeight.normal,
                        ),
                        showCheckmark: false,
                        onSelected: (_) => setStatus(s, status),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _countChip(String label, int count, Color color) {
    return Chip(
      label: Text('$label $count', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide.none,
    );
  }
}
