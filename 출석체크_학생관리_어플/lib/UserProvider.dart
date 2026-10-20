import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic> _userData = {}; // 사용자 데이터 저장

  Map<String, dynamic> get userData => _userData; // 데이터 접근

  // 데이터 설정
  void setUserData(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners(); // 변경 사항 알림
  }
}
