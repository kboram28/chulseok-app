// npm test 가 만든 테스트 계정·게시글 삭제 (데모 데이터는 그대로)
// 사용법: npm run test:cleanup

const { pool } = require('../src/db');

(async () => {
  const posts = await pool.query(`DELETE FROM posts WHERE title = '테스트 글'`);
  const users = await pool.query(`DELETE FROM users WHERE name IN ('테스트학생', '테스트선생님')`);
  await pool.query('DELETE FROM verification_codes');
  console.log(`삭제: 게시글 ${posts.rowCount}개, 계정 ${users.rowCount}개`);
  await pool.end();
})().catch((e) => { console.error(e); process.exit(1); });
