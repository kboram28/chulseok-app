import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:apiintegration/signup/StudentSignUpPage2.dart';

class StudentSignUpPage1 extends StatefulWidget {
  @override
  _StudentSignUpPage1State createState() => _StudentSignUpPage1State();
}

class _StudentSignUpPage1State extends State<StudentSignUpPage1> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // 비밀번호 확인 컨트롤러 추가
  String _birthdate = '';
  String _gender = '';
  List<int> _selectedFields = [];

  void _navigateToNextPage() {
    if (_nameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty || // 비밀번호 확인 필드 체크
        _birthdate.isEmpty ||
        _gender.isEmpty ||
        _selectedFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('모든 필드를 입력해주세요.')));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('비밀번호가 일치하지 않습니다.')));
      return;
    }

    // 다음 페이지로 데이터 전달
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentSignUpPage2(
          userData: {
            "name": _nameController.text,
            "password": _passwordController.text,
            "birthdate": _birthdate,
            "gender": _gender,
            "fields": _selectedFields,
            "role": "학생",
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('학생 회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                '이름 *필수',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '본인 이름을 24자 이내로 입력',
                  filled: true,
                  fillColor: Colors.grey[300],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                '비밀번호 *필수',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '영문자/숫자/특수문자 8자 이상',
                  filled: true,
                  fillColor: Colors.grey[300],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                '비밀번호 확인 *필수',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '비밀번호를 다시 입력하세요',
                  filled: true,
                  fillColor: Colors.grey[300],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '생년월일 *필수',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _birthdate = selectedDate.toIso8601String().split('T')[0];
                    });
                  }
                },
                child: Text(_birthdate.isEmpty ? '생년월일 선택' : _birthdate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                ),
              ),
              SizedBox(height: 20),
              Text(
                '성별 *필수',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _gender = '남';
                        });
                      },
                      child: Text('남자'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gender == '남' ? Colors.green : Colors.grey[300],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _gender = '여';
                        });
                      },
                      child: Text('여자'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gender == '여' ? Colors.green : Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                '관심있는 분야 *필수',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                children: [
                  _buildInterestButton('입시 및 보습', 1),
                  _buildInterestButton('외국어', 2),
                  _buildInterestButton('예체능', 3),
                  _buildInterestButton('검정 및 기타', 4),
                ],
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('취소'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _navigateToNextPage,
                    child: Text('다음'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterestButton(String label, int id) {
    final isSelected = _selectedFields.contains(id);
    return ElevatedButton(
      onPressed: () {
        setState(() {
          if (isSelected) {
            _selectedFields.remove(id);
          } else {
            _selectedFields.add(id);
          }
        });
      },
      child: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.grey[300],
      ),
    );
  }
}
