-- Simon AI Agent Studio - Database Initialization
-- Version: 3.1.0

-- ============================================================
-- EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For full-text search

-- ============================================================
-- ENUM TYPES
-- ============================================================
CREATE TYPE user_role AS ENUM ('guest', 'user', 'admin');
CREATE TYPE key_mode AS ENUM ('free', 'free_plus', 'byok');
CREATE TYPE model_provider AS ENUM ('anthropic', 'openai', 'google', 'xai', 'ollama');
CREATE TYPE risk_level AS ENUM ('low', 'medium', 'high');
CREATE TYPE approval_status AS ENUM ('pending', 'approved', 'rejected', 'timeout');
CREATE TYPE task_status AS ENUM ('created', 'planning', 'executing', 'completed', 'failed', 'cancelled');

-- ============================================================
-- USERS (Faz 3)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    role user_role NOT NULL DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    preferences JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- ============================================================
-- API KEYS (BYOK)
-- ============================================================
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    provider model_provider NOT NULL,
    key_encrypted TEXT NOT NULL, -- AES-256 encrypted
    key_hash VARCHAR(64) NOT NULL, -- SHA-256 hash for lookup
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_api_keys_user ON api_keys(user_id);
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);

-- ============================================================
-- MODEL CATALOG
-- ============================================================
CREATE TABLE IF NOT EXISTS model_catalog (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider model_provider NOT NULL,
    model_id VARCHAR(255) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    key_mode key_mode NOT NULL,
    enabled BOOLEAN DEFAULT TRUE,
    priority INTEGER DEFAULT 100, -- Lower = higher priority
    capabilities JSONB DEFAULT '{}'::jsonb, -- {vision: true, tools: true, ...}
    pricing JSONB, -- {input_per_1m: 3.0, output_per_1m: 15.0}
    context_window INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(provider, model_id, key_mode)
);

CREATE INDEX idx_model_catalog_provider ON model_catalog(provider);
CREATE INDEX idx_model_catalog_enabled ON model_catalog(enabled);

-- ============================================================
-- PROJECTS
-- ============================================================
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    pinned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_projects_pinned ON projects(pinned);

-- ============================================================
-- CHATS
-- ============================================================
CREATE TABLE IF NOT EXISTS chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    title VARCHAR(500),
    model_mode key_mode NOT NULL DEFAULT 'free',
    selected_model VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    archived_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_chats_project ON chats(project_id);
CREATE INDEX idx_chats_created ON chats(created_at DESC);
CREATE INDEX idx_chats_title_trgm ON chats USING gin(title gin_trgm_ops);

-- ============================================================
-- MESSAGES
-- ============================================================
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL, -- user, assistant, system
    content TEXT NOT NULL,
    token_usage JSONB, -- {input: 100, output: 200}
    cost DECIMAL(10, 6), -- USD
    model_used VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_messages_chat ON messages(chat_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);

-- ============================================================
-- TASKS (Agent Execution)
-- ============================================================
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    chat_id UUID REFERENCES chats(id) ON DELETE SET NULL,
    prompt TEXT NOT NULL,
    status task_status NOT NULL DEFAULT 'created',
    risk_level risk_level NOT NULL DEFAULT 'low',
    plan JSONB, -- AI-generated execution plan
    result JSONB, -- Execution results
    cost_estimated DECIMAL(10, 6),
    cost_actual DECIMAL(10, 6),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_tasks_user ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_created ON tasks(created_at DESC);

-- ============================================================
-- APPROVALS
-- ============================================================
CREATE TABLE IF NOT EXISTS approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    risk_level risk_level NOT NULL,
    requested_by UUID REFERENCES users(id),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_by UUID REFERENCES users(id),
    status approval_status NOT NULL DEFAULT 'pending',
    decision_at TIMESTAMP WITH TIME ZONE,
    timeout_at TIMESTAMP WITH TIME ZONE,
    reason TEXT,
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_approvals_task ON approvals(task_id);
CREATE INDEX idx_approvals_status ON approvals(status);
CREATE INDEX idx_approvals_timeout ON approvals(timeout_at) WHERE status = 'pending';

-- ============================================================
-- COST LEDGER
-- ============================================================
CREATE TABLE IF NOT EXISTS cost_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES tasks(id),
    user_id UUID REFERENCES users(id),
    provider model_provider NOT NULL,
    model VARCHAR(255) NOT NULL,
    tokens_input INTEGER NOT NULL DEFAULT 0,
    tokens_output INTEGER NOT NULL DEFAULT 0,
    cost DECIMAL(10, 6) NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_cost_ledger_task ON cost_ledger(task_id);
CREATE INDEX idx_cost_ledger_user ON cost_ledger(user_id);
CREATE INDEX idx_cost_ledger_recorded ON cost_ledger(recorded_at DESC);

