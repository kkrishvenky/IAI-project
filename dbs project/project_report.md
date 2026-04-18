# Online Multiple-Choice Test Management System
### Database Systems Lab — Mini Project Report

**Student Name:** ___________________________
**Register Number:** ___________________________
**Subject:** Database Systems Lab
**Submitted To:** ___________________________
**Date:** March 2026

---

## 1. Abstract

This project presents the design and implementation of an **Online Multiple-Choice Test Management System** using MySQL as the database backend and Python Flask as the web application framework. The system supports two user roles — Admin and Student — with role-based access control. Admins can manage a question bank, create timed tests, and view analytics dashboards. Students can take tests and view their results. The database design emphasizes normalization, relational integrity, and efficient querying through stored procedures, user-defined functions, triggers, views, indexes, and complex analytical queries.

---

## 2. Introduction

Online assessment systems have become essential in modern education. This project simulates a real-world test management platform with a robust backend database. The primary goals are:

- Design a normalized relational database schema for test management
- Implement stored procedures and functions for business logic
- Use triggers to enforce data integrity and maintain an audit trail
- Demonstrate complex SQL queries including window functions, CTEs, and subqueries
- Connect the database to a live Flask web application

---

## 3. Technology Stack

| Layer | Technology |
|-------|-----------|
| Database | MySQL 8.0 |
| Backend | Python 3.x + Flask |
| ORM/Connector | PyMySQL |
| Frontend | HTML5, CSS3, JavaScript |
| Authentication | Werkzeug (bcrypt password hashing) |
| Templating | Jinja2 |

---

## 4. ER Diagram

*(See attached ER Diagram image — er_diagram_mcq.png)*

The system consists of **8 entities** with the following relationships:

- **USERS** creates **QUESTIONS** (1:M)
- **USERS** creates **TESTS** (1:M)
- **USERS** takes **STUDENT_TESTS** (1:M)
- **TESTS** contains **QUESTIONS** via **TEST_QUESTIONS** (M:N → junction table)
- **QUESTIONS** has **OPTIONS** (1:M)
- **STUDENT_TESTS** has **STUDENT_ANSWERS** (1:M)
- **STUDENT_TESTS** logged in **SCORE_AUDIT** (1:M)
- **OPTIONS** selected in **STUDENT_ANSWERS** (1:M)

---

## 5. Relational Schema

```
users(user_id PK, username, email UNIQUE, password, role, created_date)

questions(question_id PK, question_text, subject, difficulty_level,
          created_by FK→users, created_date)

options(option_id PK, question_id FK→questions, option_text, is_correct)

tests(test_id PK, test_name, description, duration_minutes,
      created_by FK→users, created_date, is_active)

test_questions(test_question_id PK, test_id FK→tests,
               question_id FK→questions, UNIQUE(test_id, question_id))

student_tests(student_test_id PK, student_id FK→users, test_id FK→tests,
              score, total_questions, attempt_date)

student_answers(answer_id PK, student_test_id FK→student_tests,
                question_id FK→questions,
                selected_option_id FK→options, is_correct)

score_audit(audit_id PK, student_test_id FK→student_tests,
            old_score, new_score, changed_at)
```

**Normalization:** The schema is in **3NF**. All attributes are atomic (1NF), there are no partial dependencies (2NF), and there are no transitive dependencies (3NF).

---

## 6. Database Features Implemented

### 6.1 Indexes

```sql
CREATE INDEX idx_tests_active    ON tests(is_active);
CREATE INDEX idx_questions_subject ON questions(subject);
CREATE INDEX idx_questions_diff  ON questions(difficulty_level);
```
Indexes improve query performance on frequently filtered columns.

---

### 6.2 Views

