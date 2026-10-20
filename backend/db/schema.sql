-- 출석체크 앱 DB 스키마 (PostgreSQL)
-- 앱 코드가 주고받는 필드를 기준으로 재구성함

CREATE TABLE IF NOT EXISTS regions (
  id   SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS subregions (
  id        SERIAL PRIMARY KEY,
  region_id INTEGER NOT NULL REFERENCES regions(id) ON DELETE CASCADE,
  name      TEXT NOT NULL,
  UNIQUE (region_id, name)
);

-- id: 학생은 4자리 랜덤 숫자(학부모가 '자녀 코드'로 입력), 학부모/선생님은 휴대전화번호 숫자
CREATE TABLE IF NOT EXISTS users (
  id            BIGINT PRIMARY KEY,
  name          TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  phone_number  TEXT NOT NULL UNIQUE,
  birthdate     DATE,
  gender        TEXT,
  fields        INTEGER[] NOT NULL DEFAULT '{}',  -- 관심분야: 1 입시 및 보습, 2 외국어, 3 예체능, 4 검정 및 기타
  role          TEXT NOT NULL CHECK (role IN ('학생', '학부모', '선생님')),
  region_id     INTEGER REFERENCES regions(id),
  subregion_id  INTEGER REFERENCES subregions(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS academies (
  id             SERIAL PRIMARY KEY,
  name           TEXT NOT NULL,
  category       TEXT NOT NULL,  -- 입시 및 보습 / 외국어 / 예체능 / 검정 및 기타
  address        TEXT NOT NULL,
  contact_number TEXT,
  latitude       DOUBLE PRECISION NOT NULL,
  longitude      DOUBLE PRECISION NOT NULL
);

CREATE TABLE IF NOT EXISTS enrollments (
  student_id BIGINT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  academy_id INTEGER NOT NULL REFERENCES academies(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (student_id, academy_id)
);

CREATE TABLE IF NOT EXISTS family (
  parent_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  student_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (parent_id, student_id)
);

CREATE TABLE IF NOT EXISTS posts (
  id         SERIAL PRIMARY KEY,
  user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  content    TEXT NOT NULL,
  views      INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS comments (
  id         SERIAL PRIMARY KEY,
  post_id    INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    BIGINT  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content    TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS verification_codes (
  phone_number TEXT PRIMARY KEY,
  code         TEXT NOT NULL,
  expires_at   TIMESTAMPTZ NOT NULL
);
