import 'package:flutter/material.dart';

class AcademySearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('학원 찾기'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Text('학원 찾기 화면입니다.'),
      ),
    );
  }
}
