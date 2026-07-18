/* HOT and non-HOT update statistics (PostgreSQL 15 and older) */

WITH table_stats AS (
  SELECT
    s.relid,
    s.relname,
    s.n_tup_upd,
    s.n_tup_hot_upd,
    c.reltuples,
    COALESCE(
      (
        SELECT option_value::integer
        FROM pg_options_to_table(c.reloptions)
        WHERE option_name = 'fillfactor'
      ),
      100
    ) AS fillfactor
  FROM pg_stat_user_tables s
  INNER JOIN pg_class c ON c.oid = s.relid
  WHERE s.schemaname = '%{schema}'
)
SELECT
  relname AS table,
  fillfactor,
  CASE
    WHEN reltuples > 0 THEN
      ROUND(
        pg_relation_size(relid)::numeric / reltuples
      )::bigint
  END AS estimated_heap_bytes_per_live_row,
  n_tup_upd AS total_updates,
  n_tup_hot_upd AS hot_updates,
  ROUND(
    100.0 * n_tup_hot_upd
    / NULLIF(n_tup_upd, 0),
    2
  ) AS hot_pct,
  n_tup_upd - n_tup_hot_upd AS non_hot_updates,
  ROUND(
    100.0 * (n_tup_upd - n_tup_hot_upd)
    / NULLIF(n_tup_upd, 0),
    2
  ) AS non_hot_pct
FROM table_stats
WHERE n_tup_upd > 0
ORDER BY n_tup_upd DESC;
