# ER Diagram — Online MCQ Test Management System

## Visual Diagram

```mermaid
erDiagram
    USERS {
        int user_id PK
        varchar username
        varchar email
        varchar password
        enum role
        datetime created_date
    }
    QUESTIONS {
        int question_id PK
        text question_text
        varchar subject
        enum difficulty_level
        int created_by FK
        datetime created_date
    }
    OPTIONS {
        int option_id PK
        int question_id FK
        varchar option_text
        boolean is_correct
    }
    TESTS {
        int test_id PK
        varchar test_name
        text description
        int duration_minutes
        int created_by FK
        datetime created_date
        boolean is_active
    }
    TEST_QUESTIONS {
        int test_question_id PK
        int test_id FK
        int question_id FK
    }
    STUDENT_TESTS {
        int student_test_id PK
        int student_id FK
        int test_id FK
        decimal score
        int total_questions
        datetime attempt_date
    }
    STUDENT_ANSWERS {
        int answer_id PK
        int student_test_id FK
        int question_id FK
        int selected_option_id FK
        boolean is_correct
    }
    SCORE_AUDIT {
        int audit_id PK
        int student_test_id FK
        decimal old_score
        decimal new_score
        datetime changed_at
    }

    USERS ||--o{ QUESTIONS : "creates"
    USERS ||--o{ TESTS : "creates"
    USERS ||--o{ STUDENT_TESTS : "takes"
    TESTS ||--o{ TEST_QUESTIONS : "contains"
    QUESTIONS ||--o{ TEST_QUESTIONS : "included in"
    QUESTIONS ||--o{ OPTIONS : "has"
    STUDENT_TESTS ||--o{ STUDENT_ANSWERS : "has"
    STUDENT_TESTS ||--o{ SCORE_AUDIT : "logged in"
    OPTIONS ||--o{ STUDENT_ANSWERS : "selected in"
    QUESTIONS ||--o{ STUDENT_ANSWERS : "answered in"
```

## Relationship Summary

| Relationship | Cardinality | Description |
|---|---|---|
| USERS → QUESTIONS | 1 : Many | Admin creates multiple questions |
| USERS → TESTS | 1 : Many | Admin creates multiple tests |
| USERS → STUDENT_TESTS | 1 : Many | Student takes multiple tests |
| TESTS ↔ QUESTIONS | Many : Many | via TEST_QUESTIONS junction table |
| QUESTIONS → OPTIONS | 1 : Many | Each question has 4 options |
| STUDENT_TESTS → STUDENT_ANSWERS | 1 : Many | Each attempt has multiple answers |
| STUDENT_TESTS → SCORE_AUDIT | 1 : Many | Score changes are logged |
| OPTIONS → STUDENT_ANSWERS | 1 : Many | Option selected by students |

## Image File Location
The generated ER diagram image is saved at:
`C:\Users\Geethika\.gemini\antigravity\brain\2f524902-fec7-4329-bb6f-5361a6e83564\er_diagram_mcq_1774695618731.png`

You can open this file directly in Windows Explorer and paste it into your Word report.
