import 'package:apiintegration/api_config.dart';
import 'package:apiintegration/academy_search/academy_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../UserProvider.dart';
import 'family_connect.dart';
import 'package:apiintegration/attendance.dart';
import 'package:apiintegration/community/calendar.dart';
import 'package:apiintegration/community/profile_detail_screen.dart';
import 'my_info.dart';
import 'package:apiintegration/search/student_search.dart';

class HomeScreen2 extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen2> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MainHome(), // 메인 화면
      AcademyListScreen(), // 학원 찾기 화면
      MyInfoScreen(), // 내 정보 화면
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: '학원',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}

// 메인 홈 화면
class MainHome extends StatelessWidget {
  Future<Map<String, dynamic>?> fetchChild(BuildContext context) async {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    final parentId = userData['id']; // 부모 ID 가져오기

    try {
      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/parentB?parent_id=$parentId', // 부모 ID로 자녀 정보 가져오는 엔드포인트
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data.isNotEmpty) {
          return data; // 자녀 id, 이름
        }
      }
      return null; // 등록된 자녀가 없는 경우
    } catch (e) {
      print("Error fetching child name: $e");
      return null; // 오류 발생 시
    }
  }

  Future<Map<String, dynamic>?> fetchChildAcademy(BuildContext context) async {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;
    final parentId = userData['id']; // 부모 ID 가져오기

    try {
      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/parentA?parent_id=$parentId',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Fetched Academy Data: $data");

        if (data != null && data.isNotEmpty) {
          return {
            "academyName": data['academyName'], // 데이터 키를 소문자 형태로 맞춤
          };
        }
      }
      return null; // 자녀가 등록한 학원이 없는 경우
    } catch (e) {
      print("Error fetching child academy: $e");
      return null; // 오류 발생 시
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;

    return Scaffold(
      appBar: AppBar(
        title: Text('출석'),
        backgroundColor: Colors.teal, // AppBar 색상
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 자녀 연결 섹션
            FutureBuilder<Map<String, dynamic>?>(
              future: fetchChild(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final child = snapshot.data;
                final childName = child?['name'];

                return Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childName != null
                            ? '자녀 이름: $childName' // 자녀 이름 표시
                            : '가족과 연결하시면,',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        childName != null
                            ? '등록된 자녀 정보입니다.'
                            : '알림창, 결제 등 다양한 기능을 가족과 공유할 수 있어요.',
                        style: TextStyle(fontSize: 14),
                      ),
                      if (child != null) ...[
                        SizedBox(height: 12),
                        TodayAttendanceBadge(studentId: child['id']),
                      ],
                      if (childName == null) ...[
                        SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChildRegisterPage(),
                              ),
                            );
                          },
                          child: Text(
                            '자녀 계정 등록하기',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            // 등록한 학원 섹션
        FutureBuilder<Map<String, dynamic>?>(
          future: fetchChildAcademy(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Card(
                margin: EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '등록한 학원',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '지금 다니고 있는 학원을 등록해보세요!',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AcademyListScreen(),
                            ),
                          );
                        },
                        child: Text(
                          '학원 찾기',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final academy = snapshot.data!;
            return Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      academy['academyName'] ?? '학원 없음',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CalendarPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('캘린더'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CommunityScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('커뮤니티'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            // 결제 관리 페이지로 이동
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('결제 관리'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),

            // 사용자 정보 표시 섹션
            Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '사용자 정보',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('이름: ${userData['name'] ?? '이름 없음'}'),
                    Text('권한: ${userData['role'] ?? '권한 없음'}'),
                    Text('전화번호: ${userData['phone_number'] ?? '전화번호 없음'}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
