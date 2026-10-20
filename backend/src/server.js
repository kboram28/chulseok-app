// 출석체크 앱 백엔드
// 원래 AWS API Gateway + Lambda 로 나뉘어 있던 엔드포인트들을 하나의 Express 서버로 재구성.
// 경로·요청·응답 형태는 앱(lib/) 코드가 기대하는 그대로 유지한다.

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const db = require('./db');

const app = express();
app.use(cors());
app.use(express.json());

// SMS 대신 쓰는 테스트용 고정 인증번호 (실제 문자 발송 없음)
const TEST_VERIFICATION_CODE = process.env.TEST_VERIFICATION_CODE || '123456';

// 앱이 created_at 앞 10자리를 날짜로 쓰므로 한국 시간 문자열로 내려줌
const kst = (col) => `to_char(${col} AT TIME ZONE 'Asia/Seoul', 'YYYY-MM-DD"T"HH24:MI:SS')`;

const digitsOnly = (s) => String(s ?? '').replace(/\D/g, '');

// 비동기 라우트 에러를 한 곳에서 처리
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

const publicUser = (u) => ({
  id: u.id,
  name: u.name,
  role: u.role,
  phone_number: u.phone_number,
  birthdate: u.birthdate,
  gender: u.gender,
  fields: u.fields,
  region_id: u.region_id,
  subregion_id: u.subregion_id,
});

app.get('/health', (req, res) => res.json({ ok: true }));

// 서버 주소를 브라우저로 열었을 때 보이는 소개 페이지
app.get('/', (req, res) => {
  res.type('html').send(`<!doctype html>
<html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>출석체크 API</title>
<style>
  body{font-family:system-ui,sans-serif;max-width:640px;margin:40px auto;padding:0 16px;color:#1a1a1a;line-height:1.6}
  h1{color:#007F4E;margin-bottom:4px}
  .ok{display:inline-block;background:#e6f4ec;color:#007F4E;padding:2px 10px;border-radius:12px;font-size:14px}
  code{background:#f2f2f2;padding:1px 6px;border-radius:4px}
  li{margin:2px 0}
</style></head><body>
<h1>출석체크 API 서버</h1>
<span class="ok">● 정상 동작 중</span>
<p>학생·학부모·선생님용 출석/학원 관리 앱 <b>출석체크</b>의 백엔드입니다.<br>
Node.js(Express) + PostgreSQL(Supabase), Render 배포.</p>
<h3>주요 API</h3>
<ul>
  <li><code>POST /data?operation=login</code> 로그인 · <code>createUser</code> 회원가입</li>
  <li><code>GET /database?latitude=&amp;longitude=</code> 주변 학원 검색</li>
  <li><code>POST /registerEnrollment</code> 학원 등록</li>
  <li><code>POST /studentsearch</code> 자녀 코드 조회/등록</li>
  <li><code>GET /freeboard</code> · <code>/freeboardA</code> · <code>POST /freeboardwrite</code> · <code>/freeboardcomment</code> 자유게시판</li>
  <li><code>GET /teacher/students</code> · <code>POST /attendance</code> 선생님 출결 체크 · <code>GET /attendance</code> 오늘 출결</li>
</ul>
<p><a href="/health">/health</a> · <a href="https://github.com/kboram28/chulseok-app">GitHub</a></p>
</body></html>`);
});

// ───────────── 계정: /data?operation=... ─────────────

app.all('/data', wrap(async (req, res) => {
  switch (req.query.operation) {
    case 'login': return login(req, res);
    case 'createUser': return createUser(req, res);
    case 'getRegions': return getRegions(req, res);
    case 'getSubregions': return getSubregions(req, res);
    default: return res.status(400).json({ message: '알 수 없는 operation 입니다.' });
  }
}));

async function login(req, res) {
  const phone = digitsOnly(req.body?.phone_number);
  const password = String(req.body?.password ?? '');
  if (!phone || !password) {
    return res.status(400).json({ message: '휴대전화번호와 비밀번호를 입력해주세요.' });
  }
  const { rows } = await db.query('SELECT * FROM users WHERE phone_number = $1', [phone]);
  const user = rows[0];
  if (!user || !(await bcrypt.compare(password, user.password_hash))) {
    return res.status(401).json({ message: '휴대전화번호 또는 비밀번호가 올바르지 않습니다.' });
  }
  res.json({ message: '로그인 성공', user: publicUser(user) });
}

