-- Aegis Edu Database Schema
-- D1 SQLite Migrations

-- ============================================
-- AUTH SERVICE TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    external_id TEXT UNIQUE,
    role TEXT CHECK (role IN ('student', 'teacher', 'admin', 'parent')) NOT NULL,
    grade_id TEXT,
    pseudonym TEXT UNIQUE NOT NULL,
    display_name TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    last_login INTEGER,
    is_active BOOLEAN DEFAULT 1,
    metadata JSON
);

CREATE INDEX IF NOT EXISTS idx_users_grade ON users(grade_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token_hash TEXT UNIQUE NOT NULL,
    expires_at INTEGER NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    ip_address TEXT,
    user_agent TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);

CREATE TABLE IF NOT EXISTS roles (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    permissions JSON NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id TEXT NOT NULL,
    role_id TEXT NOT NULL,
    granted_by TEXT,
    granted_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

-- ============================================
-- CURRICULUM SERVICE TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS grades (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT UNIQUE NOT NULL,
    region_code TEXT,
    school_year TEXT,
    is_active BOOLEAN DEFAULT 1,
    metadata JSON
);

CREATE INDEX IF NOT EXISTS idx_grades_region ON grades(region_code);

CREATE TABLE IF NOT EXISTS subjects (
    id TEXT PRIMARY KEY,
    grade_id TEXT NOT NULL,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    description TEXT,
    order_index INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT 1,
    FOREIGN KEY (grade_id) REFERENCES grades(id) ON DELETE CASCADE,
    UNIQUE(grade_id, code)
);

CREATE INDEX IF NOT EXISTS idx_subjects_grade ON subjects(grade_id);

CREATE TABLE IF NOT EXISTS topics (
    id TEXT PRIMARY KEY,
    subject_id TEXT NOT NULL,
    parent_topic_id TEXT,
    name TEXT NOT NULL,
    description TEXT,
    mastery_weight REAL DEFAULT 1.0,
    order_index INTEGER DEFAULT 0,
    estimated_duration_min INTEGER,
    prerequisites JSON,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_topic_id) REFERENCES topics(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_topics_subject ON topics(subject_id);
CREATE INDEX IF NOT EXISTS idx_topics_parent ON topics(parent_topic_id);

CREATE TABLE IF NOT EXISTS objectives (
    id TEXT PRIMARY KEY,
    topic_id TEXT NOT NULL,
    code TEXT NOT NULL,
    description TEXT NOT NULL,
    bloom_level TEXT CHECK (bloom_level IN ('remember', 'understand', 'apply', 'analyze', 'evaluate', 'create')),
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE,
    UNIQUE(topic_id, code)
);

CREATE INDEX IF NOT EXISTS idx_objectives_topic ON objectives(topic_id);

CREATE TABLE IF NOT EXISTS lessons (
    id TEXT PRIMARY KEY,
    topic_id TEXT NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    title TEXT NOT NULL,
    summary TEXT,
    content_r2_key TEXT,
    content_type TEXT DEFAULT 'text/html',
    status TEXT CHECK (status IN ('draft', 'review', 'published', 'archived')) DEFAULT 'draft',
    ai_model_version TEXT,
    prompt_template_id TEXT,
    prompt_template_hash TEXT,
    source_references JSON,
    reviewed_by TEXT,
    reviewed_at INTEGER,
    review_notes TEXT,
    published_at INTEGER,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE,
    UNIQUE(topic_id, version)
);

CREATE INDEX IF NOT EXISTS idx_lessons_topic ON lessons(topic_id, status);
CREATE INDEX IF NOT EXISTS idx_lessons_status ON lessons(status);

CREATE TABLE IF NOT EXISTS lesson_prerequisites (
    lesson_id TEXT NOT NULL,
    prerequisite_lesson_id TEXT NOT NULL,
    PRIMARY KEY (lesson_id, prerequisite_lesson_id),
    FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE,
    FOREIGN KEY (prerequisite_lesson_id) REFERENCES lessons(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS content_sources (
    id TEXT PRIMARY KEY,
    lesson_id TEXT,
    source_type TEXT CHECK (source_type IN ('web', 'pdf', 'teacher', 'ai_generated', 'curriculum_guide')) NOT NULL,
    url TEXT,
    title TEXT,
    author TEXT,
    published_date TEXT,
    accessed_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    content_hash TEXT,
    moderation_status TEXT CHECK (moderation_status IN ('pending', 'approved', 'rejected', 'flagged')) DEFAULT 'pending',
    moderated_by TEXT,
    moderated_at INTEGER,
    notes TEXT,
    FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_sources_lesson ON content_sources(lesson_id);
CREATE INDEX IF NOT EXISTS idx_sources_moderation ON content_sources(moderation_status);

-- ============================================
-- ASSESSMENT SERVICE TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS assignments (
    id TEXT PRIMARY KEY,
    lesson_id TEXT,
    topic_id TEXT,
    type TEXT CHECK (type IN ('quiz', 'homework', 'flashcard', 'practice', 'exam')) NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    difficulty TINYINT CHECK (difficulty BETWEEN 1 AND 5) DEFAULT 3,
    time_limit_sec INTEGER,
    passing_score REAL DEFAULT 70.0,
    max_attempts INTEGER DEFAULT 3,
    parameters JSON,
    is_published BOOLEAN DEFAULT 0,
    published_at INTEGER,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE SET NULL,
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_assignments_lesson ON assignments(lesson_id);
CREATE INDEX IF NOT EXISTS idx_assignments_topic ON assignments(topic_id);
CREATE INDEX IF NOT EXISTS idx_assignments_published ON assignments(is_published);

CREATE TABLE IF NOT EXISTS questions (
    id TEXT PRIMARY KEY,
    assignment_id TEXT NOT NULL,
    type TEXT CHECK (type IN ('mcq', 'short_answer', 'essay', 'fill_blank', 'matching', 'ordering')) NOT NULL,
    content_text TEXT,
    content_r2_key TEXT,
    points REAL DEFAULT 1.0,
    order_index INTEGER DEFAULT 0,
    metadata JSON,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_questions_assignment ON questions(assignment_id);

CREATE TABLE IF NOT EXISTS mcq_options (
    question_id TEXT NOT NULL,
    option_key TEXT NOT NULL,
    content_text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT 0,
    explanation TEXT,
    order_index INTEGER DEFAULT 0,
    PRIMARY KEY (question_id, option_key),
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS question_rubrics (
    question_id TEXT PRIMARY KEY,
    rubric_criteria JSON NOT NULL,
    sample_answer TEXT,
    grading_instructions TEXT,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS submissions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    assignment_id TEXT NOT NULL,
    attempt_number INTEGER NOT NULL DEFAULT 1,
    started_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    submitted_at INTEGER,
    score REAL,
    max_score REAL,
    percentage REAL,
    xp_awarded INTEGER DEFAULT 0,
    status TEXT CHECK (status IN ('in_progress', 'submitted', 'graded', 'flagged', 'expired')) DEFAULT 'in_progress',
    time_spent_sec INTEGER,
    feedback_text TEXT,
    flagged_reason TEXT,
    graded_by TEXT,
    graded_at INTEGER,
    idempotency_key TEXT UNIQUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE,
    UNIQUE(user_id, assignment_id, attempt_number)
);

CREATE INDEX IF NOT EXISTS idx_submissions_user ON submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_submissions_assignment ON submissions(assignment_id);
CREATE INDEX IF NOT EXISTS idx_submissions_status ON submissions(status);

CREATE TABLE IF NOT EXISTS submission_answers (
    submission_id TEXT NOT NULL,
    question_id TEXT NOT NULL,
    response_text TEXT,
    response_r2_key TEXT,
    is_correct BOOLEAN,
    points_earned REAL DEFAULT 0,
    ai_feedback TEXT,
    grader_notes TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    PRIMARY KEY (submission_id, question_id),
    FOREIGN KEY (submission_id) REFERENCES submissions(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_answers_submission ON submission_answers(submission_id);

-- ============================================
-- GAMIFICATION SERVICE TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS xp_ledger (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    amount INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    reason_code TEXT NOT NULL,
    reason_detail TEXT,
    related_entity_type TEXT,
    related_entity_id TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    idempotency_key TEXT UNIQUE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_xp_user ON xp_ledger(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_created ON xp_ledger(created_at);

CREATE TABLE IF NOT EXISTS user_xp_summary (
    user_id TEXT PRIMARY KEY,
    total_xp INTEGER NOT NULL DEFAULT 0,
    current_level INTEGER NOT NULL DEFAULT 1,
    streak_days INTEGER NOT NULL DEFAULT 0,
    longest_streak INTEGER NOT NULL DEFAULT 0,
    last_activity_date TEXT,
    weekly_xp INTEGER NOT NULL DEFAULT 0,
    monthly_xp INTEGER NOT NULL DEFAULT 0,
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS levels (
    level INTEGER PRIMARY KEY,
    min_xp INTEGER NOT NULL UNIQUE,
    max_xp INTEGER,
    title TEXT,
    badge_r2_key TEXT,
    perks JSON
);

CREATE TABLE IF NOT EXISTS badges (
    id TEXT PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    criteria_json JSON NOT NULL,
    icon_r2_key TEXT,
    rarity TEXT CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary')) DEFAULT 'common',
    is_active BOOLEAN DEFAULT 1,
    category TEXT
);

CREATE INDEX IF NOT EXISTS idx_badges_category ON badges(category);

CREATE TABLE IF NOT EXISTS user_badges (
    user_id TEXT NOT NULL,
    badge_id TEXT NOT NULL,
    awarded_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    context_json JSON,
    PRIMARY KEY (user_id, badge_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (badge_id) REFERENCES badges(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_badges_user ON user_badges(user_id);

CREATE TABLE IF NOT EXISTS achievements (
    id TEXT PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    achievement_type TEXT CHECK (achievement_type IN ('one_time', 'progressive', 'recurring')) NOT NULL,
    target_value INTEGER,
    reward_xp INTEGER,
    reward_badge_id TEXT,
    is_active BOOLEAN DEFAULT 1,
    FOREIGN KEY (reward_badge_id) REFERENCES badges(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS user_achievements (
    user_id TEXT NOT NULL,
    achievement_id TEXT NOT NULL,
    progress INTEGER DEFAULT 0,
    completed_at INTEGER,
    claimed_at INTEGER,
    PRIMARY KEY (user_id, achievement_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (achievement_id) REFERENCES achievements(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS leaderboard_snapshots (
    id TEXT PRIMARY KEY,
    grade_id TEXT NOT NULL,
    subject_id TEXT,
    period_type TEXT CHECK (period_type IN ('all_time', 'weekly', 'monthly', 'seasonal')) NOT NULL,
    period_start INTEGER NOT NULL,
    period_end INTEGER,
    snapshot_data JSON NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (grade_id) REFERENCES grades(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_leaderboard_grade ON leaderboard_snapshots(grade_id, period_type, period_start);

-- ============================================
-- PROGRESS & ANALYTICS TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS user_topic_mastery (
    user_id TEXT NOT NULL,
    topic_id TEXT NOT NULL,
    mastery_score REAL DEFAULT 0,
    questions_attempted INTEGER DEFAULT 0,
    questions_correct INTEGER DEFAULT 0,
    last_practiced_at INTEGER,
    next_review_at INTEGER,
    difficulty_level TINYINT DEFAULT 1,
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    PRIMARY KEY (user_id, topic_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_mastery_user ON user_topic_mastery(user_id);
CREATE INDEX IF NOT EXISTS idx_mastery_review ON user_topic_mastery(next_review_at);

CREATE TABLE IF NOT EXISTS learning_activities (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    activity_type TEXT NOT NULL,
    entity_type TEXT,
    entity_id TEXT,
    duration_sec INTEGER,
    score REAL,
    xp_earned INTEGER,
    metadata JSON,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_activities_user ON learning_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_type ON learning_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_activities_created ON learning_activities(created_at);

CREATE TABLE IF NOT EXISTS spaced_repetition_items (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    item_type TEXT NOT NULL,
    item_id TEXT NOT NULL,
    ease_factor REAL DEFAULT 2.5,
    interval_days INTEGER DEFAULT 1,
    repetitions INTEGER DEFAULT 0,
    next_review_at INTEGER NOT NULL,
    last_reviewed_at INTEGER,
    performance_history JSON,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, item_type, item_id)
);

CREATE INDEX IF NOT EXISTS idx_srs_user ON spaced_repetition_items(user_id);
CREATE INDEX IF NOT EXISTS idx_srs_review ON spaced_repetition_items(next_review_at);

-- ============================================
-- MODERATION & AUDIT TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS moderation_queue (
    id TEXT PRIMARY KEY,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    content_text TEXT,
    content_r2_key TEXT,
    priority INTEGER DEFAULT 5,
    status TEXT CHECK (status IN ('pending', 'processing', 'approved', 'rejected', 'escalated')) DEFAULT 'pending',
    auto_mod_result JSON,
    assigned_to TEXT,
    reviewed_at INTEGER,
    decision_notes TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    UNIQUE(entity_type, entity_id)
);

CREATE INDEX IF NOT EXISTS idx_moderation_status ON moderation_queue(status);
CREATE INDEX IF NOT EXISTS idx_moderation_priority ON moderation_queue(priority);

CREATE TABLE IF NOT EXISTS audit_logs (
    id TEXT PRIMARY KEY,
    actor_user_id TEXT,
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id TEXT,
    old_values JSON,
    new_values JSON,
    ip_address TEXT,
    user_agent TEXT,
    correlation_id TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_audit_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON audit_logs(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at);

CREATE TABLE IF NOT EXISTS rate_limits (
    key TEXT PRIMARY KEY,
    count INTEGER NOT NULL DEFAULT 0,
    window_start INTEGER NOT NULL,
    window_end INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_rate_limits_window ON rate_limits(window_end);

-- ============================================
-- SYSTEM CONFIGURATION TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS feature_flags (
    key TEXT PRIMARY KEY,
    value JSON NOT NULL,
    description TEXT,
    updated_by TEXT,
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

CREATE TABLE IF NOT EXISTS system_config (
    key TEXT PRIMARY KEY,
    value JSON NOT NULL,
    schema_version TEXT,
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

CREATE TABLE IF NOT EXISTS api_keys (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    key_hash TEXT UNIQUE NOT NULL,
    service_name TEXT,
    permissions JSON,
    expires_at INTEGER,
    is_active BOOLEAN DEFAULT 1,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    last_used_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_api_keys_service ON api_keys(service_name);
CREATE INDEX IF NOT EXISTS idx_api_keys_active ON api_keys(is_active);

-- ============================================
-- INITIAL DATA SEEDING
-- ============================================

-- Default roles
INSERT OR IGNORE INTO roles (id, name, permissions, description) VALUES 
('role_student', 'student', '{"read_content": true, "submit_assignments": true, "view_leaderboard": true, "earn_xp": true}', 'Standard student role'),
('role_teacher', 'teacher', '{"read_content": true, "create_content": true, "grade_assignments": true, "view_analytics": true, "manage_students": true}', 'Teacher role with content creation'),
('role_admin', 'admin', '{"full_access": true}', 'Administrator with full access'),
('role_parent', 'parent', '{"view_child_progress": true}', 'Parent role for viewing child progress');

-- Default grade levels
INSERT OR IGNORE INTO grades (id, name, code, school_year) VALUES 
('grade_k', 'Kindergarten', 'K', '2024-2025'),
('grade_1', 'Grade 1', 'G1', '2024-2025'),
('grade_2', 'Grade 2', 'G2', '2024-2025'),
('grade_3', 'Grade 3', 'G3', '2024-2025'),
('grade_4', 'Grade 4', 'G4', '2024-2025'),
('grade_5', 'Grade 5', 'G5', '2024-2025'),
('grade_6', 'Grade 6', 'G6', '2024-2025'),
('grade_7', 'Grade 7', 'G7', '2024-2025'),
('grade_8', 'Grade 8', 'G8', '2024-2025'),
('grade_9', 'Grade 9', 'G9', '2024-2025'),
('grade_10', 'Grade 10', 'G10', '2024-2025'),
('grade_11', 'Grade 11', 'G11', '2024-2025'),
('grade_12', 'Grade 12', 'G12', '2024-2025');

-- Default levels (non-linear progression)
INSERT OR IGNORE INTO levels (level, min_xp, title, perks) VALUES 
(1, 0, 'Novice Learner', '{"badge_multiplier": 1.0}'),
(2, 100, 'Apprentice', '{"badge_multiplier": 1.1}'),
(3, 250, 'Explorer', '{"badge_multiplier": 1.2}'),
(4, 500, 'Scholar', '{"badge_multiplier": 1.3}'),
(5, 1000, 'Knowledge Seeker', '{"badge_multiplier": 1.4}'),
(6, 2000, 'Wisdom Keeper', '{"badge_multiplier": 1.5}'),
(7, 4000, 'Master Learner', '{"badge_multiplier": 1.6}'),
(8, 8000, 'Grand Scholar', '{"badge_multiplier": 1.7}'),
(9, 16000, 'Sage', '{"badge_multiplier": 1.8}'),
(10, 32000, 'Legend', '{"badge_multiplier": 2.0}');

-- Default badges
INSERT OR IGNORE INTO badges (id, code, name, description, criteria_json, rarity, category) VALUES 
('badge_first_steps', 'FIRST_STEPS', 'First Steps', 'Complete your first assignment', '{"type": "one_time", "action": "complete_assignment", "count": 1}', 'common', 'achievement'),
('badge_week_warrior', 'WEEK_WARRIOR', 'Week Warrior', 'Maintain a 7-day streak', '{"type": "streak", "days": 7}', 'uncommon', 'streak'),
('badge_perfect_score', 'PERFECT_SCORE', 'Perfect Score', 'Get 100% on any assignment', '{"type": "one_time", "action": "perfect_score", "count": 1}', 'rare', 'achievement'),
('badge_subject_master', 'SUBJECT_MASTER', 'Subject Master', 'Reach 90% mastery in any subject', '{"type": "mastery", "threshold": 0.9}', 'epic', 'mastery'),
('badge_helping_hand', 'HELPING_HAND', 'Helping Hand', 'Complete 50 practice exercises', '{"type": "progressive", "action": "practice", "count": 50}', 'uncommon', 'practice');

-- Feature flags
INSERT OR IGNORE INTO feature_flags (key, value, description) VALUES 
('ai_content_generation', '{"enabled": true, "requires_review": true}', 'Enable AI-generated content with mandatory review'),
('cross_grade_preview', '{"enabled": false}', 'Allow students to preview content from other grades'),
('leaderboard_reset_weekly', '{"enabled": true, "reset_day": "monday"}', 'Weekly leaderboard reset schedule'),
('adaptive_difficulty', '{"enabled": true}', 'Enable adaptive difficulty adjustment');
