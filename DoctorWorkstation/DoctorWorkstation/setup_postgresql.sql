-- Создание пользователя и базы данных
CREATE USER medical_user WITH PASSWORD 'medical_password';
CREATE DATABASE medical_system OWNER medical_user;

-- Подключение к базе данных
\c medical_system;

-- Предоставление прав
GRANT ALL PRIVILEGES ON DATABASE medical_system TO medical_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO medical_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO medical_user;
