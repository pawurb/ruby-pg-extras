/* Dead rows, new inserts since last VACUUM and whether an automatic vacuum is expected to be triggered */

WITH table_opts AS (
  SELECT
    pg_class.oid, relname, nspname, array_to_string(reloptions, '') AS relopts
  FROM
     pg_class INNER JOIN pg_namespace ns ON relnamespace = ns.oid
), vacuum_settings AS (
  SELECT
    oid, relname, nspname,
    CASE
      WHEN relopts LIKE '%autovacuum_vacuum_threshold%'
        THEN substring(relopts, '.*autovacuum_vacuum_threshold=([0-9.]+).*')::integer
        ELSE current_setting('autovacuum_vacuum_threshold')::integer
      END AS autovacuum_vacuum_threshold,
    CASE
      WHEN relopts LIKE '%autovacuum_vacuum_scale_factor%'
        THEN substring(relopts, '.*autovacuum_vacuum_scale_factor=([0-9.]+).*')::real
        ELSE current_setting('autovacuum_vacuum_scale_factor')::real
      END AS autovacuum_vacuum_scale_factor,
    CASE
      WHEN relopts LIKE '%autovacuum_vacuum_insert_threshold%'
        THEN substring(relopts, '.*autovacuum_vacuum_insert_threshold=([0-9.]+).*')::integer
        ELSE current_setting('autovacuum_vacuum_insert_threshold')::integer
      END AS autovacuum_vacuum_insert_threshold,
    CASE
      WHEN relopts LIKE '%autovacuum_vacuum_insert_scale_factor%'
        THEN substring(relopts, '.*autovacuum_vacuum_insert_scale_factor=([0-9.]+).*')::real
        ELSE current_setting('autovacuum_vacuum_insert_scale_factor')::real
      END AS autovacuum_vacuum_insert_scale_factor
  FROM
    table_opts
)
SELECT
  vacuum_settings.nspname AS schema,
  vacuum_settings.relname AS table,
  to_char(psut.last_vacuum, 'YYYY-MM-DD HH24:MI') AS last_manual_vacuum,
  to_char(psut.vacuum_count, '9G999G999G999') AS manual_vacuum_count,
  to_char(psut.last_autovacuum, 'YYYY-MM-DD HH24:MI') AS last_autovacuum,
  to_char(psut.autovacuum_count, '9G999G999G999') AS autovacuum_count,
  to_char(pg_class.reltuples, '9G999G999G999') AS rowcount,
  to_char(psut.n_dead_tup, '9G999G999G999') AS dead_rowcount,
  to_char(
    autovacuum_vacuum_threshold
    + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples),
    '9G999G999G999'
  ) AS dead_tup_autovacuum_threshold,
  to_char(psut.n_ins_since_vacuum, '9G999G999G999') AS n_ins_since_vacuum,
  to_char(
    autovacuum_vacuum_insert_threshold
    + (autovacuum_vacuum_insert_scale_factor::numeric * pg_class.reltuples),
    '9G999G999G999'
  ) AS insert_autovacuum_threshold,
  CASE
    WHEN psut.n_dead_tup >= autovacuum_vacuum_threshold
         + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples)
      AND psut.n_ins_since_vacuum >= autovacuum_vacuum_insert_threshold
         + (autovacuum_vacuum_insert_scale_factor::numeric * pg_class.reltuples)
    THEN 'yes (dead_tuples & inserts)'
    WHEN psut.n_dead_tup >= autovacuum_vacuum_threshold
         + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples)
    THEN 'yes (dead_tuples)'
    WHEN psut.n_ins_since_vacuum >= autovacuum_vacuum_insert_threshold
         + (autovacuum_vacuum_insert_scale_factor::numeric * pg_class.reltuples)
    THEN 'yes (inserts)'
  END AS expect_autovacuum
FROM
  pg_stat_user_tables psut INNER JOIN pg_class ON psut.relid = pg_class.oid
    INNER JOIN vacuum_settings ON pg_class.oid = vacuum_settings.oid
ORDER BY 1;
