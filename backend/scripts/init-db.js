// DB 초기화: 테이블 생성 + 초기 데이터 입력
// 사용법: npm run db:init            (데이터가 이미 있으면 건너뜀)
//        npm run db:init -- --reset (모든 테이블 삭제 후 다시 생성)

const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const { pool } = require('../src/db');
const { regions, academies, demoUsers, demoPosts, demoComments } = require('../db/seed-data');

async function main() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    if (process.argv.includes('--reset')) {
      console.log('기존 테이블 삭제');
      await client.query(`DROP TABLE IF EXISTS verification_codes, comments, posts, family, enrollments,
                          academies, users, subregions, regions CASCADE`);
    }

    await client.query(fs.readFileSync(path.join(__dirname, '../db/schema.sql'), 'utf8'));
    console.log('테이블 생성 완료');

    const { rows } = await client.query('SELECT count(*)::int AS n FROM regions');
    if (rows[0].n > 0) {
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

main().catch((e) => { console.error(e); process.exit(1); });
