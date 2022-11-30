/* Returns the list of all active database connections */

SELECT usename as username, pid, client_addr::text as client_address, application_name FROM pg_stat_activity WHERE datname = current_database();
