-- Hardcoded the app username since couldn't figure out
-- a simple way to pull it from environment variables
ALTER DEFAULT PRIVILEGES GRANT ALL ON TABLES TO app;

DROP TABLE IF EXISTS migrations;

CREATE TABLE IF NOT EXISTS migrations (
    last_migration_date TIMESTAMP
);

INSERT INTO migrations (last_migration_date)
VALUES (NOW());

SELECT * FROM migrations;
