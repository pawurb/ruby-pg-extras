/* Values of selected PostgreSQL settings */

SELECT name, setting, unit, short_desc FROM pg_settings
WHERE name IN (
  'max_connections', 'shared_buffers', 'effective_cache_size',
  'maintenance_work_mem', 'checkpoint_completion_target', 'wal_buffers',
  'default_statistics_target', 'random_page_cost', 'effective_io_concurrency',
  'work_mem', 'min_wal_size', 'max_wal_size'
);