async function createUser(req, res) {
  const b = req.body ?? {};
  const phone = digitsOnly(b.phone_number);
  const role = b.role;
  if (!b.name || !b.password || !phone || !['학생', '학부모', '선생님'].includes(role)) {
    return res.status(400).json({ message: '필수 항목이 누락되었습니다.' });
  }

  const dup = await db.query('SELECT 1 FROM users WHERE phone_number = $1', [phone]);
  if (dup.rowCount) return res.status(409).json({ message: '이미 가입된 휴대전화번호입니다.' });

  // 학생: 앱이 보낸 4자리 랜덤 id 사용(겹치면 서버에서 다시 뽑음). 학부모/선생님: 전화번호 숫자.
  let id;
  if (role === '학생') {
    id = Number(b.id);
    for (let i = 0; i < 50; i++) {
      if (Number.isInteger(id) && id >= 1000 && id <= 9999) {
        const taken = await db.query('SELECT 1 FROM users WHERE id = $1', [id]);
        if (!taken.rowCount) break;
      }
      id = 1000 + Math.floor(Math.random() * 9000);
    }
  } else {
    id = Number(phone);
  }

  const hash = await bcrypt.hash(String(b.password), 10);
  const fields = Array.isArray(b.fields) ? b.fields.map(Number).filter(Number.isInteger) : [];
  await db.query(
    `INSERT INTO users (id, name, password_hash, phone_number, birthdate, gender, fields, role, region_id, subregion_id)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
    [id, b.name, hash, phone, b.birthdate || null, b.gender || null, fields, role,
      b.region_id ? Number(b.region_id) : null, b.subregion_id ? Number(b.subregion_id) : null],
  );
  res.status(201).json({ message: '회원가입 성공', id });
}

async function getRegions(req, res) {
  const { rows } = await db.query('SELECT id, name FROM regions ORDER BY id');
  res.json(rows);
}

async function getSubregions(req, res) {
  const { rows } = await db.query(
    'SELECT id, name FROM subregions WHERE region_id = $1 ORDER BY name',
    [Number(req.query.region_id)],
  );
  res.json(rows);
}

// ───────────── 휴대폰 인증 (테스트 모드) ─────────────

app.post('/sendVerificationCode', wrap(async (req, res) => {
  const phone = digitsOnly(req.body?.phoneNumber);
  if (!phone) return res.status(400).json({ message: '휴대전화번호를 입력해주세요.' });
  await db.query(
    `INSERT INTO verification_codes (phone_number, code, expires_at)
     VALUES ($1, $2, now() + interval '3 minutes')
     ON CONFLICT (phone_number) DO UPDATE SET code = EXCLUDED.code, expires_at = EXCLUDED.expires_at`,
    [phone, TEST_VERIFICATION_CODE],
  );
  console.log(`[테스트 인증번호] ${phone} → ${TEST_VERIFICATION_CODE}`);
  res.json({ message: '인증번호가 발송되었습니다. (테스트 모드)' });
}));

app.post('/verifyCode', wrap(async (req, res) => {
  const phone = digitsOnly(req.body?.phoneNumber);
  const code = String(req.body?.enteredCode ?? '').trim();
  const { rows } = await db.query(
    'SELECT 1 FROM verification_codes WHERE phone_number = $1 AND code = $2 AND expires_at > now()',
    [phone, code],
  );
  if (!rows.length) return res.status(400).json({ message: '인증번호가 올바르지 않거나 만료되었습니다.' });
  await db.query('DELETE FROM verification_codes WHERE phone_number = $1', [phone]);
  res.json({ message: '인증 성공' });
}));

// ───────────── 자녀 검색/등록: /studentsearch?operation=... ─────────────

app.post('/studentsearch', wrap(async (req, res) => {
  const op = req.query.operation;
  if (op === 'getChildData') {
    const { rows } = await db.query(
      `SELECT id, name, phone_number, birthdate, gender FROM users WHERE id = $1 AND role = '학생'`,
      [Number(req.body?.code)],
    );
    if (!rows.length) return res.status(404).json({ message: '해당 코드의 학생을 찾을 수 없습니다.' });
    return res.json(rows[0]);
  }
  if (op === 'registerChild') {
    const parentId = Number(req.body?.parentId);
    const studentId = Number(req.body?.studentId);
    const { rows } = await db.query(`SELECT 1 FROM users WHERE id = $1 AND role = '학생'`, [studentId]);
    if (!rows.length) return res.status(404).json({ message: '해당 코드의 학생을 찾을 수 없습니다.' });
    await db.query(
      'INSERT INTO family (parent_id, student_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [parentId, studentId],
    );
    return res.json({ message: '자녀 등록 성공' });
  }
  res.status(400).json({ message: '알 수 없는 operation 입니다.' });
}));

// ───────────── 홈 화면 ─────────────

// 학부모 홈: 등록한 자녀 이름
app.get('/parentB', wrap(async (req, res) => {
  const { rows } = await db.query(
    `SELECT u.id, u.name FROM family f JOIN users u ON u.id = f.student_id
     WHERE f.parent_id = $1 ORDER BY f.created_at LIMIT 1`,
    [Number(req.query.parent_id)],
  );
  res.json(rows[0] ?? {});
}));

// 학부모 홈: 자녀가 등록한 학원
app.get('/parentA', wrap(async (req, res) => {
  const { rows } = await db.query(
    `SELECT a.id AS "academyId", a.name AS "academyName"
     FROM family f
     JOIN enrollments e ON e.student_id = f.student_id
     JOIN academies a ON a.id = e.academy_id
     WHERE f.parent_id = $1 ORDER BY e.created_at LIMIT 1`,
    [Number(req.query.parent_id)],
  );
  res.json(rows[0] ?? {});
}));

// 학생 홈: 내가 등록한 학원
app.get('/studentA', wrap(async (req, res) => {
  const { rows } = await db.query(
    `SELECT a.id AS academy_id, a.name AS academy_name
     FROM enrollments e JOIN academies a ON a.id = e.academy_id
     WHERE e.student_id = $1 ORDER BY e.created_at LIMIT 1`,
    [Number(req.query.student_id)],
  );
  if (!rows.length) return res.status(404).json({ message: '등록한 학원이 없습니다.' });
  res.json(rows[0]);
}));

// ───────────── 학원 ─────────────

// 내 위치 기준 가까운 학원 목록 (distance: km)
app.get('/database', wrap(async (req, res) => {
  const lat = Number(req.query.latitude);
  const lng = Number(req.query.longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return res.status(400).json({ message: 'latitude, longitude 가 필요합니다.' });
  }
  const { rows } = await db.query(
    `SELECT id, name, category, address, contact_number, latitude, longitude,
            6371 * 2 * asin(sqrt(
              power(sin(radians(latitude - $1) / 2), 2) +
              cos(radians($1)) * cos(radians(latitude)) * power(sin(radians(longitude - $2) / 2), 2)
            )) AS distance
     FROM academies ORDER BY distance LIMIT 100`,
    [lat, lng],
  );
  res.json(rows);
}));

// 학생: 수강 등록 / 선생님: 소속 학원으로 등록 (기존 소속은 변경)
app.post('/registerEnrollment', wrap(async (req, res) => {
  const studentId = Number(req.body?.studentId);
  const academyId = Number(req.body?.academyId);
  const { rows: [user] } = await db.query('SELECT role FROM users WHERE id = $1', [studentId]);
  if (user?.role === '선생님') {
    await db.query(
      `INSERT INTO academy_teachers (teacher_id, academy_id) VALUES ($1, $2)
       ON CONFLICT (teacher_id) DO UPDATE SET academy_id = EXCLUDED.academy_id, created_at = now()`,
      [studentId, academyId],
    );
    return res.json({ message: '소속 학원으로 등록했습니다.' });
  }
  if (user?.role !== '학생') return res.status(403).json({ message: '학생·선생님 계정만 학원에 등록할 수 있습니다.' });
  const result = await db.query(
    'INSERT INTO enrollments (student_id, academy_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
    [studentId, academyId],
  );
  if (!result.rowCount) return res.status(409).json({ message: '이미 등록한 학원입니다.' });
  res.json({ message: '등록 성공' });
}));

// 학원 상세 화면 WebView 에 띄우는 지도 페이지 (OpenStreetMap, API 키 불필요)
app.get('/kakaomap', wrap(async (req, res) => {
  const name = String(req.query.academyName ?? '');
  const address = String(req.query.address ?? '');
  const { rows } = await db.query(
    'SELECT latitude, longitude FROM academies WHERE name = $1 OR address = $2 LIMIT 1',
    [name, address],
  );
  const esc = (s) => s.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);
  const pos = rows[0] ? JSON.stringify([rows[0].latitude, rows[0].longitude]) : 'null';
  res.type('html').send(`<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<style>html,body,#map{height:100%;margin:0}#msg{font:14px sans-serif;padding:16px}</style></head>
<body><div id="map"></div><script>
  var pos = ${pos};
  if (pos) {
    var map = L.map('map').setView(pos, 16);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution: '&copy; OpenStreetMap' }).addTo(map);
    L.marker(pos).addTo(map).bindPopup(${JSON.stringify(`<b>${esc(name)}</b><br>${esc(address)}`)}).openPopup();
  } else {
    document.getElementById('map').innerHTML = '<div id="msg">위치 정보를 찾을 수 없습니다.<br>${esc(address)}</div>';
  }
