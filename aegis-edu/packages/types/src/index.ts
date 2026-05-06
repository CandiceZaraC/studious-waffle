/**
 * Aegis Edu - Shared TypeScript Types
 * Enterprise-grade type definitions for the education platform
 */

// ============================================
// CORE ENTITY TYPES
// ============================================

export type UserRole = 'student' | 'teacher' | 'admin' | 'parent';
export type ContentStatus = 'draft' | 'review' | 'published' | 'archived';
export type ModerationStatus = 'pending' | 'approved' | 'rejected' | 'flagged';
export type SubmissionStatus = 'in_progress' | 'submitted' | 'graded' | 'flagged' | 'expired';
export type AssignmentType = 'quiz' | 'homework' | 'flashcard' | 'practice' | 'exam';
export type QuestionType = 'mcq' | 'short_answer' | 'essay' | 'fill_blank' | 'matching' | 'ordering';
export type BloomLevel = 'remember' | 'understand' | 'apply' | 'analyze' | 'evaluate' | 'create';
export type BadgeRarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary';
export type LeaderboardPeriod = 'all_time' | 'weekly' | 'monthly' | 'seasonal';

// ============================================
// USER & AUTH TYPES
// ============================================

export interface User {
  id: string;
  external_id?: string;
  role: UserRole;
  grade_id?: string;
  pseudonym: string;
  display_name?: string;
  created_at: number;
  last_login?: number;
  is_active: boolean;
  metadata?: Record<string, unknown>;
}

export interface Session {
  id: string;
  user_id: string;
  token_hash: string;
  expires_at: number;
  created_at: number;
  ip_address?: string;
  user_agent?: string;
}

export interface Role {
  id: string;
  name: string;
  permissions: Record<string, boolean>;
  description?: string;
}

export interface AuthTokens {
  access_token: string;
  refresh_token?: string;
  expires_in: number;
  token_type: 'Bearer';
}

export interface LoginRequest {
  external_id: string;
  role: UserRole;
  grade_id?: string;
}

export interface LoginResponse {
  user: User;
  tokens: AuthTokens;
}

// ============================================
// CURRICULUM TYPES
// ============================================

export interface Grade {
  id: string;
  name: string;
  code: string;
  region_code?: string;
  school_year?: string;
  is_active: boolean;
  metadata?: Record<string, unknown>;
}

export interface Subject {
  id: string;
  grade_id: string;
  name: string;
  code: string;
  description?: string;
  order_index: number;
  is_active: boolean;
}

export interface Topic {
  id: string;
  subject_id: string;
  parent_topic_id?: string;
  name: string;
  description?: string;
  mastery_weight: number;
  order_index: number;
  estimated_duration_min?: number;
  prerequisites?: string[];
}

export interface Objective {
  id: string;
  topic_id: string;
  code: string;
  description: string;
  bloom_level?: BloomLevel;
}

export interface Lesson {
  id: string;
  topic_id: string;
  version: number;
  title: string;
  summary?: string;
  content_r2_key?: string;
  content_type: string;
  status: ContentStatus;
  ai_model_version?: string;
  prompt_template_id?: string;
  prompt_template_hash?: string;
  source_references?: SourceReference[];
  reviewed_by?: string;
  reviewed_at?: number;
  review_notes?: string;
  published_at?: number;
  created_at: number;
  updated_at: number;
}

export interface SourceReference {
  id: string;
  source_type: 'web' | 'pdf' | 'teacher' | 'ai_generated' | 'curriculum_guide';
  url?: string;
  title?: string;
  author?: string;
  published_date?: string;
  accessed_at: number;
  content_hash?: string;
  moderation_status: ModerationStatus;
  moderated_by?: string;
  moderated_at?: number;
  notes?: string;
}

export interface SyllabusManifest {
  grade_id: string;
  subjects: SubjectWithTopics[];
  generated_at: number;
  version: string;
}

export interface SubjectWithTopics extends Subject {
  topics: TopicWithLessons[];
}

export interface TopicWithLessons extends Topic {
  lessons: LessonSummary[];
}

