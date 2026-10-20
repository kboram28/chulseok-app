# 출석체크 앱 백엔드

Express + PostgreSQL 서버입니다. 원래 AWS API Gateway + Lambda로 흩어져 있던 엔드포인트 11개를 서버 하나로 합쳤습니다. 경로와 요청/응답 형태는 앱 코드가 기대하는 그대로입니다.

## 로컬 실행

```bash
# 1) PostgreSQL (Docker)
docker run -d --name chulseok-db -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=chulseok -p 5432:5432 postgres:16

# 2) 서버
cp .env.example .env
npm install
npm run db:init      # 테이블 생성 + 초기 데이터 (--reset 붙이면 초기화)
npm run dev          # http://localhost:3000

# 3) 점검 (서버 켜둔 상태에서)
npm test
```

## 데모 계정 (비밀번호 모두 `test1234`)

| 역할 | 휴대전화번호 | 비고 |
|---|---|---|
| 학생 | 01011112222 | 자녀 코드(id) `1234`, 한빛 수학학원 등록됨 |
| 학부모 | 01033334444 | 김학생과 연결됨 |
| 선생님 | 01055556666 | |

회원가입 인증번호는 문자 대신 **`123456`** 고정입니다 (`TEST_VERIFICATION_CODE`로 변경 가능).

## 클라우드 배포 (무료)

### 1. DB: Supabase
1. https://supabase.com 가입 → New project (Region: Northeast Asia (Seoul))
2. Project Settings → Database → Connection string → **URI** 복사
   (Session pooler 주소 권장, `[YOUR-PASSWORD]` 부분을 프로젝트 비밀번호로 교체)
3. 로컬에서 `.env`의 `DATABASE_URL`을 그 주소로 바꾸고 `npm run db:init`

### 2. 서버: Render
1. 이 `backend` 폴더를 GitHub 저장소에 올리기
2. https://render.com 가입 → New → Web Service → 저장소 선택
   - Build Command: `npm install`
   - Start Command: `npm start`
   - Instance Type: Free
   - Environment Variables: `DATABASE_URL` = Supabase 주소
3. 배포 후 받은 주소(예: `https://chulseok-backend.onrender.com`) 확인
   → `API_BASE_URL=https://... npm test` 로 점검 가능

무료 인스턴스는 15분간 요청이 없으면 잠들어서, 첫 요청이 30초쯤 걸릴 수 있습니다.

### 3. 앱 연결
```bash
flutter run --dart-define=API_BASE_URL=https://chulseok-backend.onrender.com
flutter build apk --dart-define=API_BASE_URL=https://chulseok-backend.onrender.com
```
주소는 `lib/api_config.dart` 한 곳에서 관리합니다.

## API

| 메서드 | 경로 | 용도 |
|---|---|---|
| POST | `/data?operation=login` | 로그인 |
| POST | `/data?operation=createUser` | 회원가입 |
| GET | `/data?operation=getRegions` / `getSubregions&region_id=` | 지역 목록 |
| POST | `/sendVerificationCode`, `/verifyCode` | 휴대폰 인증 (테스트 모드) |
| POST | `/studentsearch?operation=getChildData` / `registerChild` | 자녀 코드 조회/등록 |
| GET | `/studentA?student_id=` | 학생: 등록한 학원 |
| GET | `/parentA?parent_id=`, `/parentB?parent_id=` | 학부모: 자녀 학원 / 자녀 이름 |
| GET | `/database?latitude=&longitude=` | 가까운 학원 목록 |
| POST | `/registerEnrollment` | 학원 등록 |
| GET | `/kakaomap?address=&academyName=` | 학원 지도 페이지 (OpenStreetMap) |
| GET | `/freeboard`, `/freeboardA?postId=` | 게시판 목록 / 상세+댓글 |
| POST | `/freeboardwrite` | 글쓰기 |
