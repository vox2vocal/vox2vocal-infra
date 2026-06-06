CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS audit.audit_events (
  audit_event_id text PRIMARY KEY,
  occurred_at timestamptz NOT NULL,
  schema_version text NOT NULL,
  actor_type text NOT NULL,
  actor_id text NOT NULL,
  action text NOT NULL,
  resource_type text NOT NULL,
  resource_id text NOT NULL,
  decision text NOT NULL,
  reason_code text,
  policy_version text,
  consent_record_id text,
  trace_id text,
  job_id text,
  audio_asset_id text,
  source_service text NOT NULL,
  event_hash text NOT NULL,
  prev_hash text,
  payload_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit.audit_daily_digests (
  digest_date date PRIMARY KEY,
  event_count bigint NOT NULL,
  first_event_id text,
  last_event_id text,
  root_hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION audit.prevent_audit_event_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'audit_events is append-only';
END;
$$;

DROP TRIGGER IF EXISTS audit_events_no_update ON audit.audit_events;
CREATE TRIGGER audit_events_no_update
BEFORE UPDATE ON audit.audit_events
FOR EACH ROW EXECUTE FUNCTION audit.prevent_audit_event_mutation();

DROP TRIGGER IF EXISTS audit_events_no_delete ON audit.audit_events;
CREATE TRIGGER audit_events_no_delete
BEFORE DELETE ON audit.audit_events
FOR EACH ROW EXECUTE FUNCTION audit.prevent_audit_event_mutation();

COMMENT ON TABLE audit.audit_events IS 'Append-only audit event store. Do not use Loki as the only audit store.';
COMMENT ON TABLE audit.audit_daily_digests IS 'Daily integrity digest metadata for audit event verification and future WORM archive export.';
