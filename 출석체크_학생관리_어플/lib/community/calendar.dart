import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apiintegration/UserProvider.dart'; // 수정된 import 경로
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int currentYear = DateTime.now().year; // 현재 연도
  int currentMonth = DateTime.now().month; // 현재 월
  int? selectedDay; // 선택된 날짜
  Map<String, String> memo = {}; // 날짜별 메모 저장
  List<Map<String, String>> savedMemos = []; // 저장된 메모 목록 (최대 2개)

  // 월 이동 처리
  void changeMonth(int offset) {
    setState(() {
      currentMonth += offset;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      } else if (currentMonth < 1) {
        currentMonth = 12;
        currentYear--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;

    // 월 이름 배열
    final months = [
      "1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월"
    ];

    // 월별 일수 계산 및 시작 요일
    DateTime firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
    int daysInMonth = DateUtils.getDaysInMonth(currentYear, currentMonth);
    int startWeekday = firstDayOfMonth.weekday % 7; // 월요일(1)~일요일(7)을 일요일(0)~토요일(6)로 변환

    // 생년월일 포맷
    String formattedBirthDate = userData['birthdate'] != null
        ? DateFormat('yyyy년 MM월 dd일').format(DateTime.parse(userData['birthdate']))
        : '생일 정보 없음';

    return Scaffold(
      appBar: AppBar(
        title: Text('캘린더'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사용자 정보 창
            Container(
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal, width: 2),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData['name'] ?? '이름 없음',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formattedBirthDate,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // 캘린더 상단 (월/연도 변경)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed: () {
                    changeMonth(-1); // 이전 달
                  },
                ),
                Text(
                  '$currentYear년 ${months[currentMonth - 1]}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: () {
                    changeMonth(1); // 다음 달
                  },
                ),
              ],
            ),

            // 요일 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["일", "월", "화", "수", "목", "금", "토"]
                  .map((day) => Text(
                day,
                style: TextStyle(fontWeight: FontWeight.bold),
              ))
                  .toList(),
            ),

            SizedBox(height: 10),

            // 캘린더
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // 한 줄에 7일씩
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: daysInMonth + startWeekday, // 앞에 비어 있는 공간 추가
                itemBuilder: (context, index) {
                  if (index < startWeekday) {
                    return Container(); // 빈 공간
                  }
                  final day = index - startWeekday + 1; // 실제 날짜 계산
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDay = day;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: selectedDay == day
                            ? Colors.teal.shade300
                            : Colors.teal.shade50, // 선택된 날짜 강조
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            // 선택된 날짜의 메모 표시
            if (selectedDay != null) ...[
              Text(
                '${currentYear}년 ${months[currentMonth - 1]} ${selectedDay!}일 메모',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  setState(() {
                    String dateKey =
                        '$currentYear-${currentMonth.toString().padLeft(2, '0')}-${selectedDay.toString().padLeft(2, '0')}';
                    memo[dateKey] = value; // 날짜별 메모 저장
                  });
                },
                decoration: InputDecoration(
                  hintText: '${selectedDay!}일의 메모를 입력하세요.',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 10),
              ElevatedButton(
                onPressed: savedMemos.length >= 2
                    ? null // 메모가 2개일 경우 저장 불가
                    : () {
                  String dateKey =
                      '$currentYear-${currentMonth.toString().padLeft(2, '0')}-${selectedDay.toString().padLeft(2, '0')}';

                  if (memo[dateKey] != null && memo[dateKey]!.isNotEmpty) {
                    setState(() {
                      savedMemos.add({
                        "date": dateKey,
                        "content": memo[dateKey]!,
                      });
                    });
                  }
                },
                child: Text('메모 저장'),
              ),
            ],

            SizedBox(height: 20),

            // 저장된 메모 표시 (캘린더 아래)
            if (savedMemos.isNotEmpty) ...[
              Text(
                '저장된 메모',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Column(
                children: savedMemos.map((memo) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${memo['date']}: ${memo['content']}',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            savedMemos.remove(memo); // 메모 삭제
                          });
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