-- ============================================================
-- AUDIT LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL,
    user_id UUID REFERENCES users(id),
    task_id UUID REFERENCES tasks(id),
    severity VARCHAR(20) NOT NULL DEFAULT 'info', -- debug, info, warn, error, critical
    message TEXT NOT NULL,
    context JSONB DEFAULT '{}'::jsonb,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_event ON audit_logs(event_type);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_task ON audit_logs(task_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_severity ON audit_logs(severity);

-- ============================================================
-- FEEDBACK REPORTS
-- ============================================================
CREATE TABLE IF NOT EXISTS feedback_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    user_context JSONB NOT NULL, -- device, version, logs
    screenshot_url TEXT,
    logs TEXT,
    triage_report JSONB, -- AI analysis
    status VARCHAR(50) DEFAULT 'pending', -- pending, triaged, assigned, resolved
    assigned_to UUID REFERENCES users(id),
    github_issue_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_feedback_status ON feedback_reports(status);
CREATE INDEX idx_feedback_created ON feedback_reports(created_at DESC);

-- ============================================================
-- USAGE EVENTS (Telemetry)
-- ============================================================
CREATE TABLE IF NOT EXISTS usage_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL,
    user_id UUID REFERENCES users(id),
    event_type VARCHAR(100) NOT NULL,
    latency_ms INTEGER,
    tokens_in INTEGER,
    tokens_out INTEGER,
    error_code VARCHAR(100),
    metadata JSONB DEFAULT '{}'::jsonb,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_usage_events_request ON usage_events(request_id);
CREATE INDEX idx_usage_events_user ON usage_events(user_id);
CREATE INDEX idx_usage_events_type ON usage_events(event_type);
CREATE INDEX idx_usage_events_recorded ON usage_events(recorded_at DESC);

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chats_updated_at BEFORE UPDATE ON chats
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_model_catalog_updated_at BEFORE UPDATE ON model_catalog
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- INITIAL DATA - Model Catalog
-- ============================================================

-- FREE Models (Ollama)
INSERT INTO model_catalog (provider, model_id, display_name, key_mode, description, context_window, priority) VALUES
('ollama', 'gemma3', 'Gemma 3', 'free', 'Google Gemma 3 - Genel amaçlı model', 8192, 10),
('ollama', 'qwen2.5', 'Qwen 2.5', 'free', 'Alibaba Qwen 2.5 - Genel amaçlı', 8192, 20),
('ollama', 'qwen2.5-coder', 'Qwen 2.5 Coder', 'free', 'Kod üretimi ve analiz', 8192, 15),
('ollama', 'phi4', 'Phi 4', 'free', 'Microsoft Phi 4 - Kompakt ve hızlı', 4096, 30),
('ollama', 'llama3.3', 'Llama 3.3', 'free', 'Meta Llama 3.3 - Genel amaçlı', 8192, 25),
('ollama', 'mistral', 'Mistral', 'free', 'Mistral AI - Genel amaçlı', 8192, 35),
('ollama', 'deepseek-r1', 'DeepSeek R1', 'free', 'Akıl yürütme odaklı model', 4096, 40),
('ollama', 'llava', 'LLaVA', 'free', 'Görsel analiz modeli', 4096, 50);

-- BYOK Models
INSERT INTO model_catalog (provider, model_id, display_name, key_mode, description, context_window, priority, pricing) VALUES
('anthropic', 'claude-sonnet-4-20250514', 'Claude Sonnet 4.5', 'byok', 'En akıllı model - günlük kullanım için verimli', 200000, 5, '{"input_per_1m": 3.0, "output_per_1m": 15.0}'),
('anthropic', 'claude-opus-4-20250514', 'Claude Opus 4.5', 'byok', 'Premium - karmaşık görevler için', 200000, 8, '{"input_per_1m": 5.0, "output_per_1m": 25.0}'),
('openai', 'gpt-4o', 'GPT-4o', 'byok', 'OpenAI multimodal model', 128000, 6, '{"input_per_1m": 2.5, "output_per_1m": 10.0}'),
('google', 'gemini-1.5-pro', 'Gemini 1.5 Pro', 'byok', 'Google multimodal - 1M context', 1000000, 7, '{"input_per_1m": 1.25, "output_per_1m": 5.0}');

-- ============================================================
-- VIEWS
-- ============================================================

-- Daily cost summary
CREATE OR REPLACE VIEW daily_cost_summary AS
SELECT 
    DATE(recorded_at) as date,
    user_id,
    provider,
    SUM(cost) as total_cost,
    SUM(tokens_input) as total_tokens_input,
    SUM(tokens_output) as total_tokens_output,
    COUNT(*) as request_count
FROM cost_ledger
GROUP BY DATE(recorded_at), user_id, provider
ORDER BY date DESC;

-- Task summary
CREATE OR REPLACE VIEW task_summary AS
SELECT 
    DATE(created_at) as date,
    status,
    risk_level,
    COUNT(*) as task_count,
    AVG(cost_actual) as avg_cost,
    AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) as avg_duration_seconds
FROM tasks
GROUP BY DATE(created_at), status, risk_level
ORDER BY date DESC;

-- ============================================================
-- GRANTS (Production için ayarlanmalı)
-- ============================================================
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO simon_api_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO simon_api_user;

-- ============================================================
-- COMMENTS
-- ============================================================
COMMENT ON TABLE users IS 'Kullanıcı hesapları ve profilleri';
COMMENT ON TABLE api_keys IS 'BYOK API anahtarları (şifreli)';
COMMENT ON TABLE model_catalog IS 'Kullanılabilir AI modelleri kataloğu';
COMMENT ON TABLE tasks IS 'Agent görevleri ve yürütme durumları';
COMMENT ON TABLE approvals IS 'Yüksek riskli görevler için onay kayıtları';
COMMENT ON TABLE cost_ledger IS 'Her API çağrısının maliyet kaydı';
COMMENT ON TABLE audit_logs IS 'Sistem denetim logları (tamper-evident)';
COMMENT ON TABLE feedback_reports IS 'Kullanıcı geri bildirimleri ve triage';

-- ============================================================
-- END OF INITIALIZATION
-- ============================================================