export interface LessonSummary {
  id: string;
  title: string;
  status: ContentStatus;
  published_at?: number;
}

// ============================================
// ASSESSMENT TYPES
// ============================================

export interface Assignment {
  id: string;
  lesson_id?: string;
  topic_id?: string;
  type: AssignmentType;
  title: string;
  description?: string;
  difficulty: number; // 1-5
  time_limit_sec?: number;
  passing_score: number;
  max_attempts: number;
  parameters?: Record<string, unknown>;
  is_published: boolean;
  published_at?: number;
  created_at: number;
  updated_at: number;
}

export interface Question {
  id: string;
  assignment_id: string;
  type: QuestionType;
  content_text?: string;
  content_r2_key?: string;
  points: number;
  order_index: number;
  metadata?: Record<string, unknown>;
}

export interface MCQOption {
  question_id: string;
  option_key: string;
  content_text: string;
  is_correct: boolean;
  explanation?: string;
  order_index: number;
}

export interface QuestionRubric {
  question_id: string;
  rubric_criteria: Record<string, unknown>;
  sample_answer?: string;
  grading_instructions?: string;
}

export interface Submission {
  id: string;
  user_id: string;
  assignment_id: string;
  attempt_number: number;
  started_at: number;
  submitted_at?: number;
  score?: number;
  max_score?: number;
  percentage?: number;
  xp_awarded: number;
  status: SubmissionStatus;
  time_spent_sec?: number;
  feedback_text?: string;
  flagged_reason?: string;
  graded_by?: string;
  graded_at?: number;
  idempotency_key?: string;
}

export interface SubmissionAnswer {
  submission_id: string;
  question_id: string;
  response_text?: string;
  response_r2_key?: string;
  is_correct?: boolean;
  points_earned: number;
  ai_feedback?: string;
  grader_notes?: string;
  created_at: number;
}

export interface StartAssignmentRequest {
  assignment_id: string;
}

export interface SubmitAssignmentRequest {
  submission_id: string;
  answers: AnswerInput[];
}

export interface AnswerInput {
  question_id: string;
  response_text: string;
}

// ============================================
// GAMIFICATION TYPES
// ============================================

export interface XPLedgerEntry {
  id: string;
  user_id: string;
  amount: number;
  balance_after: number;
  reason_code: string;
  reason_detail?: string;
  related_entity_type?: string;
  related_entity_id?: string;
  created_at: number;
  idempotency_key: string;
}

export interface UserXPSummary {
  user_id: string;
  total_xp: number;
  current_level: number;
  streak_days: number;
  longest_streak: number;
  last_activity_date?: string;
  weekly_xp: number;
  monthly_xp: number;
  updated_at: number;
}

export interface Level {
  level: number;
  min_xp: number;
  max_xp?: number;
  title: string;
  badge_r2_key?: string;
  perks?: Record<string, unknown>;
}

export interface Badge {
  id: string;
  code: string;
  name: string;
  description?: string;
  criteria_json: Record<string, unknown>;
  icon_r2_key?: string;
  rarity: BadgeRarity;
  is_active: boolean;
  category?: string;
}

export interface UserBadge {
  user_id: string;
  badge_id: string;
  awarded_at: number;
  context_json?: Record<string, unknown>;
}

export interface Achievement {
  id: string;
  code: string;
  name: string;
  description?: string;
  achievement_type: 'one_time' | 'progressive' | 'recurring';
  target_value?: number;
  reward_xp?: number;
  reward_badge_id?: string;
  is_active: boolean;
}

export interface UserAchievement {
  user_id: string;
  achievement_id: string;
  progress: number;
  completed_at?: number;
  claimed_at?: number;
}

export interface LeaderboardEntry {
  rank: number;
  user_id: string;
  pseudonym: string;
  xp: number;
  level: number;
  badge_count: number;
}

export interface Leaderboard {
  grade_id: string;
  subject_id?: string;
  period_type: LeaderboardPeriod;
  period_start: number;
  period_end?: number;
  entries: LeaderboardEntry[];
  total_count: number;
  generated_at: number;
}

