USE mcq_db;

DELIMITER $$

-- 1. procedure get_student_report(p_student_id)
DROP PROCEDURE IF EXISTS get_student_report$$
CREATE PROCEDURE get_student_report(IN p_student_id INT)
BEGIN
    SELECT 
        st.student_test_id,
        t.test_name,
        st.score,
        st.total_questions,
        st.attempt_date,
        ROUND((st.score / NULLIF(st.total_questions, 0)) * 100, 1) AS score_pct,
        CASE 
            WHEN (st.score / NULLIF(st.total_questions, 0)) >= 0.5 THEN 'PASS'
            ELSE 'FAIL'
        END AS verdict
    FROM student_tests st
    JOIN tests t ON st.test_id = t.test_id
    WHERE st.student_id = p_student_id
    ORDER BY st.attempt_date DESC;
END$$

-- 2. procedure calculate_scores(p_student_test_id)
DROP PROCEDURE IF EXISTS calculate_scores$$
CREATE PROCEDURE calculate_scores(IN p_student_test_id INT)
BEGIN
    DECLARE total_qs INT;
    DECLARE correct_count INT;
    
    -- Update is_correct flag in student_answers based on options table
    UPDATE student_answers sa
    JOIN options o ON sa.selected_option_id = o.option_id
    SET sa.is_correct = o.is_correct
    WHERE sa.student_test_id = p_student_test_id;
    
    -- Count total questions in this test attempt
    SELECT COUNT(*) INTO total_qs
    FROM student_answers
    WHERE student_test_id = p_student_test_id;
    
    -- Count correct answers
    SELECT COUNT(*) INTO correct_count
    FROM student_answers
    WHERE student_test_id = p_student_test_id AND is_correct = TRUE;
    
    -- Update the student_tests record with the final score
    UPDATE student_tests
    SET score = correct_count,
        total_questions = total_qs
    WHERE student_test_id = p_student_test_id;
END$$

-- 3. procedure deactivate_expired_tests()
DROP PROCEDURE IF EXISTS deactivate_expired_tests$$
CREATE PROCEDURE deactivate_expired_tests()
BEGIN
    UPDATE tests
    SET is_active = FALSE
    WHERE created_date < DATE_SUB(NOW(), INTERVAL 30 DAY) AND is_active = TRUE;
END$$

-- 4. function get_avg_score(p_test_id)
DROP FUNCTION IF EXISTS get_avg_score$$
CREATE FUNCTION get_avg_score(p_test_id INT) RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE avg_score DECIMAL(5,2);
    SELECT AVG(score) INTO avg_score
    FROM student_tests
    WHERE test_id = p_test_id;
    RETURN IFNULL(avg_score, 0);
END$$

-- 5. function get_rank(p_student_id, p_test_id)
DROP FUNCTION IF EXISTS get_rank$$
CREATE FUNCTION get_rank(p_student_id INT, p_test_id INT) RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE student_rank INT;
    
    SELECT count(*) + 1 INTO student_rank
    FROM student_tests st1
    WHERE st1.test_id = p_test_id 
      AND st1.score > (
          SELECT COALESCE(MAX(score), -1) 
          FROM student_tests st2 
          WHERE st2.test_id = p_test_id AND st2.student_id = p_student_id
      );
      
    RETURN student_rank;
END$$


-- TRIGGERS
-- 1. BEFORE INSERT trigger on student_answers to validate selected option belongs to the question
DROP TRIGGER IF EXISTS trg_validate_answer$$
CREATE TRIGGER trg_validate_answer
BEFORE INSERT ON student_answers
FOR EACH ROW
BEGIN
    DECLARE valid_count INT;
    SELECT COUNT(*) INTO valid_count
    FROM options 
    WHERE option_id = NEW.selected_option_id AND question_id = NEW.question_id;
    
    IF valid_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid option for the given question.';
    END IF;
END$$

-- 2. AFTER UPDATE trigger on student_tests to log score changes into an audit table
DROP TRIGGER IF EXISTS trg_audit_score_change$$
CREATE TRIGGER trg_audit_score_change
AFTER UPDATE ON student_tests
FOR EACH ROW
BEGIN
    IF OLD.score != NEW.score THEN
        INSERT INTO score_audit (student_test_id, old_score, new_score, changed_at)
        VALUES (NEW.student_test_id, OLD.score, NEW.score, NOW());
    END IF;
END$$

DELIMITER ;
