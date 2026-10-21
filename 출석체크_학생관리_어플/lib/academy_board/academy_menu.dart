import 'package:apiintegration/community/calendar.dart';
import 'package:apiintegration/community/profile_detail_screen.dart';
import 'package:flutter/material.dart';
import 'board_common.dart';
import 'notice_screen.dart';
import 'qna_screen.dart';
import 'schedule_screen.dart';

// 학생·학부모 홈의 학원 카드에 들어가는 메뉴 버튼
class AcademyMenuButtons extends StatelessWidget {
  const AcademyMenuButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, Widget Function())>[
      (Icons.campaign, '공지사항', () => const NoticeScreen()),
      (Icons.event_note, '과제·시험', () => const ScheduleScreen()),
      (Icons.forum, '질문하기', () => const QnaScreen()),
      (Icons.calendar_month, '캘린더', () => CalendarPage()),
      (Icons.groups, '커뮤니티', () => const CommunityScreen()),
    ];
    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.85,
      children: [
        for (final (icon, label, page) in items)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page())),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.teal.shade50,
                  child: Icon(icon, color: Colors.teal),
                ),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }
}

// 다가오는 과제·시험 미리보기 (최대 2개)
class UpcomingSchedulePreview extends StatelessWidget {
  const UpcomingSchedulePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: apiGet('/schedules?user_id=${currentUser(context)['id']}'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 24);
        final items = (snapshot.data as List?) ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('다가오는 과제·시험', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (items.length > 2)
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduleScreen())),
                    child: Text('전체 ${items.length}개'),
                  ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('예정된 일정이 없어요.', style: TextStyle(color: Colors.grey[600])),
              ),
            for (final s in items.take(2)) ScheduleCard(schedule: s),
          ],
        );
      },
    );
  }
}