export interface XPAwardRequest {
  user_id: string;
  amount: number;
  reason_code: string;
  reason_detail?: string;
  related_entity_type?: string;
  related_entity_id?: string;
  idempotency_key: string;
}

// ============================================
// PROGRESS & ANALYTICS TYPES
// ============================================

export interface UserTopicMastery {
  user_id: string;
  topic_id: string;
  mastery_score: number;
  questions_attempted: number;
  questions_correct: number;
  last_practiced_at?: number;
  next_review_at?: number;
  difficulty_level: number;
  updated_at: number;
}

export interface LearningActivity {
  id: string;
  user_id: string;
  activity_type: string;
  entity_type?: string;
  entity_id?: string;
  duration_sec?: number;
  score?: number;
  xp_earned?: number;
  metadata?: Record<string, unknown>;
  created_at: number;
}

export interface SpacedRepetitionItem {
  id: string;
  user_id: string;
  item_type: string;
  item_id: string;
  ease_factor: number;
  interval_days: number;
  repetitions: number;
  next_review_at: number;
  last_reviewed_at?: number;
  performance_history?: number[];
}

export interface MasteryMap {
  user_id: string;
  topics: TopicMasteryNode[];
}

export interface TopicMasteryNode {
  topic_id: string;
  topic_name: string;
  mastery_score: number;
  children?: TopicMasteryNode[];
}

export interface ProgressRecommendation {
  type: 'review' | 'practice' | 'advance' | 'remediate';
  topic_id: string;
  topic_name: string;
  priority: number; // 1-10
  reason: string;
  suggested_activity_id?: string;
}

// ============================================
// MODERATION & AUDIT TYPES
// ============================================

export interface ModerationQueueItem {
  id: string;
  entity_type: string;
  entity_id: string;
  content_text?: string;
  content_r2_key?: string;
  priority: number;
  status: ModerationStatus;
  auto_mod_result?: AutoModResult;
  assigned_to?: string;
  reviewed_at?: number;
  decision_notes?: string;
  created_at: number;
}

export interface AutoModResult {
  is_safe: boolean;
  confidence: number;
  flags: string[];
  categories: Record<string, number>;
}

export interface AuditLog {
  id: string;
  actor_user_id?: string;
  action: string;
  resource_type: string;
  resource_id?: string;
  old_values?: Record<string, unknown>;
  new_values?: Record<string, unknown>;
  ip_address?: string;
  user_agent?: string;
  correlation_id?: string;
  created_at: number;
}

export interface RateLimitConfig {
  key: string;
  limit: number;
  window_sec: number;
}

// ============================================
// AI ORCHESTRATION TYPES
// ============================================

export interface AIRequest {
  task_type: AITaskType;
  input: Record<string, unknown>;
  model_preference?: string;
  temperature?: number;
  max_tokens?: number;
  context?: Record<string, unknown>;
}

export type AITaskType = 
  | 'generate_lesson'
  | 'generate_questions'
  | 'grade_response'
  | 'generate_feedback'
  | 'generate_hint'
  | 'classify_weakness'
  | 'generate_summary'
  | 'moderate_content'
  | 'extract_objectives';

export interface AIResponse {
  success: boolean;
  output: Record<string, unknown>;
  model_used: string;
  tokens_used: number;
  latency_ms: number;
  safety_check?: SafetyCheckResult;
}

export interface SafetyCheckResult {
  passed: boolean;
  flags: string[];
  confidence: number;
}

export interface PromptTemplate {
  id: string;
  name: string;
  version: string;
  system_prompt: string;
  user_prompt_template: string;
  variables: string[];
  model_suitability: AITaskType[];
}

export interface ContentGenerationParams {
  grade_id: string;
  topic_id: string;
  objectives: Objective[];
  difficulty: number;
  length_minutes: number;
  include_examples: boolean;
  include_assessments: boolean;
}

export interface QuestionGenerationParams {
  topic_id: string;
  question_type: QuestionType;
  count: number;
  difficulty: number;
  bloom_levels?: BloomLevel[];
  include_explanations: boolean;
}

// ============================================
// API RESPONSE TYPES
// ============================================

