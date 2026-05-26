CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- для gen_random_uuid()

CREATE TABLE users (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT NOT NULL,
    email      TEXT NOT NULL UNIQUE,
    password   TEXT NOT NULL,             -- bcrypt-хеш
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE houses (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- связь многие-ко-многим: пользователь может быть в нескольких домах
CREATE TABLE house_members (
    house_id   UUID NOT NULL REFERENCES houses(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
    joined_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (house_id, user_id)
);

CREATE TYPE task_priority AS ENUM ('LOW', 'MEDIUM', 'HIGH');

CREATE TABLE tasks (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    house_id    UUID NOT NULL REFERENCES houses(id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    done        BOOLEAN NOT NULL DEFAULT FALSE,
    priority    task_priority NOT NULL DEFAULT 'MEDIUM',
    assignee_id UUID REFERENCES users(id) ON DELETE SET NULL,
    due_date    TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- индексы для частых запросов
CREATE INDEX idx_tasks_house_id    ON tasks(house_id);
CREATE INDEX idx_tasks_assignee_id ON tasks(assignee_id);
CREATE INDEX idx_tasks_done        ON tasks(done);

-- триггер: автоматически обновляет updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();