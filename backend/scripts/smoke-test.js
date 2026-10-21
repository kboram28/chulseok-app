// 앱이 호출하는 순서대로 API 를 한 번씩 불러보는 점검 스크립트
// 사용법: 서버 실행 후 npm test   (다른 주소: API_BASE_URL=https://... npm test)

const BASE = process.env.API_BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
let failed = 0;

async function call(label, method, path, body, expectStatus) {
  const res = await fetch(BASE + path, {
    method,
    headers: body ? { 'Content-Type': 'application/json' } : {},
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data;
  try { data = JSON.parse(text); } catch { data = text; }
  const ok = res.status === expectStatus;
  if (!ok) failed++;
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${label} → ${res.status}${ok ? '' : ` (기대 ${expectStatus}) ${text.slice(0, 200)}`}`);
  return data;
}

(async () => {
  console.log(`대상 서버: ${BASE}\n`);
  await call('health', 'GET', '/health', null, 200);

  const regions = await call('지역 목록', 'GET', '/data?operation=getRegions', null, 200);
  const subs = await call('세부 지역', 'GET', `/data?operation=getSubregions&region_id=${regions[0].id}`, null, 200);

  const phone = '010' + String(Date.now()).slice(-8);
  await call('인증번호 발송', 'POST', '/sendVerificationCode', { phoneNumber: phone }, 200);
  await call('인증번호 틀림', 'POST', '/verifyCode', { phoneNumber: phone, enteredCode: '000000' }, 400);
  await call('인증번호 확인', 'POST', '/verifyCode', { phoneNumber: phone, enteredCode: '123456' }, 200);

  const created = await call('학생 회원가입', 'POST', '/data?operation=createUser', {
    name: '테스트학생', password: 'pw1234', birthdate: '2011-01-01', gender: '여성', fields: [2],
    role: '학생', phone_number: phone, region_id: String(regions[0].id), subregion_id: String(subs[0].id), id: '1234',
  }, 201);
  await call('중복 가입 거부', 'POST', '/data?operation=createUser', {
    name: 'x', password: 'x', role: '학생', phone_number: phone, id: '1111',
  }, 409);

  await call('로그인 실패', 'POST', '/data?operation=login', { phone_number: phone, password: 'wrong' }, 401);
  const login = await call('학생 로그인', 'POST', '/data?operation=login', { phone_number: phone, password: 'pw1234' }, 200);
  const studentId = login.user.id;
  if (typeof studentId !== 'number' || studentId !== created.id) { failed++; console.log('FAIL user.id 가 숫자가 아님/불일치'); }

  const academies = await call('주변 학원', 'GET', '/database?latitude=37.4979&longitude=127.0276', null, 200);
  await call('학원 등록 전 내 학원', 'GET', `/studentA?student_id=${studentId}`, null, 404);
  await call('학원 등록', 'POST', '/registerEnrollment', { studentId, academyId: academies[0].id }, 200);
  await call('학원 중복 등록', 'POST', '/registerEnrollment', { studentId, academyId: academies[0].id }, 409);
  await call('내 학원', 'GET', `/studentA?student_id=${studentId}`, null, 200);
  await call('지도 페이지', 'GET', `/kakaomap?address=${encodeURIComponent(academies[0].address)}&academyName=${encodeURIComponent(academies[0].name)}`, null, 200);

  const parent = await call('학부모 로그인', 'POST', '/data?operation=login', { phone_number: '010-3333-4444', password: 'test1234' }, 200);
  const parentId = parent.user.id;
  await call('자녀 코드 조회', 'POST', '/studentsearch?operation=getChildData', { code: String(studentId) }, 200);
  await call('없는 코드 조회', 'POST', '/studentsearch?operation=getChildData', { code: '1' }, 404);
  await call('자녀 등록', 'POST', '/studentsearch?operation=registerChild', { parentId, studentId: String(studentId) }, 200);
  await call('자녀 이름', 'GET', `/parentB?parent_id=${parentId}`, null, 200);
  await call('자녀 학원', 'GET', `/parentA?parent_id=${parentId}`, null, 200);

  const written = await call('글쓰기', 'POST', '/freeboardwrite', { title: '테스트 글', user_id: studentId, content: '내용' }, 201);
  const list = await call('게시판 목록', 'GET', `/freeboard?user_id=${studentId}`, null, 200);
  if (!list.posts.some((p) => p.id === written.id)) { failed++; console.log('FAIL 새 글이 목록에 없음'); }
  const detail = await call('게시글 상세', 'GET', `/freeboardA?postId=${written.id}`, null, 200);
  if (detail.post.views !== 1) { failed++; console.log('FAIL 조회수 증가 안 됨'); }
  const comment = await call('댓글 작성', 'POST', '/freeboardcomment', { post_id: written.id, user_id: studentId, content: '테스트 댓글' }, 201);
  if (comment.comment?.author !== '테스트학생') { failed++; console.log('FAIL 댓글 작성자 이름'); }
  const detail2 = await call('댓글 포함 상세', 'GET', `/freeboardA?postId=${written.id}`, null, 200);
  if (detail2.comments.length !== 1) { failed++; console.log('FAIL 댓글이 상세에 없음'); }

  // 선생님 출결 흐름
  const tPhone = '011' + String(Date.now()).slice(-8);
  await call('선생님 회원가입', 'POST', '/data?operation=createUser', {
    name: '테스트선생님', password: 'pw1234', role: '선생님', phone_number: tPhone, id: tPhone,
  }, 201);
  const teacher = await call('선생님 로그인', 'POST', '/data?operation=login', { phone_number: tPhone, password: 'pw1234' }, 200);
  const teacherId = teacher.user.id;
  await call('소속 학원 없음', 'GET', `/teacher/academy?teacher_id=${teacherId}`, null, 404);
  await call('소속 학원 등록', 'POST', '/registerEnrollment', { studentId: teacherId, academyId: academies[0].id }, 200);
  await call('소속 학원', 'GET', `/teacher/academy?teacher_id=${teacherId}`, null, 200);
  const roster = await call('수강생 목록', 'GET', `/teacher/students?teacher_id=${teacherId}`, null, 200);
  if (!roster.students.some((s) => s.id === studentId && s.status === null)) { failed++; console.log('FAIL 수강생 목록에 학생 없음'); }
  await call('오늘 출결 (체크 전)', 'GET', `/attendance?student_id=${studentId}`, null, 200);
  await call('출석 체크', 'POST', '/attendance', { teacher_id: teacherId, student_id: studentId, status: '지각' }, 200);
  await call('출석 변경', 'POST', '/attendance', { teacher_id: teacherId, student_id: studentId, status: '출석' }, 200);
  await call('잘못된 상태값', 'POST', '/attendance', { teacher_id: teacherId, student_id: studentId, status: '조퇴' }, 400);
  await call('다른 학원 학생 체크 거부', 'POST', '/attendance', { teacher_id: teacherId, student_id: 1, status: '출석' }, 403);
  const att = await call('오늘 출결 (학생)', 'GET', `/attendance?student_id=${studentId}`, null, 200);
  if (att.status !== '출석') { failed++; console.log('FAIL 출결 상태가 반영되지 않음'); }
  const roster2 = await call('수강생 목록 (체크 후)', 'GET', `/teacher/students?teacher_id=${teacherId}`, null, 200);
  if (roster2.students.find((s) => s.id === studentId)?.status !== '출석') { failed++; console.log('FAIL 목록에 출결 반영 안 됨'); }
  await call('출석 취소', 'POST', '/attendance', { teacher_id: teacherId, student_id: studentId, status: '' }, 200);

  // 공지사항
  await call('학생은 공지 작성 불가', 'POST', '/notices', { teacher_id: studentId, title: 'x', content: 'x' }, 403);
  const notice = await call('공지 작성', 'POST', '/notices', { teacher_id: teacherId, title: '테스트 공지', content: '내용' }, 201);
  const sNotices = await call('학생 공지 목록', 'GET', `/notices?user_id=${studentId}`, null, 200);
  if (!sNotices.some((n) => n.id === notice.id)) { failed++; console.log('FAIL 학생에게 공지가 안 보임'); }
  const pNotices = await call('학부모 공지 목록', 'GET', `/notices?user_id=${parentId}`, null, 200);
  if (!pNotices.some((n) => n.id === notice.id)) { failed++; console.log('FAIL 학부모에게 자녀 학원 공지가 안 보임'); }
  await call('공지 삭제', 'DELETE', `/notices/${notice.id}?teacher_id=${teacherId}`, null, 200);

  // 상담 및 질문
  const q = await call('질문 등록', 'POST', '/questions', { user_id: studentId, title: '테스트 질문', content: '질문 내용' }, 201);
  const tQs = await call('선생님 질문 목록', 'GET', `/questions?user_id=${teacherId}`, null, 200);
  if (tQs.find((x) => x.id === q.id)?.answer !== null) { failed++; console.log('FAIL 선생님 목록에 미답변 질문 없음'); }
  await call('답변 등록', 'POST', `/questions/${q.id}/answer`, { teacher_id: teacherId, answer: '테스트 답변' }, 200);
  const sQs = await call('학생 질문 목록', 'GET', `/questions?user_id=${studentId}`, null, 200);
  if (sQs.find((x) => x.id === q.id)?.answer !== '테스트 답변') { failed++; console.log('FAIL 학생에게 답변이 안 보임'); }
  await call('다른 학원 질문 답변 거부', 'POST', `/questions/${q.id}/answer`, { teacher_id: 1055556666, answer: 'x' }, 403);

  // 과제·시험 일정
  const in3days = new Date(Date.now() + 9 * 3600e3 + 3 * 86400e3).toISOString().slice(0, 10);
  await call('잘못된 일정 종류', 'POST', '/schedules', { teacher_id: teacherId, type: '숙제', title: 'x', due_date: in3days }, 400);
  const sch = await call('일정 등록', 'POST', '/schedules', { teacher_id: teacherId, type: '시험', title: '테스트 시험', description: '범위', due_date: in3days }, 201);
  const sSch = await call('학생 일정 목록', 'GET', `/schedules?user_id=${studentId}`, null, 200);
  if (sSch.find((x) => x.id === sch.id)?.days_left !== 3) { failed++; console.log('FAIL 일정 D-day 계산'); }
  await call('일정 삭제', 'DELETE', `/schedules/${sch.id}?teacher_id=${teacherId}`, null, 200);

  console.log(failed ? `\n실패 ${failed}건` : '\n모든 점검 통과');
  process.exit(failed ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
