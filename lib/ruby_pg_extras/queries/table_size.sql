/* Size of the tables (excluding indexes), descending by size */

SELECT c.relname AS name,
  pg_size_pretty(pg_table_size(c.oid)) AS size,
  n.nspname as schema
FROM pg_class c
LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
WHERE n.nspname = '%{schema}'
AND n.nspname !~ '^pg_toast'
AND c.relkind IN ('r', 'm')
ORDER BY pg_table_size(c.oid) DESC;
