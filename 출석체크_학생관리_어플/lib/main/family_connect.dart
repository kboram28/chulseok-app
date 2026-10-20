import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../UserProvider.dart';

// 학생: 학부모에게 알려줄 자녀 코드 보여주기
class FamilyConnectScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final code = '${Provider.of<UserProvider>(context).userData['id'] ?? ''}';

    return Scaffold(
      appBar: AppBar(
        title: Text('가족 관계 연결'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 24),
            Text('내 자녀 코드', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            SizedBox(height: 12),
            Text(
              code,
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8, color: Colors.teal),
            ),
            SizedBox(height: 12),
            TextButton.icon(
              icon: Icon(Icons.copy),
              label: Text('코드 복사'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('자녀 코드를 복사했어요.')));
              },
            ),
            SizedBox(height: 32),
            Card(
              color: Colors.teal.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '학부모님 앱에서 [자녀 계정 등록하기]를 누르고 이 코드를 입력하면 가족으로 연결돼요.\n'
                  '연결되면 학부모님도 내가 다니는 학원과 오늘 출결을 확인할 수 있어요.',
                  style: TextStyle(height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
