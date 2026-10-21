// DB 초기화: 테이블 생성 + 초기 데이터 입력
// 사용법: npm run db:init            (데이터가 이미 있으면 건너뜀)
//        npm run db:init -- --reset (모든 테이블 삭제 후 다시 생성)

const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const { pool } = require('../src/db');
const {
  regions, academies, demoUsers, extraStudents, demoNotices, demoSchedules, demoQuestions, demoPosts, demoComments,
} = require('../db/seed-data');

async function main() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    if (process.argv.includes('--reset')) {
      console.log('기존 테이블 삭제');
      await client.query(`DROP TABLE IF EXISTS verification_codes, comments, posts, family, notices, questions, schedules, attendance,
                          academy_teachers, enrollments, academies, users, subregions, regions CASCADE`);
    }

    await client.query(fs.readFileSync(path.join(__dirname, '../db/schema.sql'), 'utf8'));
    console.log('테이블 생성 완료');

    const { rows } = await client.query('SELECT count(*)::int AS n FROM regions');
    if (rows[0].n > 0) {
      await linkDemoTeacher(client);
      console.log('초기 데이터가 이미 있어 건너뜁니다. (--reset 으로 재생성 가능)');
      await client.query('COMMIT');
      return;
    }

    const regionIds = {};
    for (const [name, subs] of Object.entries(regions)) {
      const r = await client.query('INSERT INTO regions (name) VALUES ($1) RETURNING id', [name]);
      regionIds[name] = r.rows[0].id;
      for (const sub of subs) {
        await client.query('INSERT INTO subregions (region_id, name) VALUES ($1, $2)', [r.rows[0].id, sub]);
      }
    }

    const academyIds = [];
    for (const a of academies) {
      const r = await client.query(
        `INSERT INTO academies (name, category, address, contact_number, latitude, longitude)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`, a);
      academyIds.push(r.rows[0].id);
    }

    const hash = await bcrypt.hash('test1234', 10);
    const seoul = regionIds['서울특별시'];
    const gangnam = (await client.query(
      `SELECT id FROM subregions WHERE region_id = $1 AND name = '강남구'`, [seoul])).rows[0].id;
    for (const u of demoUsers) {
      await client.query(
        `INSERT INTO users (id, name, password_hash, phone_number, birthdate, gender, fields, role, region_id, subregion_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
        [u.id, u.name, hash, u.phone, u.birthdate, u.gender, u.fields, u.role, seoul, gangnam]);
    }
    const [student, parent] = demoUsers;
    await client.query('INSERT INTO family (parent_id, student_id) VALUES ($1, $2)', [parent.id, student.id]);
    await client.query('INSERT INTO enrollments (student_id, academy_id) VALUES ($1, $2)', [student.id, academyIds[0]]);

    const postIds = [];
    for (const p of demoPosts) {
      const r = await client.query(
        'INSERT INTO posts (user_id, title, content) VALUES ($1, $2, $3) RETURNING id',
        [demoUsers[p.userIdx].id, p.title, p.content]);
      postIds.push(r.rows[0].id);
    }
    for (const c of demoComments) {
      await client.query('INSERT INTO comments (post_id, user_id, content) VALUES ($1, $2, $3)',
        [postIds[c.postIdx], demoUsers[c.userIdx].id, c.content]);
    }
    await linkDemoTeacher(client);

    await client.query('COMMIT');
    console.log(`초기 데이터 입력 완료: 지역 ${Object.keys(regions).length}개, 학원 ${academies.length}개, 데모 계정 ${demoUsers.length}개`);
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
    await pool.end();
  }
}

// 데모 선생님을 데모 학생이 다니는 학원 소속으로 연결하고, 같은 학원에 추가 학생 등록 (이미 있으면 그대로)
async function linkDemoTeacher(client) {
  const [student, , teacher] = demoUsers;
  await client.query(
    `INSERT INTO academy_teachers (teacher_id, academy_id)
     SELECT $1, e.academy_id FROM enrollments e
     WHERE e.student_id = $2 AND EXISTS (SELECT 1 FROM users WHERE id = $1)
     ORDER BY e.created_at LIMIT 1
     ON CONFLICT (teacher_id) DO NOTHING`,
    [teacher.id, student.id]);

  const { rows: [t] } = await client.query('SELECT academy_id FROM academy_teachers WHERE teacher_id = $1', [teacher.id]);
  if (!t) return;
  const hash = await bcrypt.hash('test1234', 10);
  for (const u of extraStudents) {
    await client.query(
      `INSERT INTO users (id, name, password_hash, phone_number, birthdate, gender, fields, role)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) ON CONFLICT DO NOTHING`,
      [u.id, u.name, hash, u.phone, u.birthdate, u.gender, u.fields, u.role]);
    await client.query(
      'INSERT INTO enrollments (student_id, academy_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [u.id, t.academy_id]);
  }
  await seedAcademyBoard(client, t.academy_id, teacher.id);
}

// 데모 학원의 공지·일정·질문 (공지가 하나도 없을 때만)
async function seedAcademyBoard(client, academyId, teacherId) {
  const { rows: [n] } = await client.query('SELECT count(*)::int AS n FROM notices WHERE academy_id = $1', [academyId]);
  if (n.n > 0) return;
  for (const x of demoNotices) {
    await client.query('INSERT INTO notices (academy_id, teacher_id, title, content) VALUES ($1, $2, $3, $4)',
      [academyId, teacherId, x.title, x.content]);
  }
  for (const x of demoSchedules) {
    await client.query(
      `INSERT INTO schedules (academy_id, teacher_id, type, title, description, due_date)
       VALUES ($1, $2, $3, $4, $5, (now() AT TIME ZONE 'Asia/Seoul')::date + $6::int)`,
      [academyId, teacherId, x.type, x.title, x.description, x.daysFromToday]);
  }
  for (const x of demoQuestions) {
    await client.query(
      `INSERT INTO questions (academy_id, user_id, title, content, answer, answered_by, answered_at)
       VALUES ($1, $2, $3, $4, $5::text, CASE WHEN $5::text IS NULL THEN NULL ELSE $6::bigint END,
               CASE WHEN $5::text IS NULL THEN NULL ELSE now() END)`,
      [academyId, demoUsers[x.askerIdx].id, x.title, x.content, x.answer, teacherId]);
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
