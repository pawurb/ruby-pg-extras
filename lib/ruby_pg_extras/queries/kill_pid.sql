/* Kill database connection by its pid */

SELECT pg_terminate_backend(pid) FROM pg_stat_activity
  WHERE pid = %{pid}
  AND query <> '<insufficient privilege>'
  AND datname = current_database();