</script></body></html>`);
}));

// ───────────── 자유게시판 ─────────────

app.get('/freeboard', wrap(async (req, res) => {
  const { rows } = await db.query(
    `SELECT p.id, p.title, p.user_id, u.name AS author_name, p.views, ${kst('p.created_at')} AS created_at
     FROM posts p JOIN users u ON u.id = p.user_id
     ORDER BY p.created_at DESC`,
  );
  res.json({ posts: rows });
}));

app.get('/freeboardA', wrap(async (req, res) => {
  const postId = Number(req.query.postId);
  const { rows } = await db.query(
    `UPDATE posts p SET views = views + 1 FROM users u
     WHERE p.id = $1 AND u.id = p.user_id
     RETURNING p.id, p.title, p.content, p.user_id, u.name AS author_name, p.views, ${kst('p.created_at')} AS created_at`,
    [postId],
  );
  if (!rows.length) return res.status(404).json({ message: '게시글을 찾을 수 없습니다.' });
  const comments = await db.query(
    `SELECT c.id, c.content, u.name AS author, ${kst('c.created_at')} AS created_at
     FROM comments c JOIN users u ON u.id = c.user_id
     WHERE c.post_id = $1 ORDER BY c.created_at`,
    [postId],
  );
  res.json({ post: rows[0], comments: comments.rows });
}));

app.post('/freeboardwrite', wrap(async (req, res) => {
  const { title, content, user_id: userId } = req.body ?? {};
  if (!title || !content || !userId) {
    return res.status(400).json({ message: '제목, 내용, 작성자 정보가 필요합니다.' });
  }
  const { rows } = await db.query(
    'INSERT INTO posts (user_id, title, content) VALUES ($1, $2, $3) RETURNING id',
    [Number(userId), title, content],
  );
  res.status(201).json({ message: '게시글 등록 성공', id: rows[0].id });
}));

app.post('/freeboardcomment', wrap(async (req, res) => {
  const postId = Number(req.body?.post_id);
  const userId = Number(req.body?.user_id);
  const content = String(req.body?.content ?? '').trim();
  if (!postId || !userId || !content) {
    return res.status(400).json({ message: '게시글, 작성자, 내용이 필요합니다.' });
  }
  const { rows } = await db.query(
    `WITH c AS (INSERT INTO comments (post_id, user_id, content) VALUES ($1, $2, $3) RETURNING *)
     SELECT c.id, c.content, u.name AS author, ${kst('c.created_at')} AS created_at FROM c JOIN users u ON u.id = c.user_id`,
    [postId, userId, content],
  );
  res.status(201).json({ message: '댓글 등록 성공', comment: rows[0] });
}));

// ───────────── 출결 ─────────────

// 날짜를 안 주면 한국 시간 기준 오늘
const KST_TODAY = `(now() AT TIME ZONE 'Asia/Seoul')::date`;
const ATTENDANCE_STATUSES = ['출석', '지각', '결석'];

// 선생님: 소속 학원
app.get('/teacher/academy', wrap(async (req, res) => {
  const { rows } = await db.query(
    `SELECT a.id AS academy_id, a.name AS academy_name, a.address
     FROM academy_teachers t JOIN academies a ON a.id = t.academy_id WHERE t.teacher_id = $1`,
    [Number(req.query.teacher_id)],
  );
  if (!rows.length) return res.status(404).json({ message: '소속 학원이 없습니다.' });
  res.json(rows[0]);
}));

// 선생님: 소속 학원 수강생 목록 + 해당 날짜 출결 상태
app.get('/teacher/students', wrap(async (req, res) => {
  const { rows: [t] } = await db.query(
    'SELECT academy_id FROM academy_teachers WHERE teacher_id = $1', [Number(req.query.teacher_id)]);
  if (!t) return res.status(404).json({ message: '소속 학원이 없습니다.' });
  const { rows } = await db.query(
    `SELECT u.id, u.name, u.phone_number, att.status, d.date
     FROM enrollments e
     JOIN users u ON u.id = e.student_id
     CROSS JOIN (SELECT COALESCE($2::date, ${KST_TODAY}) AS date) d
     LEFT JOIN attendance att ON att.student_id = u.id AND att.academy_id = e.academy_id AND att.date = d.date
     WHERE e.academy_id = $1 ORDER BY u.name`,
    [t.academy_id, req.query.date || null],
  );
  res.json({ academy_id: t.academy_id, students: rows.map(({ date, ...s }) => s) });
}));

// 선생님: 출결 체크 (status 를 비우면 체크 취소)
app.post('/attendance', wrap(async (req, res) => {
  const teacherId = Number(req.body?.teacher_id);
  const studentId = Number(req.body?.student_id);
  const status = req.body?.status || null;
  const date = req.body?.date || null;
  if (status && !ATTENDANCE_STATUSES.includes(status)) {
    return res.status(400).json({ message: `status 는 ${ATTENDANCE_STATUSES.join('/')} 중 하나여야 합니다.` });
  }
  const { rows: [t] } = await db.query(
    `SELECT t.academy_id FROM academy_teachers t
     JOIN enrollments e ON e.academy_id = t.academy_id AND e.student_id = $2
     WHERE t.teacher_id = $1`,
    [teacherId, studentId],
  );
  if (!t) return res.status(403).json({ message: '내 학원에 등록된 학생이 아닙니다.' });
  if (!status) {
    await db.query(
      `DELETE FROM attendance WHERE student_id = $1 AND academy_id = $2 AND date = COALESCE($3::date, ${KST_TODAY})`,
      [studentId, t.academy_id, date],
    );
    return res.json({ message: '출결 체크를 취소했습니다.' });
  }
  await db.query(
    `INSERT INTO attendance (student_id, academy_id, date, status, checked_by)
     VALUES ($1, $2, COALESCE($3::date, ${KST_TODAY}), $4, $5)
     ON CONFLICT (student_id, academy_id, date)
     DO UPDATE SET status = EXCLUDED.status, checked_by = EXCLUDED.checked_by, checked_at = now()`,
    [studentId, t.academy_id, date, status, teacherId],
  );
  res.json({ message: `${status} 처리했습니다.` });
}));

// 학생/학부모: 해당 날짜 출결 (없으면 status: null)
app.get('/attendance', wrap(async (req, res) => {
  const { rows } = await db.query(
    `SELECT att.status, a.name AS academy_name, att.checked_at
     FROM attendance att JOIN academies a ON a.id = att.academy_id
     WHERE att.student_id = $1 AND att.date = COALESCE($2::date, ${KST_TODAY})
     ORDER BY att.checked_at DESC LIMIT 1`,
    [Number(req.query.student_id), req.query.date || null],
  );
  res.json(rows[0] ?? { status: null });
}));

// ─────────────

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ message: '서버 오류가 발생했습니다.' });
});

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => console.log(`출석체크 백엔드 실행 중: http://localhost:${port}`));
