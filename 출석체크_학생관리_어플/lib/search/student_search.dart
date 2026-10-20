import 'package:apiintegration/api_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../UserProvider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChildRegisterPage extends StatefulWidget {
  @override
  _ChildRegisterPageState createState() => _ChildRegisterPageState();
}

class _ChildRegisterPageState extends State<ChildRegisterPage> {
  final TextEditingController codeController = TextEditingController();
  String? childName;
  String? childPhone;
  String? childBirthDate;
  String? childGender;

  Future<void> _fetchChildData(String code) async {
    final parentData = Provider.of<UserProvider>(context, listen: false).userData;

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('코드를 입력해주세요.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/studentsearch?operation=getChildData'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"code": code}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          childName = data['name'];
          childPhone = data['phone_number'];
          childBirthDate = data['birthdate'];
          childGender = data['gender'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('자녀 데이터를 가져올 수 없습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  Future<void> _registerChild(String childId) async {
    final parentData = Provider.of<UserProvider>(context, listen: false).userData;

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/studentsearch?operation=registerChild'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "parentId": parentData["id"],
          "studentId": childId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('자녀 등록 성공!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('자녀 등록 실패: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('자녀 등록'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // 로그아웃 버튼 클릭 시 로그인 화면으로 이동
              Navigator.pushReplacementNamed(context, '/login'); // '/login'은 로그인 화면 라우트 이름
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '자녀 등록 *필수 (자녀와 연동됩니다)',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      hintText: '자녀 코드를 입력해주세요',
                      filled: true,
                      fillColor: Colors.grey[300],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _fetchChildData(codeController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('조회'),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (childName != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이름: $childName', style: TextStyle(fontSize: 16)),
                  Text('전화번호: $childPhone', style: TextStyle(fontSize: 16)),
                  Text('생년월일: $childBirthDate', style: TextStyle(fontSize: 16)),
                  Text('성별: $childGender', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _registerChild(codeController.text),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        '자녀 등록',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
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