**View 1 — vw_student_results:** Joins student tests with user and test info for easy result display.
```sql
CREATE OR REPLACE VIEW vw_student_results AS
SELECT st.student_test_id, st.student_id, u.username AS student_name,
       u.email AS student_email, t.test_id, t.test_name,
       st.score, st.total_questions, st.attempt_date
FROM student_tests st
JOIN users u ON st.student_id = u.user_id
JOIN tests t ON st.test_id = t.test_id;
```

**View 2 — vw_question_difficulty_stats:** Shows success rate per subject and difficulty level.
```sql
CREATE OR REPLACE VIEW vw_question_difficulty_stats AS
SELECT q.subject, q.difficulty_level,
       COUNT(DISTINCT q.question_id) AS total_questions,
       COUNT(sa.answer_id) AS total_attempts,
       ROUND(AVG(sa.is_correct) * 100, 1) AS success_rate_pct
FROM questions q
LEFT JOIN student_answers sa ON q.question_id = sa.question_id
GROUP BY q.subject, q.difficulty_level;
```

---

### 6.3 Stored Procedures

**Procedure 1 — calculate_scores:** Marks answers, counts correct ones, and updates the student's score.
```sql
CREATE PROCEDURE calculate_scores(IN p_student_test_id INT)
BEGIN
    UPDATE student_answers sa
    JOIN options o ON sa.selected_option_id = o.option_id
    SET sa.is_correct = o.is_correct
    WHERE sa.student_test_id = p_student_test_id;
    
    UPDATE student_tests
    SET score = (SELECT COUNT(*) FROM student_answers
                 WHERE student_test_id = p_student_test_id AND is_correct = TRUE),
        total_questions = (SELECT COUNT(*) FROM student_answers
                           WHERE student_test_id = p_student_test_id)
    WHERE student_test_id = p_student_test_id;
END$$
```

**Procedure 2 — get_student_report:** Returns full test history for a student with PASS/FAIL verdict.

**Procedure 3 — deactivate_expired_tests:** Automatically deactivates tests older than 30 days.

---

### 6.4 User-Defined Functions

**Function 1 — get_avg_score(p_test_id):** Returns the average score for a given test.

**Function 2 — get_rank(p_student_id, p_test_id):** Returns the student's rank within a test.

---

### 6.5 Triggers

**Trigger 1 — trg_validate_answer (BEFORE INSERT on student_answers):**
Validates that the selected option belongs to the correct question. Raises a custom error if not.
```sql
CREATE TRIGGER trg_validate_answer
BEFORE INSERT ON student_answers
FOR EACH ROW
BEGIN
    DECLARE valid_count INT;
    SELECT COUNT(*) INTO valid_count FROM options
    WHERE option_id = NEW.selected_option_id AND question_id = NEW.question_id;
    IF valid_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid option for the given question.';
    END IF;
END$$
```

**Trigger 2 — trg_audit_score_change (AFTER UPDATE on student_tests):**
Automatically logs any score change into the `score_audit` table.
```sql
CREATE TRIGGER trg_audit_score_change
AFTER UPDATE ON student_tests
FOR EACH ROW
BEGIN
    IF OLD.score != NEW.score THEN
        INSERT INTO score_audit (student_test_id, old_score, new_score, changed_at)
        VALUES (NEW.student_test_id, OLD.score, NEW.score, NOW());
    END IF;
END$$
```

---

## 7. SQL Queries

### 7.1 Basic Queries

```sql
-- SELECT with WHERE
SELECT * FROM users WHERE role = 'Student' LIMIT 10;

-- INSERT
INSERT INTO questions (question_text, subject, difficulty_level, created_by)
VALUES ('What is a Primary Key?', 'Database Systems', 'Easy', 1);

-- UPDATE
UPDATE tests SET is_active = FALSE WHERE test_id = 1;

-- JOIN (3 tables)
SELECT t.test_name, q.question_text
FROM tests t
JOIN test_questions tq ON t.test_id = tq.test_id
JOIN questions q ON tq.question_id = q.question_id LIMIT 10;

-- GROUP BY with HAVING
SELECT subject, COUNT(*) AS num_questions
FROM questions
GROUP BY subject HAVING num_questions >= 10;

-- View usage
SELECT * FROM vw_student_results LIMIT 10;
```

