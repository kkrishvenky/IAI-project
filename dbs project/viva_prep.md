# 🎓 Viva Preparation Sheet — MCQ Test Management System

---

## 🔷 Section 1: General / Project Overview

**Q1. What is your project about?**
> My project is an Online Multiple-Choice Test Management System built using Python Flask and MySQL. It has two roles — Admin and Student. Admins can create questions and tests; students can take timed tests and view their results. The backend uses stored procedures, triggers, views, and complex queries.

**Q2. What is your tech stack?**
> - **Backend:** Python Flask
> - **Database:** MySQL
> - **Frontend:** HTML, CSS, JavaScript (Jinja2 templating)
> - **Libraries:** PyMySQL, Werkzeug (password hashing)

---

## 🔷 Section 2: Schema & ER Design

**Q3. How many tables do you have and why?**
> 8 tables: `users`, `questions`, `options`, `tests`, `test_questions`, `student_tests`, `student_answers`, `score_audit`. Each table represents a distinct entity to avoid redundancy and follow normalization.

**Q4. Is your database normalized? Which normal form?**
> Yes, it is in **3NF (Third Normal Form)**:
> - 1NF: All attributes are atomic, no repeating groups.
> - 2NF: No partial dependencies (all non-key attributes fully depend on the whole primary key).
> - 3NF: No transitive dependencies — e.g., student score is in `student_tests`, not duplicated in `student_answers`.

**Q5. Why is `test_questions` a separate table?**
> Because Tests and Questions have a **Many-to-Many** relationship — one test can have many questions, and one question can appear in many tests. The `test_questions` table is the **junction/bridge table** that resolves this.

**Q6. What is the purpose of `score_audit`?**
> It's an audit trail table populated automatically by a trigger whenever a student's score is updated. It stores old and new scores with a timestamp — useful for detecting data tampering or errors.

---

## 🔷 Section 3: Stored Procedures & Functions

**Q7. What is the difference between a Stored Procedure and a Function?**

| | Procedure | Function |
|---|---|---|
| Returns | Nothing (or via OUT param) | Always returns a value |
| Can call DML? | Yes | Yes (with restrictions) |
| Called with | `CALL proc()` | Used in SELECT/expressions |
| Use case | Perform actions | Compute and return a value |

**Q8. Explain your `calculate_scores` procedure.**
> It takes a `student_test_id` as input. It:
> 1. Updates `is_correct` in `student_answers` by joining with `options`
> 2. Counts total questions answered
> 3. Counts correct answers
> 4. Updates `student_tests` with `score` and `total_questions`
> This also triggers the audit trigger automatically.

**Q9. Explain your `get_student_report` procedure.**
> Takes a `student_id` and returns all test attempts including test name, score, total questions, attempt date, percentage, and PASS/FAIL verdict.

**Q10. What does `get_avg_score` function do?**
> Takes a `test_id` and returns the average score across all student attempts for that test. Uses `IFNULL` to return 0 if no attempts exist.

**Q11. What does `get_rank` function do?**
> Returns a student's rank in a specific test by counting how many others scored higher, then adding 1.

---

## 🔷 Section 4: Triggers

**Q12. What is a trigger? When does yours fire?**
> A trigger automatically executes on INSERT, UPDATE, or DELETE events.
> - `trg_validate_answer` — **BEFORE INSERT** on `student_answers`. Validates that the selected option belongs to the question. Raises an error using `SIGNAL` if not.
> - `trg_audit_score_change` — **AFTER UPDATE** on `student_tests`. If the score changed, inserts a record into `score_audit`.

**Q13. What is SIGNAL SQLSTATE in your trigger?**
> `SIGNAL SQLSTATE '45000'` raises a custom user-defined error from inside a trigger or procedure. It stops the operation and sends an error message back to the application.

---

## 🔷 Section 5: Views

**Q14. What is a View and why did you use it?**
> A view is a virtual table based on a SELECT query. It doesn't store data — it's computed on the fly.
> - `vw_student_results` — joins `student_tests`, `users`, and `tests` for a clean result set.
> - `vw_question_difficulty_stats` — shows success rates per subject and difficulty level.

**Q15. What is the advantage of using views?**
> - Simplifies complex queries (write once, reuse many times)
> - Provides abstraction (hides table structure)
> - Improves security by limiting what data is exposed

---

## 🔷 Section 6: Complex Queries

**Q16. Explain your window function query.**
> Uses `DENSE_RANK() OVER (PARTITION BY test_id ORDER BY score DESC)` to rank students within each test. `DENSE_RANK` doesn't skip numbers for ties.

**Q17. What is a CTE (Common Table Expression)?**
> A CTE is a temporary named result defined with the `WITH` keyword. My CTE `TestAverages` computes average scores per test; the outer query then filters tests below 50% average.

**Q18. Explain the NOT EXISTS query.**
> Finds tests with no questions assigned. `NOT EXISTS` returns true if the subquery returns no rows — more efficient than `NOT IN` when NULLs may be present.

**Q19. What is EXCEPT in your query?**
> `EXCEPT` returns rows from the first query not in the second. I use it to find students who attempted ALL active tests.

---

## 🔷 Section 7: Transactions & Indexes

**Q20. What is a Transaction? Why is COMMIT/ROLLBACK important?**
> A transaction groups SQL statements into one atomic unit — either all succeed (COMMIT) or none take effect (ROLLBACK). Ensures data consistency.

**Q21. Why did you add indexes?**
> Indexes speed up SELECT queries:
> - `idx_tests_active` on `tests(is_active)` — filters active tests
> - `idx_questions_subject` on `questions(subject)` — subject filtering
> - `idx_questions_diff` on `questions(difficulty_level)` — difficulty filtering

---

## 🔷 Section 8: DB Connectivity

**Q22. How does Flask connect to MySQL?**
> Using `PyMySQL`. Connection is created per request using Flask's `g` object and closed automatically via `@app.teardown_appcontext`.

**Q23. What is the role of `g` in Flask?**
> `g` is Flask's per-request global context. Stores the DB connection for one HTTP request's lifetime. New connection per request, closed when request ends.

---

## 🔷 Section 9: Security

**Q24. How are passwords stored?**
> Hashed using Werkzeug's `generate_password_hash` (bcrypt-based). Plain text passwords are never stored.

**Q25. How do you prevent unauthorized access?**
> Using `@admin_required` and `@student_required` decorators that check `session['role']` before allowing access to any protected route.