export interface APIResponse<T> {
  success: boolean;
  data?: T;
  error?: APIError;
  meta?: Record<string, unknown>;
}

export interface APIError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
  correlation_id?: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  page_size: number;
  has_more: boolean;
}

// ============================================
// QUEUE MESSAGE TYPES
// ============================================

export interface ContentGenerationMessage {
  job_id: string;
  lesson_id: string;
  params: ContentGenerationParams;
  priority: number;
  created_at: number;
}

export interface GradingMessage {
  job_id: string;
  submission_id: string;
  question_ids: string[];
  priority: number;
  created_at: number;
}

export interface ModerationMessage {
  job_id: string;
  entity_type: string;
  entity_id: string;
  content_text?: string;
  content_r2_key?: string;
  priority: number;
  created_at: number;
}

export interface XPUpdateMessage {
  user_id: string;
  action: string;
  entity_type: string;
  entity_id: string;
  base_xp: number;
  multipliers: Record<string, number>;
  idempotency_key: string;
  created_at: number;
}

export interface AnalyticsEventMessage {
  event_type: string;
  user_id: string;
  properties: Record<string, unknown>;
  timestamp: number;
}

// ============================================
// DURABLE OBJECT STATE TYPES
// ============================================

export interface LeaderboardState {
  grade_id: string;
  subject_id?: string;
  period_type: LeaderboardPeriod;
  rankings: Map<string, LeaderboardEntry>;
  last_updated: number;
}

export interface RateLimitState {
  counts: Map<string, number>;
  windows: Map<string, number>;
}

export interface SessionPresenceState {
  sessions: Map<string, SessionInfo>;
}

export interface SessionInfo {
  user_id: string;
  connected_at: number;
  last_seen: number;
  metadata?: Record<string, unknown>;
}

// ============================================
// CONFIGURATION TYPES
// ============================================

export interface FeatureFlags {
  ai_content_generation: { enabled: boolean; requires_review: boolean };
  cross_grade_preview: { enabled: boolean };
  leaderboard_reset_weekly: { enabled: boolean; reset_day: string };
  adaptive_difficulty: { enabled: boolean };
  [key: string]: { enabled: boolean } | Record<string, unknown>;
}

export interface SystemConfig {
  xp_formulas: XPFormulas;
  streak_settings: StreakSettings;
  content_settings: ContentSettings;
  rate_limits: RateLimitConfig[];
}

export interface XPFormulas {
  base_xp_per_question: number;
  difficulty_multipliers: Record<number, number>;
  streak_bonus_threshold: number;
  streak_bonus_multiplier: number;
  perfect_score_bonus: number;
  speed_bonus_enabled: boolean;
}

export interface StreakSettings {
  reset_hour_utc: number;
  grace_period_hours: number;
  max_streak_freeze_per_month: number;
}

export interface ContentSettings {
  default_lesson_duration_min: number;
  min_questions_per_assignment: number;
  max_questions_per_assignment: number;
  require_human_review_for_ai: boolean;
}

// ============================================
// PWA & OFFLINE TYPES
// ============================================

export interface OfflineCache {
  lessons: Map<string, CachedLesson>;
  assignments: Map<string, CachedAssignment>;
  submissions: PendingSubmission[];
  last_sync: number;
}

export interface CachedLesson {
  id: string;
  title: string;
  content: string;
  cached_at: number;
  expires_at: number;
}

export interface CachedAssignment {
  id: string;
  title: string;
  questions: Question[];
  cached_at: number;
}

export interface PendingSubmission {
  submission_id: string;
  assignment_id: string;
  answers: AnswerInput[];
  queued_at: number;
  retry_count: number;
}

// ============================================
// UTILITY TYPES
// ============================================

export type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

export type IdempotencyKey = `${string}:${string}:${number}`;

export interface Timestamped<T> {
  data: T;
  created_at: number;
  updated_at: number;
}

export interface Versioned<T> {
  data: T;
  version: number;
  version_history: VersionHistory[];
}

export interface VersionHistory {
  version: number;
  changed_at: number;
  changed_by: string;
  changes: string[];
}
