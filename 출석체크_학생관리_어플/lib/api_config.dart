// 백엔드 서버 주소. 실행할 때 바꿀 수 있음:
//   flutter run --dart-define=API_BASE_URL=https://내서버.onrender.com
// 안드로이드 에뮬레이터에서 PC 로컬 서버에 붙을 때는 http://10.0.2.2:3000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);
