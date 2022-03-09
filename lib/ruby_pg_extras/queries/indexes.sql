/* List all the indexes with their corresponding tables and columns. */

SELECT
  schemaname,
  indexname,
  tablename,
  rtrim(split_part(indexdef, '(', 2), ')') as columns
FROM pg_indexes
where tablename in (select relname from pg_statio_user_tables);
