import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// 웹 데모를 PC 같은 넓은 화면에서 열면 앱을 휴대폰 크기 프레임 안에 보여줌.
// 휴대폰 브라우저나 APK(안드로이드)에서는 그대로 전체 화면.
class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

  static const double phoneWidth = 412;
  static const double phoneHeight = 892;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (!kIsWeb || media.size.width < 600) return child;

    // 창 높이가 낮으면 프레임 높이를 줄임
    final height = (media.size.height - 48).clamp(560.0, phoneHeight);
    final showSidePanel = media.size.width >= 1000;

    return ColoredBox(
      color: const Color(0xFF0B3D2E),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSidePanel) const _DemoInfo(),
            if (showSidePanel) const SizedBox(width: 64),
            Container(
              width: phoneWidth + 24,
              height: height + 24,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(48),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 16))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                // 앱 안의 레이아웃이 MediaQuery 로 화면 크기를 계산하므로 프레임 크기로 바꿔서 전달
                child: MediaQuery(
                  data: media.copyWith(
                    size: Size(phoneWidth, height),
                    padding: EdgeInsets.zero,
                    viewPadding: EdgeInsets.zero,
                    viewInsets: EdgeInsets.zero,
                  ),
                  child: SizedBox(width: phoneWidth, height: height, child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoInfo extends StatelessWidget {
  const _DemoInfo();

  @override
  Widget build(BuildContext context) {
    const white = TextStyle(color: Colors.white, decoration: TextDecoration.none, fontWeight: FontWeight.normal);
    return DefaultTextStyle(
      style: white.copyWith(fontSize: 15, height: 1.6),
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('출석체크', style: white.copyWith(fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('학생 · 학부모 · 선생님용 학원 출결 관리 앱', style: white.copyWith(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 32),
            Text('데모 계정', style: white.copyWith(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('역할을 고른 뒤 아래 번호로 로그인하세요.\n비밀번호는 모두 test1234'),
            const SizedBox(height: 12),
            for (final row in const [
              ['선생님', '01055556666'],
              ['학생', '01011112222'],
              ['학부모', '01033334444'],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(width: 64, child: Text(row[0], style: white.copyWith(color: Colors.white70))),
                    Text(row[1], style: white.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text('서버가 잠들어 있으면 첫 로그인에 30초~1분 걸릴 수 있어요.',
                style: white.copyWith(fontSize: 13, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
