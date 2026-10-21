import 'package:apiintegration/api_config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'signup/StudentSignUpPage1.dart';
import 'signup/ParentSignUpPage1.dart';
import 'signup/TeacherSignUpPage1.dart';
import 'main/Studenthome.dart';
import 'main/Parenthome.dart';
import 'main/Teacherhome.dart';
import 'UserProvider.dart';
import 'phone_frame.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()), // UserProvider 등록
      ],
      child: chulseokcheck(),
    ),
  );
}

class chulseokcheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '출석체크',
      builder: (context, child) => PhoneFrame(child: child!),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(Duration(seconds: 3), () {});
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF007F4E),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height / 3,
              child: Text(
                '출석',
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Colors.black,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isStudentSelected = false;
  bool isParentSelected = false;
  bool isTeacherSelected = false;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 로그인 함수
  Future<void> _login() async {
    const String apiUrl =
        '$apiBaseUrl/data?operation=login';
    final phoneNumber = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (phoneNumber.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('휴대전화번호와 비밀번호를 입력해주세요.')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"phone_number": phoneNumber, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = data['user'];

        if (user == null) {
          print("Error: User data is null");
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('사용자 데이터를 가져오지 못했습니다.')));
          return;
        }

        // UserProvider를 사용하여 데이터 저장
        Provider.of<UserProvider>(context, listen: false).setUserData(user);

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('로그인 성공!')));

        // 사용자 role에 따라 다른 화면으로 이동
        if (user['role'] == '학생') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen1()), // main/Studenthome.dart
          );
        } else if (user['role'] == '학부모') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen2()), // main/Parenthome.dart
          );
        } else if (user['role'] == '선생님') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TeacherHomeScreen()), // main/Teacherhome.dart
          );
        } else {
          // role이 없거나 알 수 없는 경우 기본 홈 화면으로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen1()),
          );
        }
      } else {
        final error = json.decode(response.body)['message'] ?? '로그인 실패';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    }
  }


  // 역할별 회원가입 페이지로 이동
  void _navigateToSignup() {
    if (isStudentSelected) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StudentSignUpPage1()),
      );
    } else if (isParentSelected) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ParentSignUpPage1()),
      );
    } else if (isTeacherSelected) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TeacherSignUpPage1()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('먼저 역할을 선택해주세요!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF007F4E),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 150.0, 16.0, 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.only(bottom: 40),
              child: Text(
                '출석',
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isStudentSelected = true;
                      isParentSelected = false;
                      isTeacherSelected = false;
                    });
                  },
                  child: Text('학생',
                      style: TextStyle(fontFamily: 'SF', fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isStudentSelected ? Colors.orange : Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isStudentSelected = false;
                      isParentSelected = true;
                      isTeacherSelected = false;
                    });
                  },
                  child: Text('학부모',
                      style: TextStyle(fontFamily: 'SF', fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isParentSelected ? Colors.yellow : Colors.grey[300],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isStudentSelected = false;
                      isParentSelected = false;
                      isTeacherSelected = true;
                    });
                  },
                  child: Text('선생님',
                      style: TextStyle(fontFamily: 'SF', fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTeacherSelected ? Colors.grey : Colors.grey[300],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                hintText: '휴대전화번호 입력',
                hintStyle: TextStyle(fontSize: 18),
                filled: true,
                fillColor: Color.fromARGB(255, 165, 203, 207),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(fontFamily: 'SF'),
            ),
            SizedBox(height: 30),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                hintText: '비밀번호 입력',
                hintStyle: TextStyle(fontSize: 18),
                filled: true,
                fillColor: Color.fromARGB(255, 165, 203, 207),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
              obscureText: true,
              style: TextStyle(fontFamily: 'SF'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _login,
              child: Text('로그인',
                  style: TextStyle(fontFamily: 'SF', fontSize: 18)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Color.fromARGB(255, 165, 203, 207),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text('비밀번호 찾기',
                      style: TextStyle(
                          fontFamily: 'SF',
                          color: Colors.black,
                          fontSize: 18)),
                ),
                TextButton(
                  onPressed: () {
                    if (isStudentSelected) {
                      // 학생 회원가입 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StudentSignUpPage1()),
                      );
                    } else if (isParentSelected) {
                      // 학부모 회원가입 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ParentSignUpPage1()),
                      );
                    } else if (isTeacherSelected) {
                      // 선생님 회원가입 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TeacherSignUpPage1()),
                      );
                    } else {
                      // 아무 버튼도 선택되지 않은 경우
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('먼저 회원 유형을 선택해주세요!')),
                      );
                    }
                  },
                  child: Text(
                    '회원가입',
                    style: TextStyle(fontFamily: 'SF', color: Colors.black, fontSize: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
