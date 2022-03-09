/* Count of index scans by table descending by order */

SELECT relname AS name,
       idx_scan as count
FROM
  pg_stat_user_tables
ORDER BY idx_scan DESC;
