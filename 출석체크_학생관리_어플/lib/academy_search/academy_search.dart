import 'package:apiintegration/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'AcademyDetailPage.dart'; // AcademyDetailPage.dart 파일 import


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '학원 앱',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MainScreen(), // MainScreen으로 변경
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 탭별로 표시할 화면
  final List<Widget> _screens = [
    HomeScreen2(), // 학원 목록 화면
    Center(child: Text('학원 정보')), // 학원 정보 화면 (미구현)
    Center(child: Text('내 정보')), // 내 정보 화면 (미구현)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
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
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class HomeScreen2 extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen2> {
  List<dynamic> academies = [];
  List<dynamic> filteredAcademies = [];
  String selectedCategory = "전체";
  String searchText = ""; // 검색어
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAcademies();
  }

  // 휴대폰 GPS로 현재 위치 가져오기
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('위치 서비스를 활성화해주세요.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부되었습니다.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // 위치를 못 가져올 때 쓰는 기본 위치 (서울 강남역)
  static const double defaultLatitude = 37.4979;
  static const double defaultLongitude = 127.0276;

  // 학원 데이터 가져오기
  Future<void> fetchAcademies() async {
    try {
      double latitude = defaultLatitude;
      double longitude = defaultLongitude;
      try {
        Position position = await getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('현재 위치를 가져오지 못해 강남역 기준으로 보여드려요.')),
          );
        }
      }

      final url = Uri.parse(
          '$apiBaseUrl/database?latitude=$latitude&longitude=$longitude');
      final response = await http.get(
        url,
        headers: {"Accept": "application/json; charset=utf-8"},
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedResponse);

        setState(() {
          academies = data ?? []; // null일 경우 빈 리스트 사용
          filteredAcademies = data ?? []; // null일 경우 빈 리스트 사용
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  // 필터 적용
  void applyFilters() {
    setState(() {
      filteredAcademies = academies.where((academy) {
        final matchesCategory =
            selectedCategory == "전체" || academy['category'] == selectedCategory;
        final matchesSearch = academy['name']
            ?.toString()
            ?.toLowerCase()
            ?.contains(searchText.toLowerCase()) ??
            false; // 학원 이름 검색
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('학원'),
      ),
      body: Column(
        children: [
          // 카테고리 필터
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // 첫 번째 줄 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // 버튼 중앙 정렬
                  children: [
                    _fixedCategoryButton("전체"),
                    SizedBox(width: 20.0),
                    _fixedCategoryButton("입시 및 보습"),
                    SizedBox(width: 20.0),
                    _fixedCategoryButton("외국어"),
                  ],
                ),
                SizedBox(height: 8.0),
                // 두 번째 줄 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // 버튼 중앙 정렬
                  children: [
                    SizedBox(width: 15.0), // "전체"와 "입시 및 보습" 사이 간격
                    _fixedCategoryButton("예체능"),
                    SizedBox(width: 32.0), // "입시 및 보습"과 "외국어" 사이 간격
                    _fixedCategoryButton("검정 및 기타"),
                  ],
                ),
              ],
            ),
          ),
          // 검색창
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              onChanged: (value) {
                searchText = value; // 검색어 업데이트
                applyFilters(); // 필터 적용
              },
              decoration: InputDecoration(
                hintText: '학원 이름 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          // 학원 목록
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredAcademies.isEmpty
                ? Center(child: Text('검색 결과가 없습니다.'))
                : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 한 줄에 2개씩
                mainAxisSpacing: 2, // 세로 간격
                crossAxisSpacing: 10, // 가로 간격
                childAspectRatio: 0.7, // 아이템의 가로 세로 비율
              ),
              padding: const EdgeInsets.all(8.0),
              itemCount: filteredAcademies.length,
              itemBuilder: (context, index) {
                final academy = filteredAcademies[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AcademyDetailPage(
                          academyId: academy['id'] ?? 0, // 학원 ID
                          address:
                          academy['address'] ?? '주소 없음', // 학원 주소
                          academyName: academy['name'] ??
                              '학원 이름 없음', // 학원 이름
                          academyNumber: academy['contact_number'] ??
                              '없음', // 학원 전화번호
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                              BorderRadius.circular(10.0),
                              child: Container(
                                color: Colors.grey[300], // 이미지 대체시 수정
                                child: Center(
                                  child: Icon(
                                    Icons.school_outlined,
                                    size: 50,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            academy['name'] ?? '알 수 없음', // null 방지
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3),
                          Text(
                            academy['address'] ?? '주소 없음', // null 방지
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '[test]:${(academy['distance'] ?? 0.0).toStringAsFixed(2)} km', // null 방지
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 카테고리 버튼 위젯
  Widget _fixedCategoryButton(String category) {
    return SizedBox(
      width: 110, // 버튼의 고정 너비 설정
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedCategory = category;
            applyFilters();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
          selectedCategory == category ? Colors.green : Colors.grey[300],
          foregroundColor:
          selectedCategory == category ? Colors.white : Colors.black,
          elevation: 0, // 그림자 제거
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0), // 둥근 버튼
          ),
          padding: EdgeInsets.symmetric(vertical: 10), // 버튼 높이 조정
        ),
        child: Text(
          category,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center, // 텍스트 가운데 정렬
        ),
      ),
    );
  }
}
