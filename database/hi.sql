-- ============================================================
-- PROVENANCE — Complete Database Schema
-- MySQL 8.0+ | Verified for Aiven MySQL
-- 18 tables across 6 layers
-- ============================================================

-- ============================================================
-- LAYER 1: IDENTITY
-- ============================================================
Use defaultdb;
CREATE TABLE IF NOT EXISTS users (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name         VARCHAR(150) NOT NULL,
  email             VARCHAR(255) NOT NULL UNIQUE,
  password_hash     VARCHAR(255) NOT NULL,
  avatar_url        VARCHAR(500) DEFAULT NULL,
  is_active         TINYINT(1) NOT NULL DEFAULT 1,
  last_login_at     TIMESTAMP NULL DEFAULT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- LAYER 2: PROJECTS & TEAMS
-- ============================================================

CREATE TABLE IF NOT EXISTS projects (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name              VARCHAR(255) NOT NULL,
  description       TEXT DEFAULT NULL,
  join_code         VARCHAR(20) NOT NULL UNIQUE,
  color_theme       VARCHAR(20) DEFAULT 'blue',
  icon_emoji        VARCHAR(10) DEFAULT '📁',
  status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  created_by        BIGINT UNSIGNED DEFAULT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  archived_at       TIMESTAMP NULL DEFAULT NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_projects_join_code (join_code),
  INDEX idx_projects_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS project_members (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id        BIGINT UNSIGNED NOT NULL,
  user_id           BIGINT UNSIGNED NOT NULL,
  role              VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
  invited_by        BIGINT UNSIGNED DEFAULT NULL,
  joined_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  removed_at        TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY unique_project_member (project_id, user_id),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_pm_project (project_id),
  INDEX idx_pm_user (user_id),
  INDEX idx_pm_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS teams (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id        BIGINT UNSIGNED NOT NULL,
  name              VARCHAR(150) NOT NULL,
  description       TEXT DEFAULT NULL,
  created_by        BIGINT UNSIGNED DEFAULT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_teams_project (project_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS team_members (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  team_id           BIGINT UNSIGNED NOT NULL,
  user_id           BIGINT UNSIGNED NOT NULL,
  added_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_team_member (team_id, user_id),
  FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- LAYER 3: UPLOADS & MEETINGS
-- ============================================================

CREATE TABLE IF NOT EXISTS uploads (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id        BIGINT UNSIGNED NOT NULL,
  uploaded_by       BIGINT UNSIGNED NOT NULL,
  file_name         VARCHAR(255) NOT NULL,
  file_type         VARCHAR(20) NOT NULL,
  file_size_kb      INT DEFAULT NULL,
  file_url          VARCHAR(500) DEFAULT NULL,
  raw_text          LONGTEXT DEFAULT NULL,
  parse_status      VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  parse_error       TEXT DEFAULT NULL,
  uploaded_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  parsed_at         TIMESTAMP NULL DEFAULT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_uploads_project (project_id),
  INDEX idx_uploads_status (parse_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS meetings (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id        BIGINT UNSIGNED NOT NULL,
  upload_id         BIGINT UNSIGNED DEFAULT NULL,
  title             VARCHAR(255) NOT NULL,
  description       TEXT DEFAULT NULL,
  meeting_date      DATETIME DEFAULT NULL,
  raw_text          LONGTEXT DEFAULT NULL,
  ai_summary        TEXT DEFAULT NULL,
  ai_model_used     VARCHAR(100) DEFAULT NULL,
  extraction_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  created_by        BIGINT UNSIGNED NOT NULL,
  reviewed_by       BIGINT UNSIGNED DEFAULT NULL,
  posted_at         TIMESTAMP NULL DEFAULT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (upload_id) REFERENCES uploads(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_meetings_project (project_id),
  INDEX idx_meetings_status (extraction_status),
  INDEX idx_meetings_date (meeting_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS meeting_attendees (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  meeting_id        BIGINT UNSIGNED NOT NULL,
  user_id           BIGINT UNSIGNED NOT NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'INVITED',
  role              VARCHAR(20) NOT NULL DEFAULT 'ATTENDEE',
  invited_by        BIGINT UNSIGNED DEFAULT NULL,
  joined_at         TIMESTAMP NULL DEFAULT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_meeting_attendee (meeting_id, user_id),
  FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_ma_meeting (meeting_id),
  INDEX idx_ma_user (user_id),
  INDEX idx_ma_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- LAYER 4: EXTRACTED CONTENT
-- ============================================================

CREATE TABLE IF NOT EXISTS decisions (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id        BIGINT UNSIGNED NOT NULL,
  meeting_id        BIGINT UNSIGNED NOT NULL,
  title             VARCHAR(255) NOT NULL,
  description       TEXT DEFAULT NULL,
  made_by           VARCHAR(150) DEFAULT NULL,
  evidence          TEXT DEFAULT NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  is_pinned         TINYINT(1) NOT NULL DEFAULT 0,
  created_by        BIGINT UNSIGNED DEFAULT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_decisions_project (project_id),
  INDEX idx_decisions_meeting (meeting_id),
  INDEX idx_decisions_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tasks (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id        BIGINT UNSIGNED NOT NULL,
  meeting_id        BIGINT UNSIGNED DEFAULT NULL,
  decision_id       BIGINT UNSIGNED DEFAULT NULL,
  parent_task_id    BIGINT UNSIGNED DEFAULT NULL,
  team_id           BIGINT UNSIGNED DEFAULT NULL,
  title             VARCHAR(255) NOT NULL,
  description       TEXT DEFAULT NULL,
  evidence          TEXT DEFAULT NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'TODO',
  priority          TINYINT NOT NULL DEFAULT 3,
  progress          TINYINT NOT NULL DEFAULT 0,
  start_date        DATE DEFAULT NULL,
  due_date          DATE DEFAULT NULL,
  completed_at      TIMESTAMP NULL DEFAULT NULL,
  created_by        BIGINT UNSIGNED DEFAULT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE SET NULL,
  FOREIGN KEY (decision_id) REFERENCES decisions(id) ON DELETE SET NULL,
  FOREIGN KEY (parent_task_id) REFERENCES tasks(id) ON DELETE CASCADE,
  FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_tasks_project (project_id),
  INDEX idx_tasks_meeting (meeting_id),
  INDEX idx_tasks_status (status),
  INDEX idx_tasks_priority (priority),
  INDEX idx_tasks_due (due_date),
  INDEX idx_tasks_team (team_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS task_assignees (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  task_id           BIGINT UNSIGNED NOT NULL,
  user_id           BIGINT UNSIGNED NOT NULL,
  role_in_task      VARCHAR(20) NOT NULL DEFAULT 'CONTRIBUTOR',
  status            VARCHAR(20) NOT NULL DEFAULT 'ASSIGNED',
  progress          TINYINT NOT NULL DEFAULT 0,
  assigned_by       BIGINT UNSIGNED DEFAULT NULL,
  assigned_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at      TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY unique_task_assignee (task_id, user_id),
  FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_ta_task (task_id),
  INDEX idx_ta_user (user_id),
  INDEX idx_ta_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS open_questions (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id        BIGINT UNSIGNED NOT NULL,
  meeting_id        BIGINT UNSIGNED NOT NULL,
  task_id           BIGINT UNSIGNED DEFAULT NULL,
  question          TEXT NOT NULL,
  context           TEXT DEFAULT NULL,
  evidence          TEXT DEFAULT NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'OPEN',
  asked_by          VARCHAR(150) DEFAULT NULL,
  assigned_to       BIGINT UNSIGNED DEFAULT NULL,
  resolved_by       BIGINT UNSIGNED DEFAULT NULL,
  resolution_note   TEXT DEFAULT NULL,
  resolved_at       TIMESTAMP NULL DEFAULT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE,
  FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL,
  FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (resolved_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_oq_project (project_id),
  INDEX idx_oq_meeting (meeting_id),
  INDEX idx_oq_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dependencies (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  task_id           BIGINT UNSIGNED NOT NULL,
  depends_on_task_id BIGINT UNSIGNED NOT NULL,
  reason            TEXT DEFAULT NULL,
  created_by        BIGINT UNSIGNED DEFAULT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
  FOREIGN KEY (depends_on_task_id) REFERENCES tasks(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  UNIQUE KEY unique_dependency (task_id, depends_on_task_id),
  INDEX idx_dep_task (task_id),
  INDEX idx_dep_depends (depends_on_task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notes (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id        BIGINT UNSIGNED NOT NULL,
  meeting_id        BIGINT UNSIGNED DEFAULT NULL,
  title             VARCHAR(255) DEFAULT NULL,
  content           TEXT NOT NULL,
  created_by        BIGINT UNSIGNED DEFAULT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_notes_project (project_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- LAYER 5: ENGAGEMENT
-- ============================================================

CREATE TABLE IF NOT EXISTS comments (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  entity_type       VARCHAR(30) NOT NULL,
  entity_id         BIGINT UNSIGNED NOT NULL,
  project_id        BIGINT UNSIGNED NOT NULL,
  user_id           BIGINT UNSIGNED NOT NULL,
  parent_comment_id BIGINT UNSIGNED DEFAULT NULL,
  content           TEXT NOT NULL,
  is_edited         TINYINT(1) NOT NULL DEFAULT 0,
  is_deleted        TINYINT(1) NOT NULL DEFAULT 0,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (parent_comment_id) REFERENCES comments(id) ON DELETE CASCADE,
  INDEX idx_comments_entity (entity_type, entity_id),
  INDEX idx_comments_project (project_id),
  INDEX idx_comments_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notifications (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id           BIGINT UNSIGNED NOT NULL,
  project_id        BIGINT UNSIGNED DEFAULT NULL,
  type              VARCHAR(50) NOT NULL,
  title             VARCHAR(255) NOT NULL,
  message           TEXT DEFAULT NULL,
  entity_type       VARCHAR(30) DEFAULT NULL,
  entity_id         BIGINT UNSIGNED DEFAULT NULL,
  link_url          VARCHAR(500) DEFAULT NULL,
  is_read           TINYINT(1) NOT NULL DEFAULT 0,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  read_at           TIMESTAMP NULL DEFAULT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  INDEX idx_notif_user (user_id, is_read),
  INDEX idx_notif_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- LAYER 6: AUDIT
-- ============================================================

CREATE TABLE IF NOT EXISTS activity_log (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id        BIGINT UNSIGNED NOT NULL,
  user_id           BIGINT UNSIGNED DEFAULT NULL,
  action            VARCHAR(50) NOT NULL,
  entity_type       VARCHAR(30) NOT NULL,
  entity_id         BIGINT UNSIGNED NOT NULL,
  summary           VARCHAR(500) DEFAULT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_activity_project (project_id, created_at),
  INDEX idx_activity_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS change_events (
  id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id        BIGINT UNSIGNED NOT NULL,
  entity_type       VARCHAR(30) NOT NULL,
  entity_id         BIGINT UNSIGNED NOT NULL,
  field_changed     VARCHAR(100) NOT NULL,
  old_value         TEXT DEFAULT NULL,
  new_value         TEXT DEFAULT NULL,
  changed_by        BIGINT UNSIGNED DEFAULT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_change_entity (entity_type, entity_id),
  INDEX idx_change_project (project_id),
  INDEX idx_change_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
