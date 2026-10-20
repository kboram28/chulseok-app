const { Pool, types } = require('pg');

// BIGINT(user id)를 문자열이 아닌 숫자로 받기 — 앱이 id를 int로 다룸
types.setTypeParser(types.builtins.INT8, (v) => Number(v));
// DATE는 'YYYY-MM-DD' 문자열 그대로 (앱에서 DateTime.parse 사용)
types.setTypeParser(types.builtins.DATE, (v) => v);

if (!process.env.DATABASE_URL) {
  console.error('DATABASE_URL 환경변수가 필요합니다. .env.example 참고');
  process.exit(1);
}

const isLocal = /localhost|127\.0\.0\.1/.test(process.env.DATABASE_URL);

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isLocal ? false : { rejectUnauthorized: false },
});

module.exports = { pool, query: (text, params) => pool.query(text, params) };
