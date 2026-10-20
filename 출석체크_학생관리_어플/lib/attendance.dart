import 'dart:convert';
import 'package:apiintegration/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 출결 상태별 색
const Map<String, Color> attendanceColors = {
  '출석': Colors.green,
  '지각': Colors.orange,
  '결석': Colors.red,
};

// 오늘(한국 시간) 출결 상태. 체크 전이면 null
Future<String?> fetchTodayAttendance(dynamic studentId) async {
  final response = await http.get(Uri.parse('$apiBaseUrl/attendance?student_id=$studentId'));
  if (response.statusCode != 200) return null;
  return json.decode(utf8.decode(response.bodyBytes))['status'];
}

// 학생/학부모 홈에 보여주는 "오늘 출결" 표시
class TodayAttendanceBadge extends StatelessWidget {
  final dynamic studentId;

  const TodayAttendanceBadge({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: fetchTodayAttendance(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 32);
        }
        final status = snapshot.data;
        final color = attendanceColors[status] ?? Colors.grey;
        return Row(
          children: [
            const Text('오늘 출결  ', style: TextStyle(fontSize: 15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status ?? '아직 체크 전',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
