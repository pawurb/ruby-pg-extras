/* Current ANALYZE progress as reported by pg_stat_progress_analyze */

SELECT
  a.datname AS database,
  n.nspname AS schema,
  c.relname AS table,
  p.pid,
  p.phase,
  p.sample_blks_total,
  p.sample_blks_scanned,
  p.ext_stats_total,
  p.ext_stats_computed,
  p.child_tables_total,
  p.child_tables_done,
  p.current_child_table_relid
FROM
  pg_stat_progress_analyze p
  LEFT JOIN pg_class c ON p.relid = c.oid
  LEFT JOIN pg_namespace n ON c.relnamespace = n.oid
  LEFT JOIN pg_stat_activity a ON p.pid = a.pid
ORDER BY
  a.datname,
  n.nspname,
  c.relname,
  p.pid;


