CREATE DATABASE IF NOT EXISTS mcq_db;
USE mcq_db;

DROP TABLE IF EXISTS score_audit;
DROP TABLE IF EXISTS student_answers;
DROP TABLE IF EXISTS student_tests;
DROP TABLE IF EXISTS test_questions;
DROP TABLE IF EXISTS tests;
DROP TABLE IF EXISTS options;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('Admin','Student') NOT NULL,
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE questions (
    question_id INT PRIMARY KEY AUTO_INCREMENT,
    question_text TEXT NOT NULL,
    subject VARCHAR(100) NOT NULL,
    difficulty_level ENUM('Easy','Medium','Hard') NOT NULL,
    created_by INT NOT NULL,
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(user_id)
);

CREATE TABLE options (
    option_id INT PRIMARY KEY AUTO_INCREMENT,
    question_id INT NOT NULL,
    option_text VARCHAR(255) NOT NULL,
    is_correct BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (question_id) REFERENCES questions(question_id) ON DELETE CASCADE
);

CREATE TABLE tests (
    test_id INT PRIMARY KEY AUTO_INCREMENT,
    test_name VARCHAR(150) NOT NULL,
    description TEXT,
    duration_minutes INT NOT NULL,
    created_by INT NOT NULL,
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (created_by) REFERENCES users(user_id)
);

CREATE TABLE test_questions (
    test_question_id INT PRIMARY KEY AUTO_INCREMENT,
    test_id INT NOT NULL,
    question_id INT NOT NULL,
    FOREIGN KEY (test_id) REFERENCES tests(test_id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(question_id) ON DELETE CASCADE,
    UNIQUE(test_id, question_id)
);

CREATE TABLE student_tests (
    student_test_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    test_id INT NOT NULL,
    score DECIMAL(5,2) DEFAULT 0,
    total_questions INT DEFAULT 0,
    attempt_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES users(user_id),
    FOREIGN KEY (test_id) REFERENCES tests(test_id)
);

CREATE TABLE student_answers (
    answer_id INT PRIMARY KEY AUTO_INCREMENT,
    student_test_id INT NOT NULL,
    question_id INT NOT NULL,
    selected_option_id INT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (student_test_id) REFERENCES student_tests(student_test_id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(question_id),
    FOREIGN KEY (selected_option_id) REFERENCES options(option_id)
);

CREATE TABLE score_audit (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    student_test_id INT NOT NULL,
    old_score DECIMAL(5,2),
    new_score DECIMAL(5,2),
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_tests_active ON tests(is_active);
CREATE INDEX idx_questions_subject ON questions(subject);
CREATE INDEX idx_questions_diff ON questions(difficulty_level);

-- View: Student Test Results View
CREATE OR REPLACE VIEW vw_student_results AS
SELECT 
    st.student_test_id,
    st.student_id,
    u.username AS student_name,
    u.email AS student_email,
    t.test_id,
    t.test_name,
    st.score,
    st.total_questions,
    st.attempt_date
FROM student_tests st
JOIN users u ON st.student_id = u.user_id
JOIN tests t ON st.test_id = t.test_id;
