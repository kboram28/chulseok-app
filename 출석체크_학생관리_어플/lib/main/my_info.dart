import 'package:flutter/material.dart';

class MyInfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 정보'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Text('내 정보 화면입니다.'),
      ),
    );
  }
}
