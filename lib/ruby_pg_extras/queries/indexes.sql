/* List all the indexes with their corresponding tables and columns. */

SELECT
  schemaname,
  indexname,
  tablename,
  rtrim(split_part(split_part(indexdef, ' WHERE', 1), '(', 2), ')') as columns
FROM pg_indexes
where tablename in (select relname from pg_statio_user_tables);
