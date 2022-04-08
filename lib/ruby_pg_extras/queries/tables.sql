/* List all the tables. */

select relname as tablename, schemaname from pg_statio_user_tables where schemaname = '%{schema}';
