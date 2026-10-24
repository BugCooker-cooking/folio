-- Recent documents and their word counts
SELECT
    d.id,
    d.title,
    COUNT(w.id) AS word_count,
    MAX(w.updated_at) AS last_edited
FROM documents AS d
LEFT JOIN words AS w ON w.document_id = d.id
WHERE d.deleted_at IS NULL
  AND d.created_at >= DATE '2026-01-01'
GROUP BY d.id, d.title
HAVING COUNT(w.id) > 0
ORDER BY last_edited DESC
LIMIT 50;

/* A small schema */
CREATE TABLE IF NOT EXISTS reading_list (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    url TEXT,
    finished BOOLEAN DEFAULT FALSE
);
