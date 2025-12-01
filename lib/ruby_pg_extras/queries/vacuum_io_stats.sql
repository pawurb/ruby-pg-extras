/* I/O statistics for autovacuum backends from pg_stat_io (PostgreSQL 16+) */

SELECT
  backend_type,
  object,
  context,
  reads,
  read_time,
  writes,
  write_time,
  writebacks,
  writeback_time,
  extends,
  extend_time,
  fsyncs,
  fsync_time,
  reuses,
  evictions,
  stats_reset
FROM
  pg_stat_io
WHERE
  backend_type IN ('autovacuum worker', 'autovacuum launcher')
  AND object = 'relation'
  AND context IN ('vacuum', 'autovacuum')
ORDER BY
  backend_type,
  context,
  object;


