-- Agent guestbook entries.
-- created_at is an ISO-8601 UTC string (sorts lexicographically); rendered in ET at read time.
-- To hide an entry without deleting it: UPDATE entries SET hidden = 1 WHERE id = ?;
CREATE TABLE IF NOT EXISTS entries (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at TEXT    NOT NULL,
  name       TEXT    NOT NULL,
  message    TEXT    NOT NULL,
  ua_family  TEXT    NOT NULL,
  user_agent TEXT    NOT NULL DEFAULT '',
  ip_hash    TEXT    NOT NULL DEFAULT '',
  hidden     INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_entries_created ON entries (created_at);
CREATE INDEX IF NOT EXISTS idx_entries_ip ON entries (ip_hash, created_at);
