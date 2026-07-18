/* HOT, same-page non-HOT, and new-page update statistics (PostgreSQL 16+) */

WITH table_stats AS (
  SELECT
    s.relid,
    s.schemaname,
    s.relname,
    s.n_tup_upd,
    s.n_tup_hot_upd,
    s.n_tup_newpage_upd,
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
  ROUND(
    pg_relation_size(relid)::numeric
    / NULLIF(reltuples, 0)
  )::bigint AS avg_row_bytes,
  n_tup_upd AS total_updates,
  n_tup_hot_upd AS hot_updates,
  ROUND(
    100.0 * n_tup_hot_upd
    / NULLIF(n_tup_upd, 0),
    2
  ) AS hot_pct,
  n_tup_upd
    - n_tup_hot_upd
    - n_tup_newpage_upd
    AS same_page_non_hot_updates,
  ROUND(
    100.0 * (
      n_tup_upd
      - n_tup_hot_upd
      - n_tup_newpage_upd
    )
    / NULLIF(n_tup_upd, 0),
    2
  ) AS same_page_non_hot_pct,
  n_tup_newpage_upd AS new_page_updates,
  ROUND(
    100.0 * n_tup_newpage_upd
    / NULLIF(n_tup_upd, 0),
    2
  ) AS new_page_pct,
  ROUND(
    100.0 * (n_tup_upd - n_tup_newpage_upd)
    / NULLIF(n_tup_upd, 0),
    2
  ) AS same_page_pct,
  ROUND(
    100.0 * n_tup_hot_upd
    / NULLIF(n_tup_upd - n_tup_newpage_upd, 0),
    2
  ) AS hot_given_same_page_pct
FROM table_stats
WHERE n_tup_upd > 0
ORDER BY n_tup_upd DESC;
