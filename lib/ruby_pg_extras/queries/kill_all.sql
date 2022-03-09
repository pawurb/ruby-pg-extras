/* Kill all the active database connections */

SELECT pg_terminate_backend(pid) FROM pg_stat_activity
  WHERE pid <> pg_backend_pid()
  AND query <> '<insufficient privilege>'
  AND datname = current_database();
