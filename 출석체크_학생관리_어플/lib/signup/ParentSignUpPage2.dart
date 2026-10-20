import 'package:apiintegration/api_config.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ParentSignUpPage2 extends StatefulWidget {
  final Map<String, dynamic> userData;

  ParentSignUpPage2({required this.userData});

  @override
  _ParentSignUpPage2State createState() => _ParentSignUpPage2State();
}

class _ParentSignUpPage2State extends State<ParentSignUpPage2> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _selectedRegion = '';
  String _selectedSubregion = '';
  List<dynamic> _regions = [];
  List<dynamic> _subregions = [];
  bool _isVerified = false;
  bool _isTimerActive = false; // 타이머 상태
  int _remainingTime = 180; // 3분 (초)
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.userData['phone_number'] ?? '';
    _fetchRegions();
  }

  @override
  void dispose() {
    _timer?.cancel(); // 타이머 정리
    super.dispose();
  }

  // 타이머 시작
  void _startTimer() {
    setState(() {
      _isTimerActive = true;
      _remainingTime = 180;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTimerActive = false;
        });
      }
    });
  }

  // 인증번호 발송 함수
  Future<void> _sendVerificationCode() async {
    const url = '$apiBaseUrl/sendVerificationCode';
    final phoneNumber = _phoneController.text;

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('휴대전화번호를 입력해주세요.')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"phoneNumber": phoneNumber}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('인증번호가 발송되었습니다.')));
        _startTimer(); // 인증번호 발송 후 타이머 시작
      } else {
        throw Exception('Failed to send verification code: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    }
  }

  // 인증번호 확인 함수
  Future<void> _verifyCode() async {
    const url = '$apiBaseUrl/verifyCode';
    final phoneNumber = _phoneController.text;
    final enteredCode = _otpController.text;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"phoneNumber": phoneNumber, "enteredCode": enteredCode}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isVerified = true;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('인증 성공!')));
      } else {
        throw Exception('Failed to verify code: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    }
  }

  // 남은 시간 포맷팅
  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  // Fetch regions from the API
  Future<void> _fetchRegions() async {
    try {
      final response = await http.get(Uri.parse(
          '$apiBaseUrl/data?operation=getRegions'));

      if (response.statusCode == 200) {
        setState(() {
          _regions = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load regions: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching regions: $e')));
    }
  }

  // Fetch subregions based on the selected region
  Future<void> _fetchSubregions(String regionId) async {
    try {
      final response = await http.get(Uri.parse(
          '$apiBaseUrl/data?operation=getSubregions&region_id=$regionId'));

      if (response.statusCode == 200) {
        setState(() {
          _subregions = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load subregions');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching subregions: $e')));
    }
  }

  // Submit final data to the database
  Future<void> _submitData() async {
    if (!_isVerified) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('휴대전화번호 인증이 필요합니다.')));
      return;
    }

    const String apiUrl = '$apiBaseUrl/data?operation=createUser';

    if (_phoneController.text.isEmpty || _selectedRegion.isEmpty || _selectedSubregion.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('모든 필드를 입력해주세요.')));
      return;
    }

    try {
      final body = {
        ...widget.userData,
        "phone_number": _phoneController.text,
        "region_id": _selectedRegion,
        "subregion_id": _selectedSubregion,
        "id": _phoneController.text,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('회원가입 성공!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('회원가입 실패: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('학부모 회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                '휴대전화번호 *필수',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '휴대전화번호 입력 (예: 01012345678)',
                        filled: true,
                        fillColor: Colors.grey[300],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isTimerActive ? null : _sendVerificationCode,
                    child: Text('인증번호 발송'),
                  ),
                ],
              ),
              if (_isTimerActive)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '남은 시간: ${_formatTime(_remainingTime)}',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              SizedBox(height: 10),
              if (!_isVerified)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '인증번호 입력',
                          filled: true,
                          fillColor: Colors.grey[300],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _verifyCode,
                      child: Text('인증 확인'),
                    ),
                  ],
                ),
              SizedBox(height: 20),
              Text(
                '시/도 선택 *필수',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField(
                value: _selectedRegion.isEmpty ? null : _selectedRegion,
                hint: Text('시/도 선택'),
                items: _regions.map<DropdownMenuItem<String>>((region) {
                  return DropdownMenuItem<String>(
                    value: region['id'].toString(), // id를 값으로 설정
                    child: Text(region['name']),    // name을 표시
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value!;
                    _selectedSubregion = ''; // Subregion 초기화
                  });

                  // 선택된 Region ID로 Subregion 데이터를 불러옵니다
                  if (value != null) {
                    _fetchSubregions(value);
                  }
                },
                decoration: InputDecoration(
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
                '구/군 선택 *필수',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField(
                value: _selectedSubregion.isEmpty ? null : _selectedSubregion,
                hint: Text('구/군 선택'),
                items: _subregions.map<DropdownMenuItem<String>>((subregion) {
                  return DropdownMenuItem<String>(
                    value: subregion['id'].toString(), // id를 값으로 설정
                    child: Text(subregion['name']),    // name을 표시
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubregion = value!;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[300],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('이전'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _submitData,
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
}
