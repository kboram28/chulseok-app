import 'package:apiintegration/api_config.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AcademyDetailPage extends StatefulWidget {
  final int academyId;
  final String address;
  final String academyName;
  final String academyNumber;

  AcademyDetailPage({
    required this.academyId,
    required this.address,
    required this.academyName,
    required this.academyNumber,
  });

  @override
  State<AcademyDetailPage> createState() => _AcademyDetailPageState();
}

class _AcademyDetailPageState extends State<AcademyDetailPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
    WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
              Page resource error:
                code: ${error.errorCode}
                description: ${error.description}
                errorType: ${error.errorType}
                isForMainFrame: ${error.isForMainFrame}
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          '$apiBaseUrl/kakaomap?'
              'address=${Uri.encodeComponent(widget.address)}&'
              'academyName=${Uri.encodeComponent(widget.academyName)}',
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  Future<void> registerEnrollment(int academyId) async {
    final userData = Provider.of<UserProvider>(context, listen: false).userData;

    // studentId와 academyId를 확인하는 디버깅 출력
    print("Student ID: ${userData['id']}");
    print("Academy ID: $academyId");

    final url = Uri.parse('$apiBaseUrl/registerEnrollment');
    final body = {
      "studentId": userData['id'], // UserProvider에서 가져온 학생 ID
      "academyId": academyId,      // 페이지에서 전달받은 학원 ID
    };

    print("Request Body: $body"); // 요청 데이터 확인

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("등록 성공!")),
        );
      } else {
        print("Error Response: ${response.body}"); // 오류 응답 출력
        final error = json.decode(response.body)['message'] ?? '등록 실패';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 이미지 영역
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          'https://thorntons-investments.co.uk/wp-content/uploads/2017/08/400x200.png'), // 이미지 URL
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // 뒤로 가기 버튼
                Positioned(
                  top: 40,
                  left: 16,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // 뒤로 가기
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: 16,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30), // 모서리 둥글게 설정
                    ),
                    child: Icon(
                      Icons.person,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            // 학원 정보 영역
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40), // 프로필 아래 공간 확보
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 학원 이름
                      Expanded(
                        child: Text(
                          widget.academyName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // 등록 신청 버튼
                      ElevatedButton.icon(
                        onPressed: () async {
                          await registerEnrollment(widget.academyId); // academyId 전달
                        },
                        icon: Icon(Icons.check_circle),
                        label: Text("등록 신청"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          textStyle: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // 학원 정보 회색 박스
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // 회색 배경
                      borderRadius: BorderRadius.circular(12), // 모서리 둥글게
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.address,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.check, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              widget.academyNumber, // 학원 전화번호 표시
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.public, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              "없음", // 실제 데이터가 있다면 여기에 표시
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 32),
                  // 지도 표시
                  Text(
                    "위치",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 320,
                    child: WebViewWidget(controller: _controller),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}