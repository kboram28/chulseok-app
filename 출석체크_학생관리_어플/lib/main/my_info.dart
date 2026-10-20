import 'package:apiintegration/main.dart' show HomeScreen;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../UserProvider.dart';

class MyInfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserProvider>(context).userData;
    final isStudent = userData['role'] == '학생';

    return Scaffold(
      appBar: AppBar(
        title: Text('내 정보'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                _infoTile(Icons.person, '이름', userData['name']),
                _infoTile(Icons.badge, '역할', userData['role']),
                _infoTile(Icons.phone, '전화번호', userData['phone_number']),
                _infoTile(Icons.cake, '생년월일', userData['birthdate']),
                _infoTile(Icons.wc, '성별', userData['gender']),
              ],
            ),
          ),
          if (isStudent) ...[
            SizedBox(height: 16),
            Card(
              color: Colors.teal.shade50,
              child: ListTile(
                leading: Icon(Icons.key, color: Colors.teal),
                title: Text('내 자녀 코드: ${userData['id']}'),
                subtitle: Text('학부모님이 이 코드로 자녀 계정을 연결할 수 있어요.'),
              ),
            ),
          ],
          SizedBox(height: 32),
          OutlinedButton.icon(
            icon: Icon(Icons.logout),
            label: Text('로그아웃'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).setUserData({});
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, dynamic value) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      subtitle: Text('${value ?? '-'}', style: TextStyle(fontSize: 16, color: Colors.black)),
    );
  }
}
