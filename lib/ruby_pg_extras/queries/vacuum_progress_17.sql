/* Current VACUUM progress as reported by pg_stat_progress_vacuum */

SELECT
  a.datname AS database,
  n.nspname AS schema,
  c.relname AS table,
  p.pid,
  p.phase,
  p.heap_blks_total,
  p.heap_blks_scanned,
  p.heap_blks_vacuumed,
  p.index_vacuum_count,
  p.indexes_total,
  p.indexes_processed,
  p.num_dead_item_ids,
  p.dead_tuple_bytes,
  p.max_dead_tuple_bytes
FROM
  pg_stat_progress_vacuum p
  LEFT JOIN pg_class c ON p.relid = c.oid
  LEFT JOIN pg_namespace n ON c.relnamespace = n.oid
  LEFT JOIN pg_stat_activity a ON p.pid = a.pid
ORDER BY
  a.datname,
  n.nspname,
  c.relname,
  p.pid;


