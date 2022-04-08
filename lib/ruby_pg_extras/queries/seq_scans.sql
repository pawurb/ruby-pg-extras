/* Count of sequential scans by table descending by order */

SELECT relname AS name,
       seq_scan as count
FROM
  pg_stat_user_tables
WHERE
  schemaname = '%{schema}'
ORDER BY seq_scan DESC;
