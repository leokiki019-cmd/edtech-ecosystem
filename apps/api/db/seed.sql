-- Seed data matching the original in-memory store
-- All demo accounts share the password "password123" (scrypt hash).

-- College reference data (idempotent: INSERT OR IGNORE)
INSERT OR IGNORE INTO colleges (id, name, short_name, created_at) VALUES
('col-cttc', 'Christian Technical Training Center', 'CTTC', '2026-01-01T00:00:00Z');

-- Department/programme reference data. Mirrors the CTTC admissions flyer:
-- four programme panels (3-year DAE, 2-year certificates, 6-month
-- certificates, 2-year paramedical). Seeded when the table is empty;
-- db.ts rebuilds the table when the schema shape changes.
INSERT OR IGNORE INTO departments (id, college_id, name, code, category, duration_months, created_at) VALUES
-- 3 YEARS PROGRAMMES (DAE — qualification: Matric Science)
('dept-arc', 'col-cttc', 'Architecture', 'ARC', '3 Years', 36, '2026-01-01T00:00:00Z'),
('dept-civ', 'col-cttc', 'Civil Engineering Technology', 'CIV', '3 Years', 36, '2026-01-01T00:00:00Z'),
('dept-cit', 'col-cttc', 'Computer Info Tech.', 'CIT', '3 Years', 36, '2026-01-01T00:00:00Z'),
('dept-eee', 'col-cttc', 'Electrical Technology', 'EEE', '3 Years', 36, '2026-01-01T00:00:00Z'),
('dept-ece', 'col-cttc', 'Electronics Technology', 'ECE', '3 Years', 36, '2026-01-01T00:00:00Z'),
('dept-mec', 'col-cttc', 'Mechanical', 'MEC', '3 Years', 36, '2026-01-01T00:00:00Z'),
-- 2 YEARS PROGRAMMES (qualification: Matric)
('dept-adm', 'col-cttc', 'Auto & Diesel Mechanic', 'ADM', '2 Years', 24, '2026-01-01T00:00:00Z'),
('dept-dft', 'col-cttc', 'Drafting Civil', 'DFT', '2 Years', 24, '2026-01-01T00:00:00Z'),
('dept-elc', 'col-cttc', 'Electrician', 'ELC', '2 Years', 24, '2026-01-01T00:00:00Z'),
-- 6 MONTHS PROGRAMMES (qualification: Middle)
('dept-cnc', 'col-cttc', 'CNC Programmer', 'CNC', '6 Months', 6, '2026-01-01T00:00:00Z'),
('dept-mac', 'col-cttc', 'Machinist', 'MAC', '6 Months', 6, '2026-01-01T00:00:00Z'),
('dept-aec', 'col-cttc', 'Auto Electrician', 'AEC', '6 Months', 6, '2026-01-01T00:00:00Z'),
-- 2 YEARS PARAMEDICAL COURSES (Punjab Medical Faculty)
('dept-ott', 'col-cttc', 'FSc. Operation Theatre Technology', 'OTT', '2 Years Paramedical', 24, '2026-01-01T00:00:00Z'),
('dept-rad', 'col-cttc', 'FSc. Radiography & Medical Imaging Technology', 'RAD', '2 Years Paramedical', 24, '2026-01-01T00:00:00Z'),
('dept-mlt', 'col-cttc', 'FSc. Medical Laboratory Technology', 'MLT', '2 Years Paramedical', 24, '2026-01-01T00:00:00Z'),
('dept-dsp', 'col-cttc', 'FSc. Dispensing Technology', 'DSP', '2 Years Paramedical', 24, '2026-01-01T00:00:00Z'),
('dept-ane', 'col-cttc', 'Anesthesia Technician', 'ANE', '2 Years Paramedical', 24, '2026-01-01T00:00:00Z'),
('dept-pht', 'col-cttc', 'Public Health Technician', 'PHT', '2 Years Paramedical', 24, '2026-01-01T00:00:00Z');

