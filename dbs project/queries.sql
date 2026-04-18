USE mcq_db;

-- ---------------------------------------------------------
-- BASIC QUERIES
-- ---------------------------------------------------------

-- 1. SELECT
SELECT * FROM users WHERE role = 'Student' LIMIT 10;

-- 2. INSERT
INSERT INTO questions (question_text, subject, difficulty_level, created_by)
VALUES ('What is a Primary Key?', 'Database Systems', 'Easy', 1);

-- 3. UPDATE
UPDATE tests SET is_active = FALSE WHERE test_id = 1;

-- 4. DELETE
-- (Disabled to prevent deleting demo data accidentally)
-- DELETE FROM questions WHERE question_id = 9999; 

-- 5. JOIN
SELECT t.test_name, q.question_text
FROM tests t
JOIN test_questions tq ON t.test_id = tq.test_id
JOIN questions q ON tq.question_id = q.question_id
LIMIT 10;

-- 6. GROUP BY & HAVING
SELECT subject, COUNT(*) AS num_questions
FROM questions
GROUP BY subject
HAVING num_questions >= 10;

-- 7. ORDER BY
SELECT username, email FROM users WHERE role = 'Student' ORDER BY username ASC LIMIT 10;

-- 8. VIEW selection
SELECT * FROM vw_student_results LIMIT 10;

-- ---------------------------------------------------------
-- COMPLEX QUERIES
-- ---------------------------------------------------------

-- 1. Top 3 students per test (using Window Functions / Subqueries)
SELECT test_id, test_name, student_name, score, rank_num
FROM (
    SELECT 
        v.test_id, v.test_name, v.student_name, v.score,
        DENSE_RANK() OVER (PARTITION BY v.test_id ORDER BY v.score DESC) as rank_num
    FROM vw_student_results v
) ranked
WHERE rank_num <= 3;

-- 2. Questions never answered correctly
SELECT q.question_id, q.question_text
FROM questions q
WHERE q.question_id NOT IN (
    SELECT sa.question_id
    FROM student_answers sa
    WHERE sa.is_correct = TRUE
)
LIMIT 10;

-- 3. Average score per subject percentage
SELECT q.subject, (AVG(sa.is_correct) * 100) AS success_rate_percentage
FROM student_answers sa
JOIN questions q ON sa.question_id = q.question_id
GROUP BY q.subject;

-- 4. Students who attempted all active tests
SELECT u.user_id, u.username
FROM users u
WHERE u.role = 'Student' AND NOT EXISTS (
    SELECT t.test_id FROM tests t WHERE t.is_active = TRUE
    EXCEPT
    SELECT st.test_id FROM student_tests st WHERE st.student_id = u.user_id
);

-- 5. WITH/CTE query for weak tests with average below threshold (e.g. below 50%)
WITH TestAverages AS (
    SELECT test_id, AVG(score) as avg_score, AVG(total_questions) as avg_total
    FROM student_tests
    GROUP BY test_id
)
SELECT t.test_name, ta.avg_score, ta.avg_total
FROM TestAverages ta
JOIN tests t ON ta.test_id = t.test_id
WHERE (ta.avg_score / NULLIF(ta.avg_total, 0)) < 0.5;

-- 6. Query using nested subquery: Find the student who took the most tests
SELECT username, email 
FROM users 
WHERE user_id = (
    SELECT student_id 
    FROM student_tests 
    GROUP BY student_id 
    ORDER BY COUNT(test_id) DESC 
    LIMIT 1
);

-- 7. Query using NOT EXISTS: Tests that have no questions assigned yet
SELECT test_name
FROM tests t
WHERE NOT EXISTS (
    SELECT 1 FROM test_questions tq WHERE tq.test_id = t.test_id
);

-- 8. Query using aggregate functions across multiple joins:
-- Total questions, total participants, and average score for each Admin's created tests.
SELECT 
    u.username AS admin_name,
    COUNT(DISTINCT t.test_id) AS total_tests_created,
    COUNT(DISTINCT tq.question_id) AS total_questions_in_tests,
    COUNT(DISTINCT st.student_id) AS total_participants_reached,
    AVG(st.score) AS average_score_across_tests
FROM users u
LEFT JOIN tests t ON u.user_id = t.created_by
LEFT JOIN test_questions tq ON t.test_id = tq.test_id
LEFT JOIN student_tests st ON t.test_id = st.test_id
WHERE u.role = 'Admin'
GROUP BY u.user_id, u.username;

-- ---------------------------------------------------------
-- SECOND VIEW
-- ---------------------------------------------------------

-- View: Question difficulty breakdown with success rate per subject
CREATE OR REPLACE VIEW vw_question_difficulty_stats AS
SELECT 
    q.subject,
    q.difficulty_level,
    COUNT(DISTINCT q.question_id)           AS total_questions,
    COUNT(sa.answer_id)                      AS total_attempts,
    SUM(sa.is_correct)                       AS correct_attempts,
    ROUND(AVG(sa.is_correct) * 100, 1)       AS success_rate_pct
FROM questions q
LEFT JOIN student_answers sa ON q.question_id = sa.question_id
GROUP BY q.subject, q.difficulty_level
ORDER BY q.subject, FIELD(q.difficulty_level, 'Easy', 'Medium', 'Hard');

-- Use the second view
SELECT * FROM vw_question_difficulty_stats;

-- ---------------------------------------------------------
-- TRANSACTION EXAMPLE
-- ---------------------------------------------------------

-- Safely deactivate a test and log the action atomically
START TRANSACTION;

    UPDATE tests SET is_active = FALSE WHERE test_id = 1;

    INSERT INTO score_audit (student_test_id, old_score, new_score, changed_at)
    SELECT student_test_id, score, score, NOW()
    FROM student_tests WHERE test_id = 1;

COMMIT;
-- ROLLBACK;  -- Uncomment to undo

-- ---------------------------------------------------------
-- QUERY OPTIMIZATION (EXPLAIN)
-- ---------------------------------------------------------

-- Explain the execution plan for the top performers query
EXPLAIN SELECT u.username, SUM(st.score) AS total_score
FROM student_tests st
JOIN users u ON st.student_id = u.user_id
GROUP BY st.student_id, u.username
ORDER BY total_score DESC
LIMIT 10;