### 7.2 Complex Queries

```sql
-- 1. Window Function: Top 3 students per test using DENSE_RANK
SELECT test_id, test_name, student_name, score, rank_num
FROM (
    SELECT v.test_id, v.test_name, v.student_name, v.score,
           DENSE_RANK() OVER (PARTITION BY v.test_id ORDER BY v.score DESC) AS rank_num
    FROM vw_student_results v
) ranked
WHERE rank_num <= 3;

-- 2. Subquery: Questions never answered correctly
SELECT q.question_id, q.question_text FROM questions q
WHERE q.question_id NOT IN (
    SELECT sa.question_id FROM student_answers sa WHERE sa.is_correct = TRUE
);

-- 3. CTE: Tests with average score below 50%
WITH TestAverages AS (
    SELECT test_id, AVG(score) AS avg_score, AVG(total_questions) AS avg_total
    FROM student_tests GROUP BY test_id
)
SELECT t.test_name, ta.avg_score FROM TestAverages ta
JOIN tests t ON ta.test_id = t.test_id
WHERE (ta.avg_score / NULLIF(ta.avg_total, 0)) < 0.5;

-- 4. NOT EXISTS: Tests with no questions assigned
SELECT test_name FROM tests t
WHERE NOT EXISTS (SELECT 1 FROM test_questions tq WHERE tq.test_id = t.test_id);

-- 5. EXCEPT: Students who attempted all active tests
SELECT u.user_id, u.username FROM users u
WHERE u.role = 'Student' AND NOT EXISTS (
    SELECT t.test_id FROM tests t WHERE t.is_active = TRUE
    EXCEPT
    SELECT st.test_id FROM student_tests st WHERE st.student_id = u.user_id
);
```

### 7.3 Transaction Example

```sql
START TRANSACTION;
    UPDATE tests SET is_active = FALSE WHERE test_id = 1;
    INSERT INTO score_audit (student_test_id, old_score, new_score, changed_at)
    SELECT student_test_id, score, score, NOW() FROM student_tests WHERE test_id = 1;
COMMIT;
```

---

## 8. Database Connectivity

Flask connects to MySQL using the **PyMySQL** library. A connection is established per HTTP request and stored in Flask's `g` application context object, then closed automatically at the end of each request.

```python
DB_CONFIG = {
    'host': 'localhost', 'user': 'root',
    'password': '****', 'database': 'mcq_db',
    'cursorclass': pymysql.cursors.DictCursor
}

def get_db():
    if 'db' not in g:
        g.db = pymysql.connect(**DB_CONFIG)
    return g.db
```

Stored procedures are called from Flask using:
```python
cur.execute("CALL calculate_scores(%s)", (student_test_id,))
```

---

## 9. System Features

| Feature | Description |
|---------|-------------|
| Role-Based Access Control | Admin and Student roles with separate dashboards |
| Question Bank | CRUD operations for questions with 4 options each |
| Test Engine | Timed tests with option shuffling and server-side enforcement |
| Score Calculation | Automated via stored procedure `calculate_scores` |
| Audit Trail | Score changes automatically logged by trigger |
| CSV Export | Student reports exportable as CSV |
| Analytics Dashboard | Charts for subject distribution, difficulty, top performers |
| Option Validation | Trigger prevents invalid option-question combinations |

---

## 10. Conclusion

This project successfully demonstrates the application of core database concepts in a real-world scenario. The system implements all major DBS concepts including normalized schema design, stored procedures, user-defined functions, triggers, views, indexes, complex queries (window functions, CTEs, subqueries), transactions, and secure database connectivity from a web application. The working Flask application validates that all database features function correctly end-to-end.

---

*End of Report*