INSERT OR IGNORE INTO users (id, display_name, email, phone, role, course_ids, password_hash, is_phone_verified, created_at) VALUES
('u-teacher-1', 'Dr. Maya Chen', 'maya.chen@example.edu', '+15550001001', 'teacher', '["c-001"]', 'scrypt$d61d8f46ce5212d0de626f54910fe3e1$2af1ee96671aaf94237605c177e50fb6bd0fa9ef4c4ca6543e01afc7b716036d450f753153cb14e3d94a2148e3002d4bac56b8df93e82a60cec5c52a6b7ed2a3', 1, '2026-08-15T00:00:00Z'),
('u-student-1', 'Alex Rivera', 'alex.rivera@example.edu', '+15550001002', 'student', '["c-001"]', 'scrypt$d61d8f46ce5212d0de626f54910fe3e1$2af1ee96671aaf94237605c177e50fb6bd0fa9ef4c4ca6543e01afc7b716036d450f753153cb14e3d94a2148e3002d4bac56b8df93e82a60cec5c52a6b7ed2a3', 1, '2026-08-15T00:00:00Z'),
('u-student-2', 'Priya Nair', 'priya.nair@example.edu', '+15550001003', 'student', '["c-001"]', 'scrypt$d61d8f46ce5212d0de626f54910fe3e1$2af1ee96671aaf94237605c177e50fb6bd0fa9ef4c4ca6543e01afc7b716036d450f753153cb14e3d94a2148e3002d4bac56b8df93e82a60cec5c52a6b7ed2a3', 1, '2026-08-15T00:00:00Z'),
('u-student-3', 'Jordan Lee', 'jordan.lee@example.edu', '+15550001004', 'student', '["c-001"]', 'scrypt$d61d8f46ce5212d0de626f54910fe3e1$2af1ee96671aaf94237605c177e50fb6bd0fa9ef4c4ca6543e01afc7b716036d450f753153cb14e3d94a2148e3002d4bac56b8df93e82a60cec5c52a6b7ed2a3', 1, '2026-08-20T00:00:00Z'),
('u-admin-1', 'Sam Okafor', 'sam.okafor@example.edu', '+15550001005', 'admin', '[]', 'scrypt$d61d8f46ce5212d0de626f54910fe3e1$2af1ee96671aaf94237605c177e50fb6bd0fa9ef4c4ca6543e01afc7b716036d450f753153cb14e3d94a2148e3002d4bac56b8df93e82a60cec5c52a6b7ed2a3', 1, '2026-07-01T00:00:00Z');

INSERT OR IGNORE INTO courses (id, title, code, teacher_id, student_ids, term, created_at) VALUES
('c-001', 'Human-Computer Interaction', 'CS 301', 'u-teacher-1', '["u-student-1", "u-student-2", "u-student-3"]', 'Fall 2026', '2026-08-01T00:00:00Z');

INSERT OR IGNORE INTO assignments (id, course_id, title, brief, due_at, status, created_at) VALUES
('a-001', 'c-001', 'Usability Study Report', 'Run a moderated usability study with five participants and report findings, severity ratings and design recommendations.', datetime('now', '+7 days'), 'open', datetime('now', '-14 days')),
('a-002', 'c-001', 'Prototype Critique', 'Critique a peer interactive prototype using Nielsen''s heuristics and propose three concrete improvements.', datetime('now', '+3 days'), 'open', datetime('now', '-10 days')),
('a-003', 'c-001', 'Final Reflection', 'Reflect on the semester''s design process, linking each milestone to the course learning outcomes.', datetime('now', '+14 days'), 'open', datetime('now', '-4 days')),
('a-004', 'c-001', 'Heuristic Evaluation', 'Evaluate the campus portal against the ten usability heuristics and deliver a findings table.', datetime('now', '-2 days'), 'closed', datetime('now', '-21 days'));

INSERT OR IGNORE INTO calendar_events (id, course_id, title, kind, starts_at, ends_at) VALUES
('e-001', 'c-001', 'Usability Study Report due', 'assignment', datetime('now', '+7 days'), NULL),
('e-002', 'c-001', 'Prototype Critique due', 'assignment', datetime('now', '+3 days'), NULL),
('e-003', 'c-001', 'Heuristics quiz', 'quiz', datetime('now', '+5 days'), datetime('now', '+5 days 02:00:00')),
('e-004', 'c-001', 'Studio session', 'class', datetime('now', '+1 days'), datetime('now', '+1 days 02:00:00')),
('e-005', NULL, 'Institution research symposium', 'institution', datetime('now', '+10 days'), datetime('now', '+10 days 04:00:00'));

INSERT OR IGNORE INTO chat_channels (id, course_id, name, kind, member_ids) VALUES
('ch-001', 'c-001', 'Announcements', 'announcement', '["u-teacher-1", "u-student-1", "u-student-2", "u-student-3"]'),
('ch-002', 'c-001', 'Studio Discussion', 'discussion', '["u-teacher-1", "u-student-1", "u-student-2", "u-student-3"]');

INSERT OR IGNORE INTO chat_messages (id, channel_id, author_id, body, sent_at) VALUES
('m-001', 'ch-001', 'u-teacher-1', 'Reminder: the usability study report is due next week. Bring questions to Thursday''s studio.', datetime('now', '-30 hours')),
('m-002', 'ch-002', 'u-student-1', 'Sharing my participant consent template for anyone who needs one.', datetime('now', '-6 hours'));

-- Pre-seeded submissions
INSERT OR IGNORE INTO submissions (id, assignment_id, student_id, status, submitted_at, attachments, grade, effort_score, created_at) VALUES
('s-001', 'a-001', 'u-student-1', 'submitted', datetime('now', '-20 hours'), '[{"id":"att-001","fileName":"usability-study-report.pdf","mimeType":"application/pdf","sizeBytes":482133,"url":"https://files.example.edu/att-001"}]', NULL, 84, datetime('now', '-20 hours')),
('s-002', 'a-002', 'u-student-2', 'pending', NULL, '[]', NULL, NULL, datetime('now')),
('s-003', 'a-004', 'u-student-3', 'late', datetime('now', '-1 days'), '[{"id":"att-002","fileName":"heuristic-evaluation.docx","mimeType":"application/vnd.openxmlformats-officedocument.wordprocessingml.document","sizeBytes":91204,"url":"https://files.example.edu/att-002"}]', 72, 58, datetime('now', '-1 days'));
