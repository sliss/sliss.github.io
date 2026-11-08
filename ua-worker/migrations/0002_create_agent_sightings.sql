-- Headers of suspected agent requests, for calibrating detection (notably Meta Muse, which
-- doesn't identify itself). No IP addresses. Rows older than 90 days are pruned by the worker.
CREATE TABLE IF NOT EXISTS agent_sightings (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at         TEXT    NOT NULL,
  http_method        TEXT    NOT NULL,
  path               TEXT    NOT NULL,
  label              TEXT,             -- classification, NULL if logged but not classified as an agent
  method             TEXT,             -- declared | signature | inferred
  user_agent         TEXT    NOT NULL DEFAULT '',
  sec_ch_ua          TEXT    NOT NULL DEFAULT '',
  sec_ch_ua_platform TEXT    NOT NULL DEFAULT '',
  sec_ch_ua_arch     TEXT    NOT NULL DEFAULT '',
  signature_agent    TEXT    NOT NULL DEFAULT '',
  has_signature      INTEGER NOT NULL DEFAULT 0,
  asn                INTEGER,
  as_org             TEXT    NOT NULL DEFAULT '',
  country            TEXT    NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_sightings_created ON agent_sightings (created_at);
CREATE INDEX IF NOT EXISTS idx_sightings_label ON agent_sightings (label, created_at);
