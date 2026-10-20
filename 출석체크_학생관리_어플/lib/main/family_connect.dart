import 'package:flutter/material.dart';

class FamilyConnectScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('가족 관계 연결'),
        backgroundColor: Colors.teal, // AppBar 색상 변경
      ),
      body: Center(
        child: Text(
          '가족 관계 연결 페이지입니다!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
